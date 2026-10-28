import csv
import os
import random
from contextlib import nullcontext

import cocotb
from cocotb.triggers import ReadOnly, Timer


DEPTH = 8
DATA_MASK = 0xFF
USAGE_MASK = 0x7


class FifoBench:
    def __init__(self, dut, writer):
        self.dut = dut
        self.writer = writer
        self.cycle = 0
        self.memory = [0] * DEPTH
        self.read_index = 0
        self.write_index = 0
        self.count = 0

        dut.clk_i.value = 0
        dut.rst_ni.value = 1
        dut.testmode_i.value = 0
        dut.push_i.value = 0
        dut.pop_i.value = 0
        dut.flush_i.value = 0
        dut.data_i.value = 0

    def reset_model(self):
        self.memory = [0] * DEPTH
        self.read_index = 0
        self.write_index = 0
        self.count = 0

    def advance_model(self, rst_n, push, data, pop, flush):
        if not rst_n:
            self.reset_model()
            return

        # Acceptance depends on occupancy before this edge.
        accept_push = bool(push and self.count < DEPTH)
        accept_pop = bool(pop and self.count > 0)

        # Flush resets pointers and count, but does not suppress an
        # otherwise accepted memory write in the supplied RTL.
        if accept_push:
            self.memory[self.write_index] = data

        if flush:
            self.read_index = 0
            self.write_index = 0
            self.count = 0
            return

        if accept_push:
            self.write_index = (self.write_index + 1) % DEPTH
        if accept_pop:
            self.read_index = (self.read_index + 1) % DEPTH

        self.count += int(accept_push) - int(accept_pop)

    def sample(self):
        result = []
        for name in ("full_o", "empty_o", "usage_o", "data_o"):
            value = getattr(self.dut, name).value
            assert value.is_resolvable, (
                f"Cycle {self.cycle}: {name} contains unknown bits: {value}"
            )
            result.append(int(value))
        return tuple(result)

    def check(self, observed, phase):
        expected = (
            int(self.count == DEPTH),
            int(self.count == 0),
            self.count & USAGE_MASK,
            self.memory[self.read_index],
        )
        for name, actual, wanted in zip(
            ("full_o", "empty_o", "usage_o", "data_o"),
            observed,
            expected,
        ):
            assert actual == wanted, (
                f"Cycle {self.cycle}, {phase}: {name}={actual}, "
                f"expected {wanted}; count={self.count}, "
                f"read_index={self.read_index}, "
                f"write_index={self.write_index}"
            )

    async def step(self, push=0, data=0, pop=0, flush=0, rst_n=1):
        push = int(bool(push))
        pop = int(bool(pop))
        flush = int(bool(flush))
        rst_n = int(bool(rst_n))
        data = int(data) & DATA_MASK

        # Leave the previous read-only phase before driving anything.
        await Timer(1, unit="ns")
        self.dut.clk_i.value = 0
        self.dut.rst_ni.value = rst_n
        self.dut.testmode_i.value = 0
        self.dut.push_i.value = push
        self.dut.data_i.value = data
        self.dut.pop_i.value = pop
        self.dut.flush_i.value = flush

        if not rst_n:
            self.reset_model()

        await Timer(4, unit="ns")
        await ReadOnly()

        # Check asynchronous reset before a rising edge and verify
        # that changing inputs cannot alter the current head.
        self.check(self.sample(), "before rising edge")

        await Timer(1, unit="ns")
        self.dut.clk_i.value = 1
        self.advance_model(rst_n, push, data, pop, flush)

        await Timer(4, unit="ns")
        await ReadOnly()
        observed = self.sample()

        if self.writer is not None:
            self.writer.writerow(
                (
                    self.cycle,
                    rst_n,
                    push,
                    data,
                    pop,
                    flush,
                    *observed,
                )
            )

        self.check(observed, "after rising edge")
        self.cycle += 1


