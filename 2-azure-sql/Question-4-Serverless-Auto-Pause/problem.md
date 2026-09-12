# Question 4 — Serverless with Auto-Pause

## Scenario

`appdb` is a **provisioned** General Purpose database: its compute is allocated
around the clock, so you pay for it 24/7 even when no one is querying — like
leaving a VM running idle. For a database used only occasionally (a dev/test DB, an
internal tool), the **Serverless** compute model is cheaper: it bills compute
per-second, **auto-pauses** after an idle period (compute billing drops to zero,
you keep paying only for storage), and **auto-resumes** on the next connection.

As the cloud administrator, convert `appdb` to Serverless with a 60-minute
auto-pause delay. This is the database analogue of *deallocating* an idle VM.

## Do it in three moves — *watch the settings appear*

**1. See the starting state.** A provisioned database has no auto-pause settings:

```bash
az sql db show -g lab-storage-sql04-rg -s <server> -n appdb \
  --query "{sku:currentServiceObjectiveName, autoPause:autoPauseDelay, minCap:minCapacity}" -o table
# sku          autoPause    minCap
# GP_Gen5_1                            <- autoPause / minCap are blank (null)
```

**2. Convert it** to Serverless with auto-pause.

**3. Confirm.** Re-run the same command. The SKU gains an `_S_` (serverless) and the
two auto-pause fields now have values:

```
# sku            autoPause    minCap
# GP_S_Gen5_1    60           0.5
```

Those settings appearing where there were none is the change you can see now.
The **pause itself** happens only after 60 minutes with no connections (that's the
minimum Azure allows) — so you won't watch it flip during the lab, but from now on
`az sql db show --query status` will report `Paused` after an idle hour, and your
next query resumes it in a few seconds.

## Requirements

The `appdb` database in `lab-storage-sql04-rg` must be:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | Compute model | **Serverless** (SKU like `GP_S_Gen5_1`) |
| 2 | Auto-pause delay | `autoPauseDelay = 60` minutes |

## Work the question

```bash
./setup.bash       # provisions server + provisioned appdb (you set the password)
# ... see no auto-pause -> convert to serverless -> see auto-pause settings ...
./validate.bash
./cleanup.bash     # do this promptly — General Purpose isn't free
```
