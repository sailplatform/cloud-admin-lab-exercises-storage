# Question 3 — Scale the Database

## Scenario

`appdb` is on the **Basic** tier (5 DTU) and the app has outgrown it — queries are
throttling under load. Azure SQL lets you change a database's performance level
**online**, without recreating it. As the cloud administrator, scale `appdb` up to
the **Standard S0** performance level (10 DTU).

`setup.bash` provisions the server and a Basic `appdb` for you.

## First, two terms: DTU and service objective

- **DTU = Database Transaction Unit.** It's Azure's single, blended unit of database
  power — a bundle of **CPU + memory + I/O (reads/writes)** rolled into one number.
  You don't size those three separately; you just pick how many DTUs you want, and
  more DTUs means proportionally more of all three. (This is the "DTU purchasing
  model." Azure also has a "vCore" model where you choose CPU cores and memory
  directly — that's a later topic.)
- **Service objective** (a.k.a. *performance level*) is the named tier that sets the
  DTU count: `Basic` (5 DTU), `S0` (10 DTU), `S1` (20 DTU), and up. **Scaling a
  DTU database is just changing this one value.**

## Do it in three moves — *watch the level change*

**1. See the starting state** — Basic, 5 DTU:

```bash
az sql db show -g lab-storage-sql03-rg -s <server> -n appdb \
  --query "{tier:edition, objective:currentServiceObjectiveName, dtu:sku.capacity}" -o table
# tier   objective   dtu
# Basic  Basic       5
```

**2. Scale it** to S0.

**3. Confirm** — re-run the same command; it now reads Standard / S0 / 10. The
database stayed **Online** the whole time (no downtime, no data lost).

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | `appdb` performance level | `currentServiceObjectiveName = S0` (Standard edition) |

## Work the question

```bash
./setup.bash       # provisions server + Basic appdb (you set the password)
# ... see Basic/5 -> scale to S0 -> see Standard/S0/10 ...
./validate.bash
./cleanup.bash
```
