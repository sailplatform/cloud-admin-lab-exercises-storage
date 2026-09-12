#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Azure SQL Q1: Create a Logical Server and a Database.
#  Read-only. Exit code = number of failed checks. (Never checks the password.)
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

RG="$(lab_rg sql01)"
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

rg_exists()   { [[ "$(az group exists -n "$RG" 2>/dev/null)" == "true" ]]; }
srv_exists()  { [[ -n "$(srv_name)" ]]; }
db_exists()   { [[ "$(db_field name)" == "$DB" ]]; }
# `edition || sku.tier` reads whichever field this CLI version populates.
db_is_basic() { [[ "$(db_field 'edition || sku.tier')" == "Basic" ]]; }
db_online()   { [[ "$(db_field status)" == "Online" ]]; }

echo "======================================================"
echo " Validating Azure SQL Q1: Create Server and Database"
echo "   Resource group: $RG"
echo "======================================================"

check "Resource group '$RG' exists"                  rg_exists
check "A SQL logical server exists in '$RG'"         srv_exists
check "Database '$DB' exists on the server"          db_exists
check "Database '$DB' is on the Basic tier"          db_is_basic
check "Database '$DB' status is Online"              db_online

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
