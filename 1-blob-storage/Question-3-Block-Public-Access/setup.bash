#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Blob Q3: Lock Down the Storage Account
# ============================================================================
#  Provisions a DELIBERATELY EXPOSED account so you can SEE the problem before
#  you fix it: public blob access is ON, and a container is set to anonymous
#  ('blob') access with a real file uploaded into it. After setup, you can open
#  the printed URL in a browser (or curl it) and read the file with no
#  credentials — that's the exposure you'll close.
#
#  Real, billable resources. Re-runnable: reuses an existing account/container.
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
CONTAINER="public-data"
BLOB="secret.txt"

echo "======================================================"
echo " Blob Storage Q3 — Lock Down the Storage Account"
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
  echo "  Provisioning EXPOSED storage account '$ACCT' (public blob access on)... ~20s."
  az storage account create -g "$RG" -n "$ACCT" --sku Standard_LRS \
    --allow-blob-public-access true --output none
fi

echo "  Creating an anonymously-readable container '$CONTAINER' and uploading '$BLOB'..."
az storage container create --account-name "$ACCT" --name "$CONTAINER" \
  --public-access blob --auth-mode key --output none
echo "CONFIDENTIAL - quarterly numbers that should NOT be public." > "$BLOB"
az storage blob upload --account-name "$ACCT" --container-name "$CONTAINER" \
  --name "$BLOB" --file "$BLOB" --auth-mode key --overwrite --output none

URL="$(az storage blob url --account-name "$ACCT" --container-name "$CONTAINER" \
  --name "$BLOB" --auth-mode key -o tsv 2>/dev/null)"

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Storage account: ${ACCT}"
echo "   Exposed blob   : ${URL}"
echo ""
echo "  >> SEE THE PROBLEM FIRST. Open that URL in a browser, or run:"
echo "         curl -i \"${URL}\""
echo "     You'll get HTTP 200 and the file contents — no login needed."
echo ""
echo "  Your task: block anonymous access (allowBlobPublicAccess=false)."
echo "  Then curl the URL again -> expect 403."
echo "  Validate with:  ./validate.bash"
echo "======================================================"
