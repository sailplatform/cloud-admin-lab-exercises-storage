# Question 2 — Configure the Server Firewall

## Scenario

The `appdb` database from Q1 is running, but nobody can connect to it: an Azure SQL
logical server **blocks every IP address by default**. A teammate needs to reach it
from their workstation. As the cloud administrator, open the server firewall for a
client IP — then prove a client can now connect.

`setup.bash` provisions the server and `appdb` for you (you set the password).
Prove it end-to-end with a SQL client (`sqlcmd`): try to connect *before* adding a
rule and the gateway refuses you by IP; add the rule; run the same command and it
returns a row. (Walkthrough — including where to get `sqlcmd` — in `solution.md`.)

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
