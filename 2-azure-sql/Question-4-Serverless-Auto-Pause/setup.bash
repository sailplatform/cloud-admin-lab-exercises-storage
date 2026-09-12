#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Azure SQL Q4: Serverless with Auto-Pause
# ============================================================================
#  Provisions a SQL logical server + 'appdb' as a PROVISIONED General Purpose
#  database (compute always allocated & billed) so you can convert it to
#  Serverless. YOU type the admin password when prompted (this script runs the
#  create, so it needs a real value; it is never stored). Real, billable
#  resources — General Purpose costs more than Basic, so CLEAN UP when done.
#  Re-runnable: reuses an existing server/database.
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

echo "======================================================"
echo " Azure SQL Q4 — Serverless with Auto-Pause"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

# Azure SQL needs the Microsoft.Sql resource provider registered on the subscription
# (one-time). A fresh subscription usually isn't, which fails create with
# MissingSubscriptionRegistration.
SQL_RP="$(az provider show --namespace Microsoft.Sql --query registrationState -o tsv 2>/dev/null)"
if [[ "$SQL_RP" != "Registered" ]]; then
  echo "  Registering the Microsoft.Sql resource provider (one-time, ~1-2 min)..."
  az provider register --namespace Microsoft.Sql --wait \
    || { echo "  [X] Could not register Microsoft.Sql (need Contributor/Owner on the subscription)."; exit 1; }
  echo "  [OK] Microsoft.Sql registered."
else
  echo "  [OK] Microsoft.Sql resource provider already registered."
fi

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

SRV="$(az sql server list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
if [[ -n "$SRV" ]]; then
  echo "  [OK] SQL server '$SRV' already exists — reusing it."
else
  if [[ ! -t 0 ]]; then
    echo "  [X] Run this in an interactive terminal — it will prompt for a password."; exit 1
  fi
  read -r -s -p "  Set an admin password for the lab server (input hidden): " PW; echo
  [[ -z "$PW" ]] && { echo "  [X] No password entered."; exit 1; }
  SRV="labsql${RANDOM}${RANDOM}"
  echo "  Provisioning SQL server '$SRV' (login '${LAB_SQL_ADMIN}')... ~1-2 min."
  az sql server create -g "$RG" -n "$SRV" -u "$LAB_SQL_ADMIN" -p "$PW" --output none \
    || { echo "  [X] Server create failed (name taken globally? try again)."; exit 1; }
  unset PW
  # Provisioned GP Gen5 starts at 2 vCores (1 vCore is serverless-only), so create at 2.
  echo "  Creating 'appdb' as PROVISIONED General Purpose (Gen5, 2 vCore)... ~1 min."
  az sql db create -g "$RG" -s "$SRV" -n appdb \
    -e GeneralPurpose -f Gen5 -c 2 --output none
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   SQL server      : ${SRV}"
echo "   Database        : appdb  (Provisioned GP — compute always billed)"
echo ""
echo "  >> SEE THE STARTING STATE. Provisioned has NO auto-pause settings:"
echo "       az sql db show -g ${RG} -s ${SRV} -n appdb \\"
echo "         --query '{sku:currentServiceObjectiveName, autoPause:autoPauseDelay, minCap:minCapacity}' -o table"
echo "     -> sku GP_Gen5_2, autoPause and minCap are blank (null)."
echo ""
echo "  Your task: convert 'appdb' to the Serverless compute model with"
echo "  auto-pause after 60 minutes idle (min 0.5 vCore, max 1 vCore). Then"
echo "  re-run the command and watch the serverless settings appear."
echo "  Validate with:  ./validate.bash    Clean up promptly with: ./cleanup.bash"
echo "======================================================"
