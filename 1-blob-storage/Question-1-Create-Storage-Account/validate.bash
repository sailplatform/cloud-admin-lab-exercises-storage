#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Blob Q1: Create a Storage Account and Container
# ============================================================================
#  Read-only PASS/FAIL checks. Exit code = number of failed checks.
#  Finds THE storage account in this question's resource group, so your chosen
#  (globally-unique) account name doesn't matter.
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

RG="$(lab_rg blob01)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# --- discovery + helpers ----------------------------------------------------
acct_name()  { az storage account list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
acct_field() {  # $1 = jmespath field on the storage account
  local a; a="$(acct_name)"; [[ -z "$a" ]] && return 1
  az storage account show -g "$RG" -n "$a" --query "$1" -o tsv 2>/dev/null
}
acct_exists()      { [[ -n "$(acct_name)" ]]; }
kind_is_v2()       { [[ "$(acct_field kind)" == "StorageV2" ]]; }
sku_is_lrs()       { [[ "$(acct_field sku.name)" == "Standard_LRS" ]]; }
container_data()  {
  local a; a="$(acct_name)"; [[ -z "$a" ]] && return 1
  # `exists` prints True/true depending on CLI version — match either.
  [[ "$(az storage container exists --account-name "$a" --name data --auth-mode key \
        --query exists -o tsv 2>/dev/null)" == [tT]rue ]]
}

echo "======================================================"
echo " Validating Blob Q1: Storage Account + Container"
echo "   Resource group: $RG"
echo "======================================================"

check "Resource group '$RG' exists" \
  bash -c '[[ "$(az group exists --name "'"$RG"'")" == "true" ]]'
check "A storage account exists in the resource group" acct_exists
check "Storage account kind is StorageV2"               kind_is_v2
check "Storage account SKU is Standard_LRS"             sku_is_lrs
check "Blob container 'data' exists"                    container_data

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
