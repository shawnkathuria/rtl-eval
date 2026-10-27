# rtl-eval

Evaluating testbenches, not designs. Given a golden RTL block and a
testbench of unknown quality, this scores the testbench by mutation
analysis and then explains every miss:

- **STIMULUS_MISS** — the bug was there, the test never drove the design into it
- **CHECKER_MISS** — the bug showed up on the outputs, the test didn't look

Formal equivalence (SymbiYosys miter, golden vs. mutant, `mode prove` with
abc pdr) is the ground truth: mutants proven equivalent are dropped from the
score; for every real miss, the counterexample is the input sequence that
would have exposed it.

Target: evaluate agent-generated testbenches/checkers (Wan, Sept 29 email),
toward ICCAD 2027. MCY is the baseline and implementation foundation.

## Layout

```
designs/fifo_v3/      <- the real golden: PULP common_cells fifo_v3 (used in CVA6),
                         Solderpad license, see rtl/PROVENANCE.md. Same layout as below.
designs/fifo/         <- smoke-test design: a 60-line hand-written FIFO, same ports idea
  rtl/fifo.v          golden sync FIFO (8 wide x 8 deep), the design under mutation
  tb/test_fifo.py     cocotb bench under evaluation: deterministic stimulus,
                      logs every output every cycle to a CSV trace
  tb/Makefile         `make` runs the bench; RTL=... swaps in a mutant
  mcy/config.mcy      MCY project: mutation count, tag logic, report
  mcy/test_sim.sh     MCY test 1: run the bench on the mutant
  mcy/test_eq.sh      MCY test 2: formal miter golden vs mutant (SymbiYosys)
  mcy/miter.sv        the miter: identical free inputs (incl. flush_i), any output diff fails
  mcy/test_eq.sby     SymbiYosys config: mode prove, abc pdr, timeout 1800
  mcy/test_prove.sby  identical copy, used by eq_one.sh (CFG=test_prove)
scripts/classify.py   splits UNCOVERED mutants into STIMULUS_MISS / CHECKER_MISS;
                      golden = MCY's control mutant, diffs output columns only
scripts/eq_one.sh N   formal check for one mutant outside MCY's queue; leaves trace.vcd
                      and trace_tb.v (the counterexample's inputs, cycle by cycle)
scripts/sim_one.sh N  bench on one mutant, shows the assertion
```

## Install (macOS, Apple Silicon)

What actually worked: the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases)
tarball (yosys, sby, mcy, iverilog, yices, z3, gtkwave in one bundle) plus a cocotb venv.
`source ~/oss-cad-suite/environment` in every new terminal. `setup_mac.sh` tries the
Homebrew route below, which died silently on yosys; kept for reference.

Manual (Homebrew route):

```sh
brew install yosys icarus-verilog z3 python
pip3 install cocotb click            # cocotb 2.x
brew install yices2                   # optional, faster BMC engine (see test_eq.sby)

# SymbiYosys (sby) is not in Homebrew; install from source:
git clone https://github.com/YosysHQ/sby && cd sby && sudo make install && cd ..

# MCY, from source:
git clone https://github.com/YosysHQ/mcy && cd mcy
sudo mkdir -p /usr/local/bin /usr/local/share/mcy
sudo install mcy.py /usr/local/bin/mcy
sudo cp -r scripts /usr/local/share/mcy/
cd ..
```

