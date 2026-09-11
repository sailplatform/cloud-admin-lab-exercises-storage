#!/usr/bin/env bash
# ============================================================================
#  lab-config.sh — shared configuration for the Storage lab
# ============================================================================
#  Every setup.bash / validate.bash / cleanup.bash sources this one file, so
#  all the scripts for a question agree on WHERE your resources live and WHAT
#  they are named.
#
#  This is YOUR file to edit. The most common change is the region. Azure
#  capacity/quotas vary by region: if a create fails, switch LAB_LOCATION to
#  another region and re-run. Reliable alternates:
#      westus2, westus3, eastus2, southcentralus, westeurope, northeurope
#  The scripts only care that setup, your solution, validate, and cleanup all
#  agree on the region — which is why the value lives here, in one place.
#
#  Override any value for a single run without editing the file:
#      LAB_LOCATION=westus3 ./validate.bash
# ============================================================================

# Azure region where all lab resources are created.
export LAB_LOCATION="${LAB_LOCATION:-centralus}"

# Prefix applied to every resource group this lab creates. Keeps lab resources
# easy to spot in the portal and easy to delete when you're done.
export LAB_RG_PREFIX="${LAB_RG_PREFIX:-lab-storage}"

# Admin LOGIN name for the Azure SQL questions (NOT a password — you set the
# password yourself when you create the server, and it is never stored here).
export LAB_SQL_ADMIN="${LAB_SQL_ADMIN:-sqladmin}"

# Build the resource-group name for a question from its short slug.
#   lab_rg blob01   ->   lab-storage-blob01-rg
lab_rg() {
  echo "${LAB_RG_PREFIX}-$1-rg"
}
