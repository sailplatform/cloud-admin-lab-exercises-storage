# Solution — Upload a File to Blob Storage

**Reference:** *Azure CLI reference → Storage → `az storage blob` → `upload`*:
<https://learn.microsoft.com/cli/azure/storage/blob#az-storage-blob-upload>
(or `az storage blob upload --help`).

A **blob** is just a file stored inside a container. `az storage blob upload`
copies a **local file** (`--file`) into a container (`--container-name`) under a
blob name (`--name`). So you need a file on disk first, then the account name
(setup generated it — look it up rather than guessing).

```bash
# 1) Make a file to upload (any file works)
echo "Hello, Azure Storage" > hello.txt

# 2) Find the account setup created
ACCT=$(az storage account list -g lab-storage-blob02-rg --query "[0].name" -o tsv)

# 3) Upload it as a blob named hello.txt
az storage blob upload --account-name "$ACCT" --container-name data \
  --name hello.txt --file hello.txt --auth-mode key
```

**Verify:** `az storage blob list --account-name "$ACCT" --container-name data --auth-mode key -o table`

| Goal | Command |
|------|---------|
| See upload flags | `az storage blob upload --help` |
| Upload a blob | `az storage blob upload --account-name <acct> --container-name <c> --name <blob> --file <local> --auth-mode key` |
| List blobs | `az storage blob list --account-name <acct> --container-name <c> --auth-mode key -o table` |
| Download a blob | `az storage blob download --account-name <acct> --container-name <c> --name <blob> --file <local> --auth-mode key` |
