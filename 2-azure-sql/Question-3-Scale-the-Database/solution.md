# Solution — Scale the Database

**Reference:** *Azure CLI reference → SQL → `az sql db update`*:
<https://learn.microsoft.com/cli/azure/sql/db#az-sql-db-update>
(or `az sql db update --help`). `update` changes an existing database in place.

## Move 1 — see the current level

```bash
SRV=$(az sql server list -g lab-storage-sql03-rg --query "[0].name" -o tsv)

az sql db show -g lab-storage-sql03-rg -s "$SRV" -n appdb \
  --query "{tier:edition, objective:currentServiceObjectiveName, dtu:sku.capacity}" -o table
# Basic / Basic / 5
```

## Move 2 — scale to S0

The performance level is the **service objective**. `S0` is a standalone objective
name that implies Standard edition, so one flag does it:

```bash
az sql db update -g lab-storage-sql03-rg -s "$SRV" -n appdb --service-objective S0
```

(Equivalent, spelled out: `--edition Standard --capacity 10`. Run
`az sql db update --help` to see `--service-objective`, `--edition`, and
`--capacity`.)

## Move 3 — confirm

```bash
az sql db show -g lab-storage-sql03-rg -s "$SRV" -n appdb \
  --query "{tier:edition, objective:currentServiceObjectiveName, dtu:sku.capacity}" -o table
# Standard / S0 / 10
```

The edition, objective, and DTU count all moved up, and `status` stayed `Online`
throughout — scaling a DTU database is an online operation. To scale back down you'd
run the same command with `--service-objective Basic`.

| Goal | Command |
|------|---------|
| See current level | `az sql db show -g <rg> -s <server> -n appdb --query "{tier:edition, objective:currentServiceObjectiveName, dtu:sku.capacity}" -o table` |
| See update flags | `az sql db update --help` |
| Scale to S0 | `az sql db update -g <rg> -s <server> -n appdb --service-objective S0` |
| Scale back to Basic | `az sql db update -g <rg> -s <server> -n appdb --service-objective Basic` |