Check: `yosys -V`, `iverilog -V`, `sby -h`, `mcy --help`, `z3 --version`,
`python3 -c "import cocotb, click"`. If `brew install yosys` gives you an old
version (< 0.40), use the OSS CAD Suite nightly instead
(https://github.com/YosysHQ/oss-cad-suite-build/releases), which bundles
yosys + sby + mcy + solvers in one tarball; then skip the sby/mcy steps above.

## Run

```sh
# 1. bench passes on the golden design?   (fifo_v3 is the real one; fifo/ is the smoke test)
cd designs/fifo_v3/tb && make && cd ../mcy

# 2. mutation run (size is in config.mcy; 100 is a reasonable first run)
mcy init
mcy run -j8            # -j = parallel tasks; formal tasks are the slow part
mcy status             # mutation score + tag counts

# 3. explain the survivors
python3 ../../../scripts/classify.py            # -> classify_report.md
python3 ../../../scripts/classify.py --tag SURVIVED   # before formal is done (includes equivalents)
```

`mcy run` is resumable; rerun it if it stops. `mcy purge` wipes everything incl. the
mutant list. `mcy reset` only clears `tasks/` and recomputes tags; cached results survive
a config change, so to rerun just the formal side after editing `test_eq.sby`:
`sqlite3 database/db.sqlite3 "delete from results where test='test_eq'; delete from tags;"`
then `mcy reset && mcy run -j8`. Mutant 1 is always the unmutated control.

Formal counterexample for mutant N: `CFG=test_prove ../../../scripts/eq_one.sh N`, then
`eq_one/N/test_prove_N/engine_0/trace.vcd` (gtkwave / surfer) or `trace_tb.v` for the
input sequence as text.

## What the numbers mean

| MCY tag    | bench on mutant | formal golden-vs-mutant | meaning |
|------------|-----------------|-------------------------|---------|
| COVERED    | FAIL            | not equivalent          | real bug, caught |
| UNCOVERED  | PASS            | not equivalent          | real bug, missed -> `classify.py` |
| NOCHANGE   | PASS            | proven equivalent       | nothing to catch; excluded from score |
| EQGAP      | FAIL            | proven equivalent       | bench is flaky, X-prop in sim, or the miter ties off an input the bench drives; investigate |
| EQTIMEOUT  | any             | solver gave up          | unresolved, not counted either way |

Mutation score = COVERED / (COVERED + UNCOVERED).

## Result: fifo_v3, 300 mutants (Oct 27 2026)

288 caught, 2 missed, 10 proven equivalent. **Score 288/290 = 99.3%.**

Both misses are in the flush path (`fifo_v3.sv:119`): mutant 300 disables flush,
mutant 262 makes it reset pointers to 1 instead of 0. The bench never asserts
`flush_i`, so `classify.py` tags both **STIMULUS_MISS** (output traces identical to
golden for all 406 bench cycles). Formal exposes 300 in two cycles: release reset, then
push and flush together; golden reports empty, mutant reports usage=1.

The bench's deliberate blind spot (never checks `full_o`/`usage_o`) was *not* found by
300 random mutants: every mutant in that logic also broke something the bench checks,
or was equivalent. A 99% score with a known hole in the checker.

Lessons that cost a day each: BMC (yices, depth 24) could not prove golden == golden
in 30 min; pdr does it in 2 s. A tied-off miter input (`flush_i=0`) turned both real
bugs into "proven equivalent". The classifier must build golden and mutant through the
identical path (MCY's control mutant), or the random stimulus diverges at cycle 0.

## Known gaps in the bench (deliberate; same in `test_fifo.py` and `test_fifo_v3.py`)

The bench stands in for an agent-generated one, so it is decent but
incomplete on purpose: never checks `full`, never checks `count`, random
traffic only. Expect CHECKER_MISS on mutations in the `count` subtractor and
the `full` comparator, and STIMULUS_MISS on anything behind a corner the
random traffic rarely reaches. Replacing this file with a generated bench is
the whole point.

## Next steps

1. A population of LLM-written benches for fifo_v3 with a spread of mutation scores.
2. A bug population that is not mutants: agent-generated RTL with known failures.
   The experiment: does a bench's mutation score predict its catch rate on those?
3. More blocks from the same source family: PULP `rr_arb_tree`, `stream_fifo`,
   Forencich's `axis_fifo` (MIT). Open-source with provenance, not hand-written.
4. Cluster runs once the matrix exists (each formal check ~30 s, trivially parallel).
