#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Blob Q2: Upload a File to Blob Storage
# ============================================================================
#  Uploading is the exercise, so setup PROVISIONS a storage account (with a
#  generated unique name) + a `data` container for you. Real, billable resources.
#  Re-runnable: it reuses an existing account in the resource group.
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

echo "======================================================"
echo " Blob Storage Q2 — Upload a File"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

ACCT="$(az storage account list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
if [[ -n "$ACCT" ]]; then
  echo "  [OK] Storage account '$ACCT' already exists — reusing it."
else
  ACCT="labstore${RANDOM}${RANDOM}"
  echo "  Provisioning storage account '$ACCT' (Standard_LRS)... ~20s."
  az storage account create -g "$RG" -n "$ACCT" --sku Standard_LRS --output none
  echo "  Creating container 'data'..."
  az storage container create --account-name "$ACCT" --name data --auth-mode key --output none
  echo "  [OK] Storage account + 'data' container ready."
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Storage account: ${ACCT}"
echo "   Container      : data"
echo " Your task: upload a file named 'hello.txt' into the 'data' container."
echo " Validate with:  ./validate.bash"
echo "======================================================"
