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

Method: run the bench twice with the same seed, once on the golden and once
on the mutant, with TRACE set so every input and output is logged every
cycle; diff the OUTPUT columns of the two traces.

Two things make this valid, and the script checks both:

  1. The golden is MCY's own control mutant ("mutate -mode none", id 1),
     generated from database/design.il by the same create_mutated.sh path as
     every real mutant. It is therefore the exact netlist the mutants were
     derived from, with the same parameters (e.g. DATA_WIDTH set by chparam
     in config.mcy). Running the bench on the raw .sv instead would compare
     against a different design (different parameter defaults) and the
     random stimulus would diverge from cycle 0.

  2. The INPUT columns of the two traces must be identical. If they are not,
     the stimulus was not deterministic (or the designs differ in interface)
     and no verdict is possible; the mutant is reported as STIM_MISMATCH,
     which is a tooling error, not a classification.

For each mutant it also records which output columns first diverged and at
which cycle; the formal counterexample for the same mutant can be produced
with scripts/eq_one.sh.

Usage (from a design's mcy/ directory, after `mcy run`):
    python3 ../../../scripts/classify.py [--tag UNCOVERED] [--out report.md]
                                        [--inputs rst_n,push,data_i,pop,flush]
"""

import argparse
import csv
import os
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path

GOLDEN_MUTATION = "mutate -mode none"

# Trace columns that are stimulus, not response. "cycle" is the index column.
# Anything not listed here is treated as an output and diffed.
DEFAULT_INPUT_COLS = ["cycle", "rst_n", "push", "data_i", "pop", "flush"]


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
    # MCY always includes the unmutated design as a control; it is the golden, not a mutant.
    return [(i, m) for i, m in rows if m.strip() != GOLDEN_MUTATION]


def golden_mutation(db_path):
    """The control entry MCY generates for the unmutated design (normally id 1)."""
    con = sqlite3.connect(db_path)
    row = con.execute(
        "SELECT mutation_id, mutation FROM mutations WHERE mutation = ? "
        "ORDER BY mutation_id LIMIT 1", (GOLDEN_MUTATION,)).fetchone()
    con.close()
    if not row:
        sys.exit(f"no '{GOLDEN_MUTATION}' control entry in the MCY database; cannot build the golden")
    return row


def make_mutant(scripts, design_il, mutation, workdir):
    """Write mutated.v for one mutation into workdir (also used for the golden)."""
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


def diff_traces(golden, mutant, input_cols):
    """Diff the OUTPUT columns of two traces.

    Returns (status, first_cycle, [columns that differ at that cycle], total_diff_cycles).
    status is "ok", or "stim_mismatch" if any INPUT column differs (then the
    comparison is invalid and the other fields describe the input mismatch).
    """
    hdr, g = golden
    mhdr, m = mutant
    if hdr != mhdr:
        return "stim_mismatch", None, ["<header: %s vs %s>" % (hdr, mhdr)], 0
    in_idx = [i for i, c in enumerate(hdr) if c in input_cols]
    out_idx = [i for i, c in enumerate(hdr) if c not in input_cols]
    if not out_idx:
        sys.exit(f"no output columns left after removing inputs {input_cols}; header is {hdr}")

    # 1. stimulus must be identical, cycle for cycle
    for gr, mr in zip(g, m):
        bad = [hdr[i] for i in in_idx if gr[i] != mr[i]]
        if bad:
            return "stim_mismatch", gr[0], bad, 0

    # 2. diff outputs
    first, cols, n = None, [], 0
    for gr, mr in zip(g, m):
        d = [hdr[i] for i in out_idx if gr[i] != mr[i]]
        if d:
            n += 1
            if first is None:
                first, cols = gr[0], d
    if len(g) != len(m):
        n += abs(len(g) - len(m))
        if first is None:
            first, cols = str(min(len(g), len(m))), ["<trace length>"]
    return "ok", first, cols, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="UNCOVERED",
                    help="MCY tag to classify (default UNCOVERED)")
    ap.add_argument("--out", default="classify_report.md")
    ap.add_argument("--work", default="classify_work")
    ap.add_argument("--tb", default="../tb",
                    help="bench directory, relative to this mcy dir (default ../tb)")
    ap.add_argument("--inputs", default=",".join(DEFAULT_INPUT_COLS),
                    help="comma-separated trace columns that are stimulus (not diffed)")
    args = ap.parse_args()
    input_cols = [c.strip() for c in args.inputs.split(",") if c.strip()]

    here = Path.cwd()
    db = here / "database" / "db.sqlite3"
    design_il = here / "database" / "design.il"
    tb_dir = (here / args.tb).resolve()
    if not (tb_dir / "Makefile").exists():
        sys.exit(f"no Makefile in bench dir {tb_dir}")
    if not db.exists():
        sys.exit("no MCY database here; run from the design's mcy/ dir after `mcy run`")
    if not design_il.exists():
        sys.exit(f"missing {design_il}; run `mcy init` first")

    scripts = mcy_scripts_dir()
    work = here / args.work
    work.mkdir(exist_ok=True)

    # golden trace, once: MCY's own control mutant, through the same path as every mutant
    gid, gmut = golden_mutation(db)
    gdir = work / "golden"
    golden_rtl = make_mutant(scripts, design_il, gmut, gdir)
    gtrace = gdir / "trace.csv"
    if not run_bench(tb_dir, golden_rtl, gdir, gtrace):
        sys.exit(f"bench FAILS on the golden (control mutant {gid}); see {gdir}/sim.log")
    golden = read_trace(gtrace)
    print(f"golden = control mutant {gid} ({gmut}); {len(golden[1])} trace cycles; "
          f"outputs diffed: {[c for c in golden[0] if c not in input_cols]}")

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
            status, first, cols, n = diff_traces(golden, read_trace(mtrace), input_cols)
            if status == "stim_mismatch":
                verdict = "STIM_MISMATCH"      # tooling error: inputs differed, no verdict possible
            elif not passed:
                verdict = "CAUGHT_ON_RERUN"    # nondeterminism; should not happen
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
    lines.append(f"Golden: control mutant {gid} from `database/design.il`  "
                 f"Bench: `{tb_dir.name}/`  Mutants: {len(results)}  "
                 f"Outputs diffed: {', '.join(c for c in golden[0] if c not in input_cols)}")
    lines.append("")
    for k in ("STIMULUS_MISS", "CHECKER_MISS", "CAUGHT_ON_RERUN", "STIM_MISMATCH", "SIM_ERROR"):
        if k in counts:
            lines.append(f"- **{k}**: {counts[k]}")
    lines.append("")
    lines.append("| id | verdict | first diff cycle | outputs that differ | # diff cycles | mutation |")
    lines.append("|---:|---|---:|---|---:|---|")
    for mid, mutation, verdict, first, cols, n in results:
        lines.append(f"| {mid} | {verdict} | {first if first is not None else ''} | "
                     f"{', '.join(cols)} | {n} | `{mutation}` |")
    lines.append("")
    lines.append("To see the formal counterexample (the input sequence that exposes the bug) for mutant N: "
                 "`CFG=test_prove ../../../scripts/eq_one.sh N`, then open "
                 "`eq_one/N/test_prove_N/engine_0/trace.vcd` (GTKWave / Surfer) or read "
                 "`.../trace_tb.v` for the cycle-by-cycle inputs.")
    Path(args.out).write_text("\n".join(lines) + "\n")
    print(f"\nwrote {args.out}")
    print("summary:", counts)


if __name__ == "__main__":
    main()
