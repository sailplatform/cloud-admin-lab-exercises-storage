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

`setup.bash` provisions `appdb` as a provisioned database. Check its settings
before and after: a provisioned database has no auto-pause fields, and after you
convert it the SKU gains an `_S_` (serverless) and the auto-pause settings appear.
The pause *itself* happens only after 60 minutes idle (Azure's minimum), so you
won't watch it flip during the lab — but from then on `az sql db show --query
status` reports `Paused` after an idle hour, and the next query resumes it in
seconds. (Walkthrough in `solution.md`.)

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
