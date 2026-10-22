#!/bin/bash
# Re-run the simulation bench on ONE mutant, outside MCY's queue, and show
# what (if anything) the bench complained about. Leaves everything in sim_one/<N>/.
#
#   usage: ../../../scripts/sim_one.sh <mutation_id>
#   run from a design's mcy/ directory after `mcy init`.

set -e
N=${1:?mutation id}
HERE=$(pwd)
[ -f database/design.il ] || { echo "run from a design's mcy/ dir after mcy init" >&2; exit 1; }

MCYBIN=$(command -v mcy) || { echo "mcy not in PATH" >&2; exit 1; }
# mcy looks for its helper scripts at <bin>/../share/mcy/scripts; the OSS CAD
# Suite installs mcy under libexec/, so try both before giving up.
for cand in "$(dirname "$MCYBIN")/../share/mcy/scripts" \
            "$(dirname "$(readlink "$MCYBIN" || echo "$MCYBIN")")/../share/mcy/scripts" \
            "${MCY_SCRIPTS:-}"; do
    [ -n "$cand" ] && [ -d "$cand" ] && SCRIPTS=$(cd "$cand" && pwd) && break
done
[ -n "${SCRIPTS:-}" ] || { echo "cannot find mcy scripts dir; set MCY_SCRIPTS" >&2; exit 1; }

MUT=$(python3 - "$N" <<'EOF'
import sqlite3, sys
c = sqlite3.connect("database/db.sqlite3")
r = c.execute("select mutation from mutations where mutation_id=?", (int(sys.argv[1]),)).fetchone()
print(r[0] if r else "")
EOF
)
[ -n "$MUT" ] || { echo "no mutation $N in database" >&2; exit 1; }

W=sim_one/$N
rm -rf "$W"; mkdir -p "$W"; cd "$W"
echo "$N $MUT" > input.txt
bash "$SCRIPTS/create_mutated.sh" -d "$HERE/database/design.il" -o mutated.v
echo "== mutant $N: $MUT"
if make -C "$HERE/../tb" RTL="$PWD/mutated.v" SIM_BUILD="$PWD/sim_build" \
        COCOTB_RESULTS_FILE="$PWD/results.xml" TRACE="$PWD/trace.csv" > sim.log 2>&1; then
    echo "== bench PASSED on this mutant"
else
    echo "== bench FAILED on this mutant; the complaint:"
    grep -E "AssertionError|Error|Exception" sim.log | grep -v "^make" | head -5
fi
echo "== full log: $W/sim.log   trace: $W/trace.csv"
