#!/usr/bin/env python3
"""
classify.py: explain WHY each surviving mutant survived.

MCY tells you that a mutant is UNCOVERED (the bench passed, but formal proved
the mutant is not equivalent to the golden). This script splits those into:

  STIMULUS_MISS : under the bench's own stimulus, the mutant's outputs were
                  identical to the golden's on every cycle. The bug was there
                  but the test never drove the design into it. The checker
                  had nothing to see. Fix: better stimulus.

  CHECKER_MISS  : the mutant's outputs DID differ from the golden's at some
                  cycle under the bench's own stimulus, and the bench still
                  passed. The bug showed itself; the checker didn't look.
                  Fix: better checks / assertions.

Method: run the bench twice with the same seed, once on the golden RTL and
once on the mutant, with TRACE set so every output is logged every cycle;
diff the two traces. Deterministic stimulus is what makes this valid.

For each mutant it also records which output columns first diverged and at
which cycle, and where the formal counterexample trace lives, so you can
look at the input sequence that would have exposed it.

Usage (from a design's mcy/ directory, after `mcy run`):
    python3 ../../../scripts/classify.py [--tag UNCOVERED] [--out report.md]
"""

import argparse
import csv
import os
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path


def mcy_scripts_dir():
    """Locate MCY's helper scripts (create_mutated.sh) the way mcy itself does."""
    mcy = shutil.which("mcy")
    if not mcy:
        sys.exit("mcy not found in PATH")
    cand = Path(mcy).resolve().parent.parent / "share" / "mcy" / "scripts"
    if cand.is_dir():
        return cand
    env = os.environ.get("MCY_SCRIPTS")
    if env and Path(env).is_dir():
        return Path(env)
    sys.exit(f"could not find MCY scripts dir (looked in {cand}); set MCY_SCRIPTS")


def load_mutants(db_path, tag):
    """Mutants carrying `tag`; or, with tag=SURVIVED, every mutant the bench passed on
    (useful before the formal results are in, but then equivalent mutants are included)."""
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    if tag == "SURVIVED":
        rows = cur.execute(
            "SELECT m.mutation_id, m.mutation FROM mutations m "
            "JOIN results r ON r.mutation_id = m.mutation_id "
            "WHERE r.test = 'test_sim' AND r.result = 'PASS' "
            "ORDER BY m.mutation_id").fetchall()
    else:
        rows = cur.execute(
            "SELECT m.mutation_id, m.mutation FROM mutations m "
            "JOIN tags t ON t.mutation_id = m.mutation_id WHERE t.tag = ? "
            "ORDER BY m.mutation_id", (tag,)).fetchall()
    con.close()
    # MCY always includes the unmutated design as a control ("mutate -mode none")
    return [(i, m) for i, m in rows if m.strip() != "mutate -mode none"]


def make_mutant(scripts, design_il, mutation, workdir):
    """Write mutated.v for one mutation into workdir."""
    workdir.mkdir(parents=True, exist_ok=True)
    (workdir / "input.txt").write_text(f"1 {mutation}\n")
    subprocess.run(
        ["bash", str(scripts / "create_mutated.sh"), "-d", str(design_il),
         "-o", "mutated.v"],
        cwd=workdir, check=True, capture_output=True)
    return workdir / "mutated.v"


def run_bench(tb_dir, rtl, workdir, trace):
    """Run the cocotb bench on `rtl`; return True if it passed."""
    env = dict(os.environ)
    env["TRACE"] = str(trace)
    r = subprocess.run(
        ["make", "-C", str(tb_dir), f"RTL={rtl}", f"SIM_BUILD={workdir}/sim_build",
         f"COCOTB_RESULTS_FILE={workdir}/results.xml"],
        env=env, capture_output=True, text=True)
    (workdir / "sim.log").write_text(r.stdout + r.stderr)
    return r.returncode == 0


def read_trace(path):
    with open(path, newline="") as f:
        rd = csv.reader(f)
        header = next(rd)
        return header, [row for row in rd]


