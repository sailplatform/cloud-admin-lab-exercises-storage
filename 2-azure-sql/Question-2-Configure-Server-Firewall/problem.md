# Question 2 — Configure the Server Firewall

## Scenario

The `appdb` database from Q1 is running, but nobody can connect to it: an Azure SQL
logical server **blocks every IP address by default**. A teammate needs to reach it
from their workstation. As the cloud administrator, open the server firewall for a
client IP — then prove a client can now connect.

`setup.bash` provisions the server and `appdb` for you (you set the password).

## Do it in three moves — *watch the connection change*

You need a SQL client. **Azure Cloud Shell has `sqlcmd` built in** (zero install);
on the Ubuntu jumpbox you can install it (see solution.md).

**1. See it blocked.** Try to connect — the gateway refuses you *by name*:

```bash
sqlcmd -S <server>.database.windows.net -U sqladmin -P '<your-password>' \
  -d appdb -Q "SELECT 'connected' AS status"
# -> ...Client with IP address 'x.x.x.x' is not allowed to access the server...
```

Note the IP it reports — that's the client you must allow.

**2. Open the firewall.** Add a rule for that IP.

**3. Confirm.** Run the exact same `sqlcmd` again — it now returns a row. Same
command, refused a minute ago, working now: that's the firewall doing its job.

## Requirements

The SQL server in `lab-storage-sql02-rg` must have:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A **firewall rule** allowing your client's public IP | start/end IP cover your current IP |

*Allow **your specific IP**, not `0.0.0.0–255.255.255.255` (that opens the server to
the whole internet). The validator checks that some rule covers the IP you're
running from.*

## Work the question

```bash
./setup.bash       # provisions server + appdb (you set the password)
# ... try sqlcmd (blocked) -> add rule -> sqlcmd (works) ...
./validate.bash
./cleanup.bash
```
