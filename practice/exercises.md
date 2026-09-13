# Practice Exercises — Storage and Databases

These are practice problems: **questions only** — no `setup.bash`, no
`validate.bash`, no `solution.md`. The graded questions walked you through the core
skills; these are the reps that turn understanding into muscle memory.

Work them the same way a cloud admin works any ticket:

1. **Read the scenario into a checklist** of concrete constraints.
2. **Find the reference** — guess `az <group> <verb>`, confirm in the docs.
3. **Tame the flags with `--help`** — required first, then match the rest to your checklist.
4. **Build the command incrementally**, then **verify with your own eyes.**

Some questions deliberately don't hand you the exact flag or value. Finding it in
the docs is part of the exercise.

## How to check your own work (no validator here)

You are the validator now. The commands that tell you the truth:

```bash
# --- Blob storage ---
az storage account show -g <rg> -n <acct> -o jsonc                 # full definition
az storage account show -g <rg> -n <acct> --query <jmespath> -o tsv
az storage blob list --account-name <acct> -c <container> --auth-mode key -o table
az storage blob show --account-name <acct> -c <container> -n <blob> --auth-mode key -o jsonc
curl -i "<blob-or-sas-url>"                                        # anonymous / SAS access

# --- Azure SQL ---
az sql db list -g <rg> -s <server> -o table                       # all databases on a server
az sql db show -g <rg> -s <server> -n <db> --query <jmespath> -o tsv
az sql server firewall-rule list -g <rg> -s <server> -o table
sqlcmd -S <server>.database.windows.net -U <login> -P '<pw>' -d <db> -Q "SELECT ..."
```

## Ground rules

- Use your **own resource groups** — a good convention is `practice-blobNN-rg` and
  `practice-sqlNN-rg` so they're easy to find and delete. One group per exercise.
- These create **real, billable resources.** Clean up the moment you finish each:
  ```bash
  az group delete --name <your-rg> --yes --no-wait
  ```
- **Storage account** and **SQL server** names are globally unique and lowercase.
- For the SQL exercises: your subscription needs the `Microsoft.Sql` provider
  registered (`az provider register --namespace Microsoft.Sql --wait`), a firewall
  rule for your client IP, and `sqlcmd` (preinstalled in Azure Cloud Shell).

---

# Part A — Blob Storage

## Exercise 1 — Pick your redundancy

Finance wants durable backups that survive a whole datacenter going down, not just
a disk failure.

**Done when:**
- A storage account exists on a **zone-redundant** SKU (find the right
  `--sku` value; it is not the default).
- It holds a container named `backups`.
- Confirm the SKU with `az storage account show --query sku.name`.

## Exercise 2 — Upload a web page as a blob

You are handed `index.html` and asked to store it so that, if served, a browser
would render it as a page rather than download it as text.

**Done when:**
- A container `site` holds a blob `index.html`.
- The blob's **content type** is `text/html` (not the default
  `application/octet-stream`). Set it at upload time.
- The blob carries **metadata** `owner=<your-name>`.
- Verify both with `az storage blob show ... --query "{type:properties.contentSettings.contentType, meta:metadata}"`.

## Exercise 3 — Hand out time-limited access with a SAS

A partner needs to read one file for the next hour without getting a login on your
account. A **Shared Access Signature (SAS)** is the tool: a signed, expiring URL.

**Done when:**
- You generate a **read-only** SAS for a single blob that expires in about 1 hour.
- `curl -i "<blob-url>?<sas>"` returns **HTTP 200** and the content.
- `curl -i "<blob-url>"` (no SAS) is refused, proving the file is not public.
- (Look at `az storage blob generate-sas`; note the `--permissions` and
  `--expiry` flags, and that you build the full URL as `<blob-url>?<sas>`.)

## Exercise 4 — Turn on soft delete and recover a blob

Someone will eventually delete the wrong blob. **Soft delete** keeps deleted blobs
recoverable for a retention window.

**Done when:**
- Blob **soft delete** is enabled on the account with a retention of 7 days.
- You upload a blob, delete it, and confirm it is gone from a normal listing.
- You **restore** it and confirm it is back.
- (Explore `az storage account blob-service-properties delete-policy` to enable it,
  then `az storage blob delete`, `list --include d`, and `az storage blob undelete`.)

## Exercise 5 — Automate tiering with a lifecycle policy

Manually re-tiering blobs does not scale. A **lifecycle management policy** does it
on a schedule.

**Done when:**
- The account has a lifecycle policy that **moves blobs to Cool after 30 days**
  since last modification and **deletes them after 365 days**.
- Confirm with `az storage account management-policy show`.
- (The policy is JSON. Read `az storage account management-policy create --help`
  and the docs for the rule shape: filters plus `tierToCool` and `delete` actions.)

---

# Part B — Azure SQL Database

## Exercise 6 — Add a second database at a different tier

The reporting team wants its own database, sized larger than `appdb`, on the same
server.

**Done when:**
- A second database `reporting` exists on your server.
- It is on the **Standard S1** performance level (20 DTU).
- Confirm with `az sql db list -g <rg> -s <server> -o table` and
  `az sql db show ... --query "{tier:edition, objective:currentServiceObjectiveName}"`.

## Exercise 7 — Create a table and put real data in it

So far you have managed the database from the outside. Now work *inside* it with
`sqlcmd`.

**Done when:**
- Connected to a database with `sqlcmd`, you create a table (for example
  `customers(id INT, name NVARCHAR(50))`).
- You insert at least three rows.
- `SELECT COUNT(*) FROM customers;` returns your row count.
- (This is pure T-SQL over the connection you opened in the firewall question. Use
  `-Q "<sql>"` for one-shot statements, or run `sqlcmd` interactively.)

## Exercise 8 — Let Azure services in, and an office range

Your app runs on other Azure resources and must reach the database, and the office
network (a CIDR range) should also connect.

**Done when:**
- A firewall rule allows **Azure services** to connect (the special
  `0.0.0.0`-`0.0.0.0` rule; find out why that value means "Azure services").
- A separate named rule allows an **IP range** you choose (for example
  `203.0.113.0` to `203.0.113.255`).
- Confirm with `az sql server firewall-rule list -g <rg> -s <server> -o table`.

## Exercise 9 — Recover with point-in-time restore

A bad `UPDATE` just corrupted data. Azure SQL keeps continuous backups, so you can
restore the database to how it looked minutes ago, into a **new** database.

**Done when:**
- You restore your database to a new database named `appdb-restored`, as of a few
  minutes ago.
- The new database shows up in `az sql db list` and reports status **Online**.
- (See `az sql db restore`; note `--dest-name` and `--time` in ISO 8601. The
  earliest restore point is a few minutes after the source database was created.)

## Exercise 10 — Capstone: export the database to Blob Storage

Combine both halves of this lab. Export a database to a portable `.bacpac` file
and land it in a blob container: exactly how an admin takes a movable backup.

**Done when:**
- A storage account and a container (for example `exports`) exist.
- You export a database to `<container>/appdb.bacpac` in that account.
- The `.bacpac` blob appears in `az storage blob list`.
- (Look at `az sql db export`; it needs the server admin login and password, plus
  a storage **account key or SAS** and the target blob URL. The export runs
  server-side and can take a few minutes. This is a stretch: read the help
  carefully and build the command one flag at a time.)