def diff_traces(golden, mutant):
    """Return (first_cycle, [columns that differ at that cycle], total_diff_cycles)."""
    hdr, g = golden
    _, m = mutant
    first = None
    cols = []
    n = 0
    for gr, mr in zip(g, m):
        if gr != mr:
            n += 1
            if first is None:
                first = gr[0]
                cols = [hdr[i] for i in range(len(hdr)) if gr[i] != mr[i]]
    if len(g) != len(m):
        n += abs(len(g) - len(m))
        if first is None:
            first = str(min(len(g), len(m)))
            cols = ["<trace length>"]
    return first, cols, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="UNCOVERED",
                    help="MCY tag to classify (default UNCOVERED)")
    ap.add_argument("--out", default="classify_report.md")
    ap.add_argument("--work", default="classify_work")
    args = ap.parse_args()

    here = Path.cwd()
    db = here / "database" / "db.sqlite3"
    design_il = here / "database" / "design.il"
    tb_dir = (here / ".." / "tb").resolve()
    golden_rtl = (here / ".." / "rtl").resolve()
    if not db.exists():
        sys.exit("no MCY database here; run from the design's mcy/ dir after `mcy run`")
    rtl_files = sorted(golden_rtl.glob("*.v"))
    if len(rtl_files) != 1:
        sys.exit(f"expected exactly one golden .v in {golden_rtl}, found {rtl_files}")
    golden_rtl = rtl_files[0]

    scripts = mcy_scripts_dir()
    work = here / args.work
    work.mkdir(exist_ok=True)

    # golden trace, once
    gdir = work / "golden"
    gdir.mkdir(exist_ok=True)
    gtrace = gdir / "trace.csv"
    if not run_bench(tb_dir, golden_rtl, gdir, gtrace):
        sys.exit("bench FAILS on the golden design; fix that before classifying anything")
    golden = read_trace(gtrace)

    mutants = load_mutants(db, args.tag)
    print(f"{len(mutants)} mutants tagged {args.tag}")

    results = []
    for mid, mutation in mutants:
        mdir = work / f"mut_{mid}"
        rtl = make_mutant(scripts, design_il, mutation, mdir)
        mtrace = mdir / "trace.csv"
        passed = run_bench(tb_dir, rtl, mdir, mtrace)
        if not mtrace.exists():
            verdict, first, cols, n = "SIM_ERROR", None, [], 0
        else:
            first, cols, n = diff_traces(golden, read_trace(mtrace))
            if not passed:
                verdict = "CAUGHT_ON_RERUN"   # nondeterminism; should not happen
            elif n == 0:
                verdict = "STIMULUS_MISS"
            else:
                verdict = "CHECKER_MISS"
        results.append((mid, mutation, verdict, first, cols, n))
        print(f"  mutant {mid:4d}  {verdict:14s}  first_diff_cycle={first}  cols={cols}  diff_cycles={n}")

    # ---- report ----------------------------------------------------------
    counts = {}
    for r in results:
        counts[r[2]] = counts.get(r[2], 0) + 1
    lines = [f"# Survivor classification ({args.tag})", ""]
    lines.append(f"Design: `{golden_rtl.name}`  Bench: `{tb_dir.name}/`  Mutants: {len(results)}")
    lines.append("")
    for k in ("STIMULUS_MISS", "CHECKER_MISS", "CAUGHT_ON_RERUN", "SIM_ERROR"):
        if k in counts:
            lines.append(f"- **{k}**: {counts[k]}")
    lines.append("")
    lines.append("| id | verdict | first diff cycle | outputs that differ | # diff cycles | mutation |")
    lines.append("|---:|---|---:|---|---:|---|")
    for mid, mutation, verdict, first, cols, n in results:
        src = " ".join(t for t in mutation.split() if t.startswith("fifo.v:") or t.endswith(".v"))
        lines.append(f"| {mid} | {verdict} | {first if first is not None else ''} | "
                     f"{', '.join(cols)} | {n} | `{mutation}` |")
    lines.append("")
    lines.append("To see the formal counterexample (the input sequence that exposes a bug) for mutant N: "
                 "`mcy reset test_eq N && mcy task -k test_eq N`, then open "
                 "`tasks/<id>/test_eq_1/engine_0/trace.vcd` (GTKWave / Surfer).")
    Path(args.out).write_text("\n".join(lines) + "\n")
    print(f"\nwrote {args.out}")
    print("summary:", counts)


if __name__ == "__main__":
    main()
