# Solution — Serverless with Auto-Pause

**Reference:** *Azure CLI reference → SQL → `az sql db update`*:
<https://learn.microsoft.com/cli/azure/sql/db#az-sql-db-update>
(or `az sql db update --help`). The serverless flags are `--compute-model`,
`--auto-pause-delay`, and `--min-capacity`.

## What "serverless" changes

Serverless is a **compute model** of the vCore General Purpose tier, not a separate
edition. Instead of a fixed vCore count billed 24/7, you set a **range** —
`--min-capacity` (floor while active) up to `--capacity` (ceiling) — and Azure
scales compute within it and **auto-pauses** after `--auto-pause-delay` idle
minutes. Paused = you pay only for storage.

## Move 1 — see the starting state

```bash
SRV=$(az sql server list -g lab-storage-sql04-rg --query "[0].name" -o tsv)

az sql db show -g lab-storage-sql04-rg -s "$SRV" -n appdb \
  --query "{sku:currentServiceObjectiveName, autoPause:autoPauseDelay, minCap:minCapacity}" -o table
# GP_Gen5_1 / (blank) / (blank)
```

## Move 2 — convert to serverless

Keep General Purpose, switch the compute model, and set the auto-pause window. The
minimum delay Azure allows is **60** minutes (use `-1` to disable auto-pause):

```bash
az sql db update -g lab-storage-sql04-rg -s "$SRV" -n appdb \
  --compute-model Serverless -e GeneralPurpose -f Gen5 \
  --capacity 1 --min-capacity 0.5 --auto-pause-delay 60
```

## Move 3 — confirm

```bash
az sql db show -g lab-storage-sql04-rg -s "$SRV" -n appdb \
  --query "{sku:currentServiceObjectiveName, autoPause:autoPauseDelay, minCap:minCapacity}" -o table
# GP_S_Gen5_1 / 60 / 0.5
```

The `_S_` in the SKU marks serverless, and the auto-pause fields now hold values.
After 60 idle minutes `az sql db show --query status -o tsv` will read `Paused`
(compute billing stops); the next connection auto-resumes it in seconds. To go back
to always-on, run the update with `--compute-model Provisioned`.

| Goal | Command |
|------|---------|
| See compute model + auto-pause | `az sql db show -g <rg> -s <server> -n appdb --query "{sku:currentServiceObjectiveName, autoPause:autoPauseDelay, minCap:minCapacity}" -o table` |
| See serverless flags | `az sql db update --help` |
| Convert to serverless | `az sql db update -g <rg> -s <server> -n appdb --compute-model Serverless -e GeneralPurpose -f Gen5 --capacity 1 --min-capacity 0.5 --auto-pause-delay 60` |
| Check paused/online status | `az sql db show -g <rg> -s <server> -n appdb --query status -o tsv` |
| Back to always-on | `az sql db update -g <rg> -s <server> -n appdb --compute-model Provisioned` |
