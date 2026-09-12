#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Azure SQL Q2: Configure the Server Firewall
# ============================================================================
#  Provisions a SQL logical server + 'appdb' (Basic) so you have something to
#  connect to. YOU type the admin password when prompted — it is never stored in
#  a file and this script never sees it written down. Real, billable resources.
#  Re-runnable: if the server already exists it is reused (keep your password).
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

echo "======================================================"
echo " Azure SQL Q2 — Configure the Server Firewall"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

SRV="$(az sql server list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
if [[ -n "$SRV" ]]; then
  echo "  [OK] SQL server '$SRV' already exists — reusing it (use the password you set)."
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
  echo "  Creating database 'appdb' (Basic tier)..."
  az sql db create -g "$RG" -s "$SRV" -n appdb -e Basic --output none
fi

FQDN="$(az sql server show -g "$RG" -n "$SRV" --query fullyQualifiedDomainName -o tsv 2>/dev/null)"

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   SQL server      : ${SRV}"
echo "   Server endpoint : ${FQDN}"
echo "   Admin login     : ${LAB_SQL_ADMIN}   (password: the one you just set)"
echo ""
echo "  >> SEE THE PROBLEM FIRST. Try to connect (needs sqlcmd — Azure Cloud"
echo "     Shell has it built in). It will be REFUSED because no firewall rule"
echo "     allows your IP:"
echo "        sqlcmd -S ${FQDN} -U ${LAB_SQL_ADMIN} -P '<your-password>' -d appdb -Q 'SELECT 1'"
echo "     -> 'Cannot open server ... Client with IP address <yours> is not allowed.'"
echo ""
echo "  Your task: add a server firewall rule for your client IP, then connect"
echo "  again and watch it succeed. Validate with:  ./validate.bash"
echo "======================================================"
