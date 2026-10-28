# LLM testbench prompt — fifo_v3

Every LLM-written bench for fifo_v3 is produced from the prompt below, verbatim, with the
contents of `rtl/fifo_v3.sv` pasted where indicated. One prompt, one reply, no follow-up
turns, no edits by hand. Record per bench: model name and version, date, temperature or
reasoning setting if the UI exposes it, and the raw reply (save it as `RAW.md` next to the
bench).

Protocol:
1. Save the reply's Python file as `tb_<model>/test_fifo_v3.py`, copy `tb/Makefile` into
   `tb_<model>/` unchanged.
2. Gate: the bench must pass on the unmutated design (`make -C tb_<model>`). If it fails,
   paste the failure log back to the model as one follow-up turn ("your bench fails on the
   golden RTL: <log>. Fix the bench, not the RTL.") and save that turn too. One repair turn
   max; a bench that still fails on the golden is recorded as DNF, not fixed by hand.
3. Score it with MCY exactly as `tb/` was scored (same config, same 300 mutants, same
   `test_eq.sby`), then run `classify.py` on its UNCOVERED set.

---

## Prompt (paste from here to the end of the file)

Write a cocotb testbench for the SystemVerilog FIFO below.

Harness contract — the bench runs unmodified inside an automated flow, so these are hard
requirements:

- One file, `test_fifo_v3.py`, cocotb 2.x API, Icarus Verilog simulator. Reply with the
  complete file and nothing else.
- Top-level module is `fifo_v3`, elaborated with `DATA_WIDTH=8`, `DEPTH=8`,
  `FALL_THROUGH=0`. The flow compiles the RTL with `-DSYNTHESIS`, so the SVA assertions
  inside the module are not present; the bench must do all checking itself.
- Interact with the design through its ports only. Never reference internal signals; the
  flow substitutes a re-elaborated module with the same ports but different internal
  names, and any internal reference will fail to resolve.
- The bench drives the clock (`clk_i`) and the asynchronous active-low reset (`rst_ni`).
  Tie `testmode_i` to 0.
- A mismatch between expected and observed behavior must raise `AssertionError` (use
  `assert`). Do not catch exceptions, do not log an error and continue, do not use any
  other failure mechanism; the flow treats a non-assertion exception as a bench crash,
  not a caught bug.
- Deterministic: seed Python's `random` from the environment variable `SEED` (default 1)
  so two runs with the same seed apply identical stimulus cycle for cycle.
- If the environment variable `TRACE` is set, write a CSV to that path with exactly this
  header, one row per rising clock edge, values as decimal integers, outputs sampled after
  they settle in that cycle (e.g. in the read-only phase):

      cycle,rst_n,push,data_i,pop,flush,full,empty,usage,data_o

  Cycles with reset asserted are logged too. The trace must cover every cycle of every
  test, in order, in one file.
- Keep total simulated length under 5000 clock cycles; the bench will be run several
  hundred times.
- Do not modify or wrap the RTL, and do not require any Verilog file other than the one
  below.

Design under test:

```systemverilog
<paste rtl/fifo_v3.sv here>
```
