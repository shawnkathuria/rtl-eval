"""
cocotb testbench for fifo.v.

This bench stands in for the thing we ultimately want to evaluate: a
testbench of unknown quality (eventually, an agent-generated one). It is
deliberately decent-but-incomplete so that the mutation run has survivors to
classify. Known gaps, on purpose:

  * it never checks `full`
  * it never checks `count`
  * stimulus is random traffic only; it does not deliberately drive the
    FIFO to full and hold it there, so the full-side pointer logic may be
    under-exercised

Two properties matter for the evaluator, independent of how good the checks
are:

  1. Stimulus is DETERMINISTIC (fixed seed). The same test run against the
     golden design and against a mutant sees exactly the same inputs. That is
     what lets scripts/classify.py compare output traces across the two runs.
  2. Every cycle, ALL DUT outputs are written to a trace file (when TRACE is
     set), whether or not the bench looks at them. The trace is the record of
     "what the bug did"; the pass/fail verdict is the record of "what the
     checker noticed".

Environment variables:
  SEED   : random seed (default 1)
  TRACE  : if set, path of the CSV trace to write
  CYCLES : number of traffic cycles (default 400)
"""

import csv
import os
import random
from collections import deque

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, Timer


def _int(sig):
    """Resolve a signal to int, treating X/Z as -1 so it still lands in the trace."""
    try:
        return int(sig.value)
    except ValueError:
        return -1


class Tracer:
    def __init__(self, path):
        self.f = open(path, "w", newline="") if path else None
        self.w = csv.writer(self.f) if self.f else None
        if self.w:
            self.w.writerow(["cycle", "rst", "wr_en", "wr_data", "rd_en",
                             "full", "empty", "count", "rd_data"])

    def row(self, cycle, dut):
        if not self.w:
            return
        self.w.writerow([cycle, _int(dut.rst), _int(dut.wr_en), _int(dut.wr_data),
                         _int(dut.rd_en), _int(dut.full), _int(dut.empty),
                         _int(dut.count), _int(dut.rd_data)])

    def close(self):
        if self.f:
            self.f.close()


@cocotb.test()
async def random_traffic(dut):
    seed = int(os.environ.get("SEED", "1"))
    cycles = int(os.environ.get("CYCLES", "400"))
    tracer = Tracer(os.environ.get("TRACE"))
    rng = random.Random(seed)

    width = len(dut.wr_data)
    depth = 2 ** (len(dut.count) - 1)

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # --- reset -----------------------------------------------------------
    dut.rst.value = 1
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    model = deque()      # reference model: what the FIFO should contain
    cycle = 0
    pops_checked = 0

    # Phases vary the write/read bias so the FIFO drifts between near-empty
    # and near-full. (It still never *forces* full and holds it.)
    phases = [(0.8, 0.2), (0.5, 0.5), (0.2, 0.8), (0.6, 0.6)]

    for cyc in range(cycles):
        p_wr, p_rd = phases[(cyc // 50) % len(phases)]
        wr = 1 if rng.random() < p_wr else 0
        rd = 1 if rng.random() < p_rd else 0
        data = rng.getrandbits(width)

        dut.wr_en.value = wr
        dut.rd_en.value = rd
        dut.wr_data.value = data

        # Sample outputs in the same delta as the inputs are visible
        # (combinational outputs reflect the state before this edge).
        await ReadOnly()
        full = _int(dut.full)
        empty = _int(dut.empty)
        rd_data = _int(dut.rd_data)
        tracer.row(cycle, dut)
        cycle += 1

        # --- checks the bench actually performs ---------------------------
        # empty flag must agree with the model
        assert empty == (1 if len(model) == 0 else 0), \
            f"cycle {cyc}: empty={empty} but model has {len(model)} entries"

        # on a successful pop, head-of-queue data must match
        if rd and not empty:
            expect = model[0]
            assert rd_data == expect, \
                f"cycle {cyc}: rd_data={rd_data:#x} expected {expect:#x}"
            pops_checked += 1

        # --- update reference model with what the DUT *should* do ---------
        # NOTE: uses the model's own notion of full, not dut.full, so a wrong
        # full flag is not silently trusted. (It is also never asserted on.)
        model_full = len(model) == depth
        if rd and len(model) > 0:
            model.popleft()
        if wr and not model_full:
            model.append(data)

        await RisingEdge(dut.clk)

    # drain
    dut.wr_en.value = 0
    while len(model) > 0:
        dut.rd_en.value = 1
        await ReadOnly()
        rd_data = _int(dut.rd_data)
        tracer.row(cycle, dut)
        cycle += 1
        assert rd_data == model[0], \
            f"drain: rd_data={rd_data:#x} expected {model[0]:#x}"
        model.popleft()
        pops_checked += 1
        await RisingEdge(dut.clk)

    dut.rd_en.value = 0
    await ReadOnly()
    tracer.row(cycle, dut)
    assert _int(dut.empty) == 1, "FIFO not empty after drain"
    tracer.close()

    dut._log.info(f"random_traffic: seed={seed} cycles={cycles} pops_checked={pops_checked}")
    assert pops_checked > 0, "bench never checked a pop; stimulus is broken"
