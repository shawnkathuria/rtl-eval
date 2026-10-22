#!/bin/bash
# MCY test: run the cocotb bench against the mutated FIFO.
# Runs inside tasks/<id>/ with $PRJDIR = designs/fifo/mcy and $SCRIPTS = mcy scripts dir.

exec 2>&1
set -ex

## create the mutated design (plain module, same ports as the golden)
bash "$SCRIPTS/create_mutated.sh" -o mutated.v

## run the bench on it. Build in this task dir so parallel tasks don't collide.
if make -C "$PRJDIR/../tb" RTL="$PWD/mutated.v" SIM_BUILD="$PWD/sim_build" \
        COCOTB_RESULTS_FILE="$PWD/results.xml" > sim.log 2>&1; then
    echo "1 PASS" > output.txt
elif grep -q "FAIL=[1-9]" sim.log && grep -q "AssertionError" sim.log; then
    echo "1 FAIL" > output.txt       # a checker fired: the bench caught it
else
    # compile error, crash, or a non-assertion Python exception: NOT a caught bug
    echo "1 ERROR" > output.txt
fi

exit 0
