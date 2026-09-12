#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Azure SQL Q2: Configure the Server Firewall. Read-only.
#  Exit code = number of failed checks. (Never needs the DB password.)
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

RG="$(lab_rg sql02)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

srv_name() { az sql server list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
srv_exists() { [[ -n "$(srv_name)" ]]; }

# IPv4 dotted-quad -> integer, for range comparison.
ip2int() { local a b c d; IFS=. read -r a b c d <<<"$1"; echo $(( (a<<24)+(b<<16)+(c<<8)+d )); }

# A firewall rule whose [start,end] range covers THIS machine's public IPv4.
# Rules are read as scalars per rule (never a multiselect projection -> tsv).
ip_allowed() {
  local srv myip mi names name s e
  srv="$(srv_name)"; [[ -z "$srv" ]] && return 1
  myip="$(curl -s -4 --max-time 10 https://api.ipify.org 2>/dev/null)"
  [[ "$myip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  mi=$(ip2int "$myip")
  names="$(az sql server firewall-rule list -g "$RG" -s "$srv" --query "[].name" -o tsv 2>/dev/null)"
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    s="$(az sql server firewall-rule show -g "$RG" -s "$srv" -n "$name" --query startIpAddress -o tsv 2>/dev/null)"
    e="$(az sql server firewall-rule show -g "$RG" -s "$srv" -n "$name" --query endIpAddress -o tsv 2>/dev/null)"
    [[ "$s" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && "$e" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    if (( mi >= $(ip2int "$s") && mi <= $(ip2int "$e") )); then return 0; fi
  done <<< "$names"
  return 1
}

echo "======================================================"
echo " Validating Azure SQL Q2: Configure the Server Firewall"
echo "   Resource group: $RG"
echo "======================================================"

check "A SQL logical server exists in '$RG'"               srv_exists
check "A firewall rule allows your current public IP"      ip_allowed

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above (need internet to detect your IP), or read solution.md."
fi
exit $FAIL
