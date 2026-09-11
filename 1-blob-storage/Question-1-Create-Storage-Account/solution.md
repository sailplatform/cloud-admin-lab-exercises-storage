# Solution — Create a Storage Account and Container

**Start at the reference.** Every `az` command is documented — for this one it's
*Azure CLI reference → Storage → `az storage account` → `create`*:
<https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-create>.
Read it (or run `az storage account create --help`): it explains every parameter,
lists the **allowed values**, and — importantly — shows each flag's **default**.
A flag you don't pass takes its default, so only pass one when you want something
*other* than the default.

**What you're actually choosing:**

- **`--kind` (account kind)** — its default is already `StorageV2`, the modern
  general-purpose kind (blobs, files, queues, tables + access tiering). So you
  **don't pass `--kind` at all** — a plain create already gives you StorageV2.
  (The docs list the alternatives you *would* name explicitly: `BlobStorage`,
  `FileStorage`, `BlockBlobStorage`, `StorageV1`.)
- **`--sku` (redundancy)** — how many copies Azure keeps, and where. Here the
  default is `Standard_RAGRS` (geo-redundant across two regions, ~2× the cost),
  so we override it: `--sku Standard_LRS` = **L**ocally **R**edundant **S**torage,
  3 copies in one datacenter, the cheapest — plenty for a lab. That's the rule:
  keep defaults, override *deliberately*.

A **storage account** is the top-level container for all of Azure Storage; its
name is a global DNS label (unique, all-lowercase). Your files (**blobs**) live
inside **containers**.

```bash
az group create -n lab-storage-blob01-rg -l centralus

az storage account create -g lab-storage-blob01-rg -n <unique-name> --sku Standard_LRS

az storage container create --account-name <unique-name> --name data --auth-mode key
```

**Auth note:** container/blob commands use `--auth-mode key` (the account key,
which an Owner/Contributor can fetch automatically). `--auth-mode login` uses your
Entra identity instead — but that needs the *Storage Blob Data Contributor* role;
being subscription Owner isn't enough for data-plane access.

**Verify:** `az storage container exists --account-name <unique-name> --name data --auth-mode key`

| Goal | Command |
|------|---------|
| See flags, allowed values, defaults | `az storage account create --help` |
| Create account (LRS; kind defaults to StorageV2) | `az storage account create -g <rg> -n <acct> --sku Standard_LRS` |
| List accounts in an RG | `az storage account list -g <rg> -o table` |
| Create container | `az storage container create --account-name <acct> -n <name> --auth-mode key` |
