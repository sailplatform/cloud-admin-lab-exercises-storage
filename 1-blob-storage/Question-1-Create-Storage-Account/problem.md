# Question 1 — Create a Storage Account and Container

## Scenario

The team needs a place in Azure to store files — documents, backups, exports. As
the cloud administrator, create a **storage account** and a **blob container** to
hold them.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A resource group | `lab-storage-blob01-rg`, in your lab region |
| 2 | A **storage account** (globally-unique name) | kind `StorageV2`, SKU `Standard_LRS` |
| 3 | A **blob container** | named `data` |

> Storage-account names are **globally unique** and must be all lowercase letters
> and numbers (3–24 chars) — pick something like `labstore<yourinitials><digits>`.
> The validator finds the account in your resource group, so the exact name is
> your choice.

## Work the question

```bash
./setup.bash      # checks your environment and prints the target
# ... create the resources yourself (see solution.md if you get stuck) ...
./validate.bash   # PASS/FAIL check
./cleanup.bash    # delete everything when you're done
```
