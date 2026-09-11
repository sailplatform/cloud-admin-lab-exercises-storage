#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Blob Q4: Optimize Cost with the Access Tier
# ============================================================================
#  Provisions a StorageV2 account on the HOT tier and uploads a blob WITHOUT an
#  explicit tier, so the blob's tier is "inferred" from the account default.
#  That lets you watch the blob's tier follow the account when you switch it to
#  Cool. Real, billable resources. Re-runnable: reuses an existing account.
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

RG="$(lab_rg blob04)"
CONTAINER="data"
BLOB="report.csv"

echo "======================================================"
echo " Blob Storage Q4 — Optimize Cost with the Access Tier"
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
  echo "  Provisioning storage account '$ACCT' on the HOT tier... ~20s."
  az storage account create -g "$RG" -n "$ACCT" --sku Standard_LRS \
    --access-tier Hot --output none
fi

echo "  Creating container '$CONTAINER' and uploading '$BLOB' (no explicit tier)..."
az storage container create --account-name "$ACCT" --name "$CONTAINER" \
  --auth-mode key --output none
printf 'quarter,revenue\nQ1,100\nQ2,120\n' > "$BLOB"
az storage blob upload --account-name "$ACCT" --container-name "$CONTAINER" \
  --name "$BLOB" --file "$BLOB" --auth-mode key --overwrite --output none

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Storage account: ${ACCT}"
echo "   Blob           : ${CONTAINER}/${BLOB}"
echo ""
echo "  >> SEE THE STARTING STATE. The account and the blob are both 'Hot':"
echo "       az storage account show -g ${RG} -n ${ACCT} --query accessTier -o tsv"
echo "       az storage blob show --account-name ${ACCT} --container-name ${CONTAINER} \\"
echo "         --name ${BLOB} --auth-mode key --query properties.blobTier -o tsv"
echo ""
echo "  Your task: this data is accessed rarely — move the account default"
echo "  access tier to Cool to cut storage cost. Then re-run the two commands"
echo "  above and watch both flip to 'Cool'."
echo "  Validate with:  ./validate.bash"
echo "======================================================"
