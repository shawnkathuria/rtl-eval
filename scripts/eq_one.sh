#!/bin/bash
# Re-run the formal golden-vs-mutant check for ONE mutant, outside MCY's queue,
# optionally at a different BMC depth. Leaves the counterexample (if any) in
# eq_one/<N>/test_eq_<N>/engine_0/trace.vcd.
#
#   usage: ../../../scripts/eq_one.sh <mutation_id> [depth]
#   run from a design's mcy/ directory after `mcy init`.

set -e
N=${1:?mutation id}
DEPTH=${2:-}
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

W=eq_one/$N
rm -rf "$W"; mkdir -p "$W"; cd "$W"
echo "$N $MUT" > input.txt
bash "$SCRIPTS/create_mutated.sh" -c -d "$HERE/database/design.il" -o mutated.il
cp "$HERE/miter.sv" .
sed 's|^../../miter.sv|miter.sv|' "$HERE/test_eq.sby" > test_eq.sby
[ -n "$DEPTH" ] && sed -i.bak "s/^depth .*/depth $DEPTH/" test_eq.sby

echo "== mutant $N: $MUT"
echo "== depth: $(grep ^depth test_eq.sby)"
sby -f test_eq.sby "$N" 2>&1 | grep -E "summary:|DONE"
echo "== status: $(head -n1 test_eq_$N/status)"
[ -f "test_eq_$N/engine_0/trace.vcd" ] && echo "== counterexample: $W/test_eq_$N/engine_0/trace.vcd"
