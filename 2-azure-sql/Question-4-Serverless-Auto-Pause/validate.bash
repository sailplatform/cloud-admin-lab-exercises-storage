#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Azure SQL Q4: Serverless with Auto-Pause. Read-only.
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

RG="$(lab_rg sql04)"
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
# Serverless service objectives are named with an "_S_" (e.g. GP_S_Gen5_1).
db_serverless() { [[ "$(db_field currentServiceObjectiveName)" == *_S_* ]]; }
db_autopause60(){ [[ "$(db_field autoPauseDelay)" == "60" ]]; }

echo "======================================================"
echo " Validating Azure SQL Q4: Serverless with Auto-Pause"
echo "   Resource group: $RG"
echo "======================================================"

check "A SQL logical server exists in '$RG'"          srv_exists
check "Database '$DB' exists on the server"           db_exists
check "Database '$DB' uses the Serverless model"      db_serverless
check "Auto-pause delay is 60 minutes"                db_autopause60

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
