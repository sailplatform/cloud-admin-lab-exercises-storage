# Question 4 — Optimize Cost with the Access Tier

## Scenario

A storage account holds data that is **rarely read** — old reports kept only for
the occasional audit. It sits on the **Hot** tier, which charges a premium to keep
data instantly ready. For infrequently-accessed data, the **Cool** tier costs less
to store (in exchange for higher per-read charges and a 30-day minimum retention).
As the cloud administrator, move the account's default access tier to **Cool**.

`setup.bash` provisions the account on Hot and uploads a file whose tier is
*inferred* from the account default. Check the account and the blob before and
after your change: because the blob has no tier of its own, it follows the
account default — set the account to Cool and watch the blob move with it.
(Walkthrough in `solution.md`.)

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
