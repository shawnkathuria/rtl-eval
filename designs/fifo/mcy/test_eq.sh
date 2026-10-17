#!/bin/bash
# MCY test: bounded equivalence check, golden vs mutant, via a SymbiYosys miter.
# PASS = no difference found within the BMC depth (treated as equivalent).
# FAIL = counterexample found; the trace is the input sequence that exposes the bug.

exec 2>&1
set -ex

## mutated design with a 'mutsel' control input (0 = golden, idx = mutant)
bash "$SCRIPTS/create_mutated.sh" -c -o mutated.il

cp "$PRJDIR/miter.sv" "$PRJDIR/test_eq.sby" .

while read -r idx mut; do
    sby -f test_eq.sby "$idx"
    status=$(head -n1 "test_eq_${idx}/status" | awk '{print $1}')
    echo "$idx $status" >> output.txt
done < input.txt

exit 0
