#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Blob Q3: Lock Down the Storage Account. Read-only.
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

RG="$(lab_rg blob03)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

acct_name()  { az storage account list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
acct_field() {
  local a; a="$(acct_name)"; [[ -z "$a" ]] && return 1
  az storage account show -g "$RG" -n "$a" --query "$1" -o tsv 2>/dev/null
}
acct_exists()       { [[ -n "$(acct_name)" ]]; }
# `-o tsv` may print False/false by CLI version — match either (portable to bash 3.2).
public_disabled() { [[ "$(acct_field allowBlobPublicAccess)" == [Ff]alse ]]; }
tls_is_13()       { [[ "$(acct_field minimumTlsVersion)" == "TLS1_3" ]]; }

# The real proof: an anonymous (no-auth) GET of the exposed blob must be refused.
# primaryEndpoints.blob is like https://<acct>.blob.core.windows.net/  (trailing /).
blob_blocked() {
  local base url code
  base="$(acct_field primaryEndpoints.blob)" || return 1
  [[ -z "$base" ]] && return 1
  url="${base}public-data/secret.txt"
  code="$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)"
  [[ "$code" == "403" ]]
}

echo "======================================================"
echo " Validating Blob Q3: Lock Down the Storage Account"
echo "   Resource group: $RG"
echo "======================================================"

check "A storage account exists in '$RG'"               acct_exists
check "Public blob access is disabled (false)"          public_disabled
check "Anonymous GET of the blob is refused (HTTP 403)" blob_blocked
check "Minimum TLS version is TLS1_3"                   tls_is_13

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
