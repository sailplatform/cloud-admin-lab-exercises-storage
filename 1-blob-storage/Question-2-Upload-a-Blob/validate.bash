#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Blob Q2: Upload a File to Blob Storage. Read-only.
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

RG="$(lab_rg blob02)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

acct_name() { az storage account list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
acct_exists() { [[ -n "$(acct_name)" ]]; }
blob_hello_exists() {
  local a; a="$(acct_name)"; [[ -z "$a" ]] && return 1
  # `exists` prints True/true depending on CLI version — match either.
  [[ "$(az storage blob exists --account-name "$a" --container-name data --name hello.txt \
        --auth-mode key --query exists -o tsv 2>/dev/null)" == [tT]rue ]]
}

echo "======================================================"
echo " Validating Blob Q2: Upload a File"
echo "   Resource group: $RG"
echo "======================================================"

check "A storage account exists in '$RG'"        acct_exists
check "Blob 'hello.txt' exists in container 'data'" blob_hello_exists

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
