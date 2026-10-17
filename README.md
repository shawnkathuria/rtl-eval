# rtl-eval

Evaluating testbenches, not designs. Given a golden RTL block and a
testbench of unknown quality, this scores the testbench by mutation
analysis and then explains every miss:

- **STIMULUS_MISS** — the bug was there, the test never drove the design into it
- **CHECKER_MISS** — the bug showed up on the outputs, the test didn't look

Formal equivalence (SymbiYosys miter, golden vs. mutant) is the ground truth:
mutants with no counterexample are equivalent and dropped from the score;
for every real miss, the counterexample is the input sequence that would have
exposed it.

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
  mcy/test_eq.sh      MCY test 2: BMC miter golden vs mutant (SymbiYosys)
  mcy/miter.sv        the miter
  mcy/test_eq.sby     SymbiYosys config (engine, depth, timeout)
scripts/classify.py   splits UNCOVERED mutants into STIMULUS_MISS / CHECKER_MISS
```

## Install (macOS, Apple Silicon)

Easiest: `./setup_mac.sh` (does everything below). Then `git init && git add -A && git commit -m init`.

Manual:

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

`mcy run` is resumable; rerun it if it stops. `mcy purge` wipes results.
`mcy dash` (web) browses results. To get the formal counterexample for mutant N:
`mcy reset test_eq N && mcy task -k test_eq N`, then open
`tasks/<id>/test_eq_1/engine_0/trace.vcd`.

## What the numbers mean

| MCY tag    | bench on mutant | formal golden-vs-mutant | meaning |
|------------|-----------------|-------------------------|---------|
| COVERED    | FAIL            | not equivalent          | real bug, caught |
| UNCOVERED  | PASS            | not equivalent          | real bug, missed -> `classify.py` |
| NOCHANGE   | PASS            | equivalent (or BMC timeout) | nothing to catch; excluded from score |
| EQGAP      | FAIL            | equivalent              | bench is flaky, or BMC depth too short; investigate |
| EQTIMEOUT  | (subset of NOCHANGE) | solver timed out   | treated as equivalent; rerun deeper to be sure |

Mutation score = COVERED / (COVERED + UNCOVERED).

## Known gaps in the bench (deliberate; same in `test_fifo.py` and `test_fifo_v3.py`)

The bench stands in for an agent-generated one, so it is decent but
incomplete on purpose: never checks `full`, never checks `count`, random
traffic only. Expect CHECKER_MISS on mutations in the `count` subtractor and
the `full` comparator, and STIMULUS_MISS on anything behind a corner the
random traffic rarely reaches. Replacing this file with a generated bench is
the whole point.

## Next steps

1. Larger mutation count (300+) on the FIFO; hand-check a few classifications
   against the formal counterexample to confirm the labels are right.
2. More blocks from the same source family: PULP `rr_arb_tree` (arbiter),
   `stream_fifo`, Forencich's `axis_fifo` (MIT). Open-source with provenance,
   not hand-written.
3. Source-level mutants alongside MCY's netlist mutants (open question to Wan).
4. Generated testbenches as the thing under evaluation; then the real
   experiment: does this score predict missed bugs in unseen agent-generated RTL?
