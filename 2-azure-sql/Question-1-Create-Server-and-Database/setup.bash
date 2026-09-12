#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Azure SQL Q1: Create a Logical Server and a Database
# ============================================================================
#  Preflight only. YOU create the resource group, the SQL logical server, and
#  the database — including choosing the server's admin PASSWORD, which only you
#  should ever know. This script does not create anything billable.
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

RG="$(lab_rg sql01)"

echo "======================================================"
echo " Azure SQL Q1 — Create a Logical Server and a Database"
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
echo ""
echo "  Nothing was provisioned — this question is yours to build."
echo "------------------------------------------------------"
echo "   Target resource group : ${RG}  (in ${LAB_LOCATION})"
echo "   Admin login name       : ${LAB_SQL_ADMIN}   (the password is YOURS to set)"
echo "   Database to create     : appdb   (Basic tier)"
echo ""
echo "  Build: a resource group, a globally-unique SQL logical server, and the"
echo "  'appdb' database on the Basic tier. See problem.md, then solution.md if"
echo "  you get stuck. Validate with:  ./validate.bash"
echo "======================================================"
