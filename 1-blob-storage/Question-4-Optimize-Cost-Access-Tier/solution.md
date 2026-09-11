# Solution — Optimize Cost with the Access Tier

**Reference:** *Azure CLI reference → Storage → `az storage account` → `update`*:
<https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-update>
(or `az storage account update --help`). Look at **`--access-tier`** — allowed
values `Cold, Cool, Hot, Premium`.

## What the access tier is

The **access tier** decides how you're billed for blob storage — it's a
cost/performance trade-off, not a capability switch:

- **Hot** — highest storage cost, lowest access cost. For data read often.
- **Cool** — lower storage cost, higher access cost, 30-day minimum retention. For
  data read rarely (backups, old reports).
- **Cold**/**Premium** exist too; Cool is the usual "save money on cold-ish data" pick.

The account has a **default** tier. A blob can carry its own explicit tier, but a
blob uploaded without one has an *inferred* tier that simply follows the account
default — which is why switching the account moves that blob too.

## Move 1 — see the starting state (Hot)

```bash
ACCT=$(az storage account list -g lab-storage-blob04-rg --query "[0].name" -o tsv)

az storage account show -g lab-storage-blob04-rg -n "$ACCT" --query accessTier -o tsv
az storage blob show --account-name "$ACCT" --container-name data \
  --name report.csv --auth-mode key --query properties.blobTier -o tsv
# both print: Hot
```

## Move 2 — switch the account default to Cool

```bash
az storage account update -g lab-storage-blob04-rg -n "$ACCT" --access-tier Cool
```

## Move 3 — confirm (Cool)

```bash
az storage account show -g lab-storage-blob04-rg -n "$ACCT" --query accessTier -o tsv
az storage blob show --account-name "$ACCT" --container-name data \
  --name report.csv --auth-mode key --query properties.blobTier -o tsv
# both now print: Cool
```

Billing changes aren't instantly visible on your invoice, but the tier that
*drives* the bill is — and you watched the untagged blob inherit it.

| Goal | Command |
|------|---------|
| See account default tier | `az storage account show -g <rg> -n <acct> --query accessTier -o tsv` |
| See a blob's effective tier | `az storage blob show --account-name <acct> --container-name <c> --name <b> --auth-mode key --query properties.blobTier -o tsv` |
| See allowed tier values | `az storage account update --help` |
| Set account default to Cool | `az storage account update -g <rg> -n <acct> --access-tier Cool` |
| Set a *single blob's* tier | `az storage blob set-tier --account-name <acct> --container-name <c> --name <b> --tier Cool --auth-mode key` |
