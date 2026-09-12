# Question 1 — Create a Logical Server and a Database

## Scenario

The team needs a managed SQL database in Azure for a small app. In Azure SQL, a
**database always lives inside a logical server** — the server is the connection
endpoint (`<name>.database.windows.net`) and holds the admin login; the database
holds your data. As the cloud administrator, create both, using the cheap
**Basic** tier.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A resource group | `lab-storage-sql01-rg`, in your lab region |
| 2 | A **SQL logical server** (globally-unique name) | admin login `sqladmin`; **you choose the password** |
| 3 | A **database** on the server | name `appdb`, tier **Basic** |

*Server names are globally unique (they become a public DNS name), all lowercase —
pick e.g. `labsql<initials><digits>`. The validator finds the server in your
resource group, so the exact name is your choice. **The admin password is a secret
only you set** — never put it in a script or share it.*

## Observe that it's real

A create question is "done" when the resource is actually **running**. After you
build it, confirm the database reports **Online** on the **Basic** tier:

```bash
az sql db show -g lab-storage-sql01-rg -s <server> -n appdb \
  --query "{name:name, tier:edition, status:status}" -o table
```

You'll notice you still can't *connect* a SQL client to it from your laptop — the
server firewall blocks all IPs by default. Opening that is **Question 2**.

## Work the question

```bash
./setup.bash       # preflight only — you build everything
# ... create the RG, server (your password), and appdb ...
./validate.bash
./cleanup.bash
```
