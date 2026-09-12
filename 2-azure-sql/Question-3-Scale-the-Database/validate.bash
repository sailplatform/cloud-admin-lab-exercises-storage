#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Azure SQL Q3: Scale the Database. Read-only.
#  Exit code = number of failed checks.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_config() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/lab-config.sh" ]]; then echo "$dir/lab-config.sh"; return 0; fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CONFIG="$(find_config)" || { echo "ERROR: could not find lab-config.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"

RG="$(lab_rg sql03)"
DB="appdb"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

srv_name() { az sql server list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
db_field() {
  local s; s="$(srv_name)"; [[ -z "$s" ]] && return 1
  az sql db show -g "$RG" -s "$s" -n "$DB" --query "$1" -o tsv 2>/dev/null
}

srv_exists()    { [[ -n "$(srv_name)" ]]; }
db_exists()     { [[ "$(db_field name)" == "$DB" ]]; }
db_is_s0()      { [[ "$(db_field currentServiceObjectiveName)" == "S0" ]]; }
# `edition || sku.tier` reads whichever field this CLI version populates.
db_standard()   { [[ "$(db_field 'edition || sku.tier')" == "Standard" ]]; }

echo "======================================================"
echo " Validating Azure SQL Q3: Scale the Database"
echo "   Resource group: $RG"
echo "======================================================"

check "A SQL logical server exists in '$RG'"          srv_exists
check "Database '$DB' exists on the server"           db_exists
check "Database '$DB' service objective is S0"        db_is_s0
check "Database '$DB' edition is Standard"            db_standard

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