async def exercise(bench, rng):
    # Reset edges are included in the same trace as all other stimulus.
    await bench.step(rst_n=0)
    await bench.step(rst_n=0, push=1, pop=1, flush=1, data=0xFF)
    await bench.step()

    patterns = (
        [0x00] * DEPTH,
        [0xFF] * DEPTH,
        [1 << bit for bit in range(8)],
        [DATA_MASK ^ (1 << bit) for bit in range(8)],
        [0xAA, 0x55, 0x00, 0xFF, 0x81, 0x7E, 0x18, 0xE7],
        list(range(DEPTH)),
    )

    for values in patterns:
        await bench.step(flush=1)
        for value in values:
            await bench.step(push=1, data=value)

        # A full queue rejects writes and retains its existing contents.
        for _ in range(4):
            await bench.step(push=1, data=rng.randrange(256))

        for _ in range(DEPTH):
            await bench.step(pop=1, data=rng.randrange(256))

        # An empty queue rejects reads.
        for _ in range(4):
            await bench.step(pop=1, data=rng.randrange(256))

    # Every occupancy, push/pop combination, and flush combination.
    # At empty, simultaneous push/pop accepts only the push.
    # At full, simultaneous push/pop accepts only the pop.
    for occupancy in range(DEPTH + 1):
        for push, pop in ((0, 0), (1, 0), (0, 1), (1, 1)):
            for flush in (0, 1):
                await bench.step(flush=1)
                for index in range(occupancy):
                    await bench.step(
                        push=1,
                        data=(occupancy * 29 + index * 47 + 13) & DATA_MASK,
                    )

                await bench.step(
                    push=push,
                    pop=pop,
                    flush=flush,
                    data=rng.randrange(256),
                )

                for _ in range(DEPTH + 1):
                    await bench.step(pop=1, data=rng.randrange(256))

    # Maintain different occupancies while both pointers wrap repeatedly.
    for occupancy in range(1, DEPTH):
        await bench.step(flush=1)
        for index in range(occupancy):
            await bench.step(push=1, data=(index * 53 + occupancy))

        for index in range(48):
            await bench.step(
                push=1,
                pop=1,
                data=(index * 37 + occupancy * 19) & DATA_MASK,
            )

        for _ in range(DEPTH + 1):
            await bench.step(pop=1)

    # Assert reset between rising edges at every possible occupancy,
    # including with conflicting input requests.
    for occupancy in range(DEPTH + 1):
        await bench.step(flush=1)
        for _ in range(occupancy):
            await bench.step(push=1, data=rng.randrange(256))

        await bench.step(
            rst_n=0, push=1, pop=1, flush=1, data=0xA5
        )
        await bench.step(
            rst_n=0, push=1, pop=0, flush=0, data=0x5A
        )
        await bench.step(push=1, data=(occupancy * 31 + 7))
        await bench.step(pop=1)

    # Alternate traffic biases to exercise full/empty stretches,
    # stalls, simultaneous operations, resets, and flush collisions.
    probabilities = (
        (0.85, 0.15),
        (0.15, 0.85),
        (0.80, 0.80),
        (0.50, 0.50),
        (0.15, 0.15),
    )

    for index in range(1700):
        push_probability, pop_probability = probabilities[
            (index // 85) % len(probabilities)
        ]
        push = int(rng.random() < push_probability)
        pop = int(rng.random() < pop_probability)
        data = rng.randrange(256)
        flush = int(rng.randrange(29) == 0)
        rst_n = int(rng.randrange(83) != 0)

        await bench.step(
            push=push,
            data=data,
            pop=pop,
            flush=flush,
            rst_n=rst_n,
        )

    # Drain outstanding traffic, then refill and drain once more.
    for _ in range(DEPTH + 1):
        await bench.step(pop=1)

    for value in range(DEPTH):
        await bench.step(push=1, data=(0xF0 ^ (value * 17)))

    for _ in range(DEPTH + 1):
        await bench.step(pop=1)

    await bench.step()
    assert bench.cycle < 5000, "Testbench exceeded its cycle budget"


@cocotb.test()
async def test_fifo_v3(dut):
    rng = random.Random(int(os.environ.get("SEED", "1")))
    trace_path = os.environ.get("TRACE")

    trace_context = (
        open(trace_path, "w", newline="", encoding="utf-8")
        if trace_path is not None
        else nullcontext(None)
    )

    with trace_context as trace_file:
        writer = csv.writer(trace_file) if trace_file is not None else None
        if writer is not None:
            writer.writerow(
                (
                    "cycle",
                    "rst_n",
                    "push",
                    "data_i",
                    "pop",
                    "flush",
                    "full",
                    "empty",
                    "usage",
                    "data_o",
                )
            )

        bench = FifoBench(dut, writer)
        await exercise(bench, rng)