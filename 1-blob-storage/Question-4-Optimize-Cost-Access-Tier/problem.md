# Question 4 — Optimize Cost with the Access Tier

## Scenario

A storage account holds data that is **rarely read** — old reports kept only for
the occasional audit. It sits on the **Hot** tier, which charges a premium to keep
data instantly ready. For infrequently-accessed data, the **Cool** tier costs less
to store (in exchange for higher per-read charges and a 30-day minimum retention).
As the cloud administrator, move the account's default access tier to **Cool**.

`setup.bash` provisions the account on Hot and uploads a file whose tier is
*inferred* from the account default — so you can watch it follow the account.

## Do it in three moves — *observe* the tier change

**1. See the starting state.** After `./setup.bash`, check both the account and
the blob — both report **Hot**:

```bash
az storage account show -g lab-storage-blob04-rg -n <acct> --query accessTier -o tsv
az storage blob show --account-name <acct> --container-name data \
  --name report.csv --auth-mode key --query properties.blobTier -o tsv
```

**2. Change it.** Set the account default access tier to Cool.

**3. Confirm.** Re-run the two commands. Both now report **Cool** — the blob never
had its own tier, so it inherited the account's new default. That inheritance is
the lesson: set the account default once and existing untagged blobs follow.

## Requirements

The storage account in `lab-storage-blob04-rg` must have:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | Account default access tier | `accessTier = Cool` |

## Work the question

```bash
./setup.bash       # provisions the Hot account + blob, prints the check commands
# ... see Hot, switch to Cool, see Cool ...
./validate.bash
./cleanup.bash
```
