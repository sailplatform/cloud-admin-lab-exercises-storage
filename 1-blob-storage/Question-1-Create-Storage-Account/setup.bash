#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Blob Q1: Create a Storage Account and Container
# ============================================================================
#  Creating the storage account + container is the exercise, so setup only
#  preflights your environment and prints the target.
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

echo "======================================================"
echo " Blob Storage Q1 — Create a Storage Account and Container"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "------------------------------------------------------"
echo " Your target:"
echo "   Resource group : ${RG}"
echo "   Region         : ${LAB_LOCATION}"
echo "   Storage account: a globally-unique name, kind StorageV2, SKU Standard_LRS"
echo "   Blob container : data"
echo " Validate with:  ./validate.bash"
echo "======================================================"
