#!/usr/bin/env python3
"""
Hand-written mutants of fifo_v3 aimed at the status outputs (full_o, usage_o).

Why these exist: MCY mutates netlist cells. In fifo_v3, usage_o is the count
register's Q and full_o is the same comparator that gates pushes, so every MCY
mutant "on" those outputs also corrupts the internal count and shows up on
empty_o/data_o. Cell-level mutation cannot produce a bug that lives only on the
status ports. These mutants can. run.sh proves which ones are port-only
(data_o/empty_o formally equivalent to the golden) and which propagate.

Each mutant = golden rtl/fifo_v3.sv with exact-string edits; each edit must
match exactly once. Writes mutants/<name>.sv.
"""
from pathlib import Path

HERE = Path(__file__).resolve().parent
GOLDEN = HERE / ".." / "rtl" / "fifo_v3.sv"

FULL_LINE = "        assign full_o       = (status_cnt_q == FifoDepth[ADDR_DEPTH:0]);\n"
USAGE_LINE = "    assign usage_o = status_cnt_q[ADDR_DEPTH-1:0];\n"
PUSH_GATE = "        if (push_i && ~full_o) begin\n"
HOLD_GATE = "        if (push_i && pop_i &&  ~full_o && ~empty_o)\n"


def decouple_full(port_expr):
    """Internal logic keeps the correct full; only the full_o port is driven by port_expr."""
    return [
        (FULL_LINE,
         "        assign full_int     = (status_cnt_q == FifoDepth[ADDR_DEPTH:0]);\n"
         f"        assign full_o       = {port_expr};\n"),
        ("    logic gate_clock;\n", "    logic gate_clock;\n    logic full_int;\n"),
        (PUSH_GATE, "        if (push_i && ~full_int) begin\n"),
        (HOLD_GATE, "        if (push_i && pop_i &&  ~full_int && ~empty_o)\n"),
    ]


MUTANTS = {
    # --- port-only: usage_o ---
    # "usage should not wrap": reports 7 when full instead of the truncated 0
    "T1_usage_saturates": [
        (USAGE_LINE,
         "    assign usage_o = (status_cnt_q == FifoDepth[ADDR_DEPTH:0]) ? '1 : status_cnt_q[ADDR_DEPTH-1:0];\n"),
    ],
    # combinational look-ahead: usage from the next-state count, not the register
    "T2_usage_from_next": [
        (USAGE_LINE, "    assign usage_o = status_cnt_n[ADDR_DEPTH-1:0];\n"),
    ],
    # status pipelined one cycle too many
    "T3_usage_one_cycle_late": [
        (USAGE_LINE,
         "    logic [ADDR_DEPTH-1:0] usage_d;\n"
         "    always_ff @(posedge clk_i or negedge rst_ni)\n"
         "        if (~rst_ni) usage_d <= '0; else usage_d <= status_cnt_q[ADDR_DEPTH-1:0];\n"
         "    assign usage_o = usage_d;\n"),
    ],
    # --- port-only: full_o (internal push gating stays correct) ---
    # port left tied off
    "T4_full_port_stuck0": decouple_full("1'b0"),
    # almost-full wired to the full port
    "T5_full_port_early": decouple_full("(status_cnt_q >= FifoDepth[ADDR_DEPTH:0] - 1)"),
    # --- control: the same "early full" bug, but in the one shared comparator ---
    # (propagates: pushes at count 7 are dropped, so data_o/empty_o change too)
    "C1_full_early_shared": [
        (FULL_LINE,
         "        assign full_o       = (status_cnt_q == FifoDepth[ADDR_DEPTH:0] - 1);\n"),
    ],
}


def main():
    src = GOLDEN.read_text()
    out = HERE / "mutants"
    out.mkdir(exist_ok=True)
    for name, edits in MUTANTS.items():
        s = src
        for old, new in edits:
            n = s.count(old)
            assert n == 1, f"{name}: edit target occurs {n}x: {old!r}"
            s = s.replace(old, new)
        (out / f"{name}.sv").write_text(s)
        print(f"wrote mutants/{name}.sv")


if __name__ == "__main__":
    main()
