# Solution — Create a Logical Server and a Database

**Reference:** *Azure CLI reference → SQL*:
- server: <https://learn.microsoft.com/cli/azure/sql/server#az-sql-server-create>
- database: <https://learn.microsoft.com/cli/azure/sql/db#az-sql-db-create>

(or `az sql server create --help` / `az sql db create --help`).

## Two resources, in order

1. **Logical server** — the endpoint + admin identity. `-u` is the admin login;
   `-p` is its password. Azure requires a strong password (≥8 chars, 3 of: upper,
   lower, digit, symbol) — **you** choose it and replace the placeholder below.
   Don't save a real password into a file or commit it to a repo.

   ```bash
   az group create -n lab-storage-sql01-rg -l centralus

   az sql server create -g lab-storage-sql01-rg -n <unique-server> \
     -u sqladmin -p '<your-password>'
   ```

2. **Database** — created *inside* the server with `-s`. The tier is set with
   `-e/--edition`. Run `az sql db create --help`: the default edition is
   **General Purpose** (several vCores, pricey), so pass **Basic** deliberately —
   it's the cheapest tier (~2 GB, 5 DTU), perfect for a lab.

   ```bash
   az sql db create -g lab-storage-sql01-rg -s <unique-server> -n appdb -e Basic
   ```

## Confirm it's running

```bash
az sql db show -g lab-storage-sql01-rg -s <unique-server> -n appdb \
  --query "{name:name, tier:edition, status:status}" -o table
# name   tier    status
# appdb  Basic   Online
```

The database is live — but a SQL client on your laptop still can't reach it until
you open the server firewall (Question 2).

| Goal | Command |
|------|---------|
| See server flags | `az sql server create --help` |
| See db tiers/defaults | `az sql db create --help` |
| Create server | `az sql server create -g <rg> -n <server> -u sqladmin -p '<your-password>'` |
| Create Basic database | `az sql db create -g <rg> -s <server> -n appdb -e Basic` |
| List databases on a server | `az sql db list -g <rg> -s <server> -o table` |
| Check one database | `az sql db show -g <rg> -s <server> -n appdb --query "{tier:edition, status:status}" -o table` |
