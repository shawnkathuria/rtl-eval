#!/usr/bin/env python3
"""
Score benches on the hand-written status-output mutants (see make_mutants.py).

For every mutant:
  formal  : eq.sby task "all"  (golden vs mutant, every output)   FAIL = real bug
            eq.sby task "core" (empty_o + data_o only)             PASS = port-only bug
  sim     : each bench on the mutant, same pass/FAIL/ERROR rule as mcy/test_sim.sh
  explain : if a bench PASSED a real bug, diff its trace against the same bench's
            golden trace (output columns only): identical -> STIMULUS_MISS,
            different -> CHECKER_MISS (the bug was on the wires; nobody looked).

Golden and mutants go through the identical yosys path (read -DSYNTHESIS, chparam
8x8, prep, write_verilog), so stimulus and widths match cycle for cycle.

Usage (from this dir, oss-cad-suite environment sourced):
    python3 make_mutants.py && python3 run.py [--bench ../tb --bench ../tb_gpt5]
Writes RESULTS.md; scratch goes to work/.
"""
import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GOLDEN_SV = (HERE / ".." / "rtl" / "fifo_v3.sv").resolve()
OUTPUT_COLS = ["full", "empty", "usage", "data_o"]


def sh(cmd, log, cwd=None, env_extra=None):
    with open(log, "w") as f:
        return subprocess.run(cmd, cwd=cwd, stdout=f, stderr=subprocess.STDOUT).returncode


def elaborate(sv, outdir):
    """sv -> outdir/sim.v (module fifo_v3) and outdir/formal.v (module renamed later)."""
    outdir.mkdir(parents=True, exist_ok=True)
    for name, top in (("sim.v", "fifo_v3"), ("formal.v", "__RENAME__")):
        ys = (f"read_verilog -sv -DSYNTHESIS {sv}; "
              "chparam -set DATA_WIDTH 8 -set DEPTH 8 fifo_v3; prep -top fifo_v3; ")
        if top != "fifo_v3":
            ys += "rename fifo_v3 __RENAME__; "
        ys += f"write_verilog -noattr {outdir / name}"
        if sh(["yosys", "-q", "-p", ys], outdir / f"yosys_{name}.log") != 0:
            sys.exit(f"yosys failed on {sv}; see {outdir}/yosys_{name}.log")


def formal(gold_dir, mut_dir, workdir):
    workdir.mkdir(parents=True, exist_ok=True)
    (workdir / "gold.v").write_text((gold_dir / "formal.v").read_text().replace("__RENAME__", "fifo_gold"))
    (workdir / "mut.v").write_text((mut_dir / "formal.v").read_text().replace("__RENAME__", "fifo_mut"))
    for f in ("miter.sv", "eq.sby"):
        (workdir / f).write_text((HERE / f).read_text())
    res = {}
    for task in ("all", "core"):
        sh(["sby", "-f", "eq.sby", task], workdir / f"sby_{task}.log", cwd=workdir)
        st = workdir / f"eq_{task}" / "status"
        res[task] = st.read_text().split()[0] if st.exists() else "ERROR"
    return res


def run_bench(bench, rtl, workdir):
    workdir.mkdir(parents=True, exist_ok=True)
    log = workdir / "sim.log"
    rc = sh(["make", "-C", str(bench), f"RTL={rtl}", f"SIM_BUILD={workdir}/sim_build",
             f"COCOTB_RESULTS_FILE={workdir}/results.xml", f"TRACE={workdir}/trace.csv"], log)
    text = log.read_text(errors="replace")
    if rc == 0 and not re.search(r"FAIL=[1-9]", text):
        return "PASS"
    if re.search(r"FAIL=[1-9]", text) and "AssertionError" in text:
        return "FAIL"
    return "ERROR"


def read_trace(p):
    with open(p) as f:
        rows = list(csv.DictReader(f))
    return rows


def diff(gold, mut):
    """first cycle and columns where outputs differ, number of differing cycles."""
    first, cols, n = None, [], 0
    for g, m in zip(gold, mut):
        d = [c for c in OUTPUT_COLS if g[c] != m[c]]
        if d:
            n += 1
            if first is None:
                first, cols = g["cycle"], d
    if len(gold) != len(mut) and first is None:
        first, cols = str(min(len(gold), len(mut))), ["<trace length>"]
    return first, cols, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", action="append", help="bench dir (repeatable)")
    args = ap.parse_args()
    benches = [(HERE / b).resolve() for b in (args.bench or ["../tb", "../tb_gpt5"])]
    work = HERE / "work"
    mutants = sorted((HERE / "mutants").glob("*.sv"))
    if not mutants:
        sys.exit("no mutants; run make_mutants.py first")

    gold_dir = work / "golden"
    elaborate(GOLDEN_SV, gold_dir)
    gold_trace = {}
    for b in benches:
        v = run_bench(b, gold_dir / "sim.v", gold_dir / b.name)
        if v != "PASS":
            sys.exit(f"bench {b.name} does not pass on the elaborated golden ({v}); see {gold_dir / b.name}/sim.log")
        gold_trace[b.name] = read_trace(gold_dir / b.name / "trace.csv")
        print(f"golden {b.name}: PASS, {len(gold_trace[b.name])} trace rows")

    rows = []
    for sv in mutants:
        name = sv.stem
        mdir = work / name
        elaborate(sv, mdir)
        fr = formal(gold_dir, mdir, mdir / "formal")
        real = fr["all"] == "FAIL"
        kind = ("port-only" if fr["core"] == "PASS" else "propagates") if real else "equivalent?"
        cells = []
        for b in benches:
            v = run_bench(b, mdir / "sim.v", mdir / b.name)
            if v == "FAIL":
                cells.append("caught")
            elif v == "ERROR":
                cells.append("ERROR (crash)")
            elif not real:
                cells.append("pass (no bug)")
            else:
                first, cols, n = diff(gold_trace[b.name], read_trace(mdir / b.name / "trace.csv"))
                if first is None:
                    cells.append("**STIMULUS_MISS**")
                else:
                    cells.append(f"**CHECKER_MISS** ({'/'.join(cols)} wrong from cycle {first}, {n} cycles)")
        rows.append((name, fr["all"], fr["core"], kind, cells))
        print(f"{name:26s} all={fr['all']:5s} core={fr['core']:5s} {kind:11s} " + " | ".join(cells))

    out = HERE / "RESULTS.md"
    with open(out, "w") as f:
        f.write("# Targeted status-output mutants, fifo_v3 (8x8)\n\n"
                "Generated by `run.py`; mutants defined in `make_mutants.py`.\n\n"
                "Formal `all` = golden vs mutant on every output (FAIL = real bug). "
                "Formal `core` = empty_o/data_o only (PASS = bug visible only on full_o/usage_o).\n\n")
        f.write("| mutant | formal all | formal core | kind | " + " | ".join(f"`{b.name}/`" for b in benches) + " |\n")
        f.write("|---|---|---|---|" + "---|" * len(benches) + "\n")
        for name, a, c, kind, cells in rows:
            f.write(f"| {name} | {a} | {c} | {kind} | " + " | ".join(cells) + " |\n")
        real_rows = [r for r in rows if r[1] == "FAIL"]
        f.write("\nCaught / real bugs: " + ", ".join(
            f"`{b.name}/` {sum(r[4][i] == 'caught' for r in real_rows)}/{len(real_rows)}"
            for i, b in enumerate(benches)) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
