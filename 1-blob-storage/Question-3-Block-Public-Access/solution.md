# Solution — Lock Down the Storage Account

**Reference:** *Azure CLI reference → Storage → `az storage account` → `update`*:
<https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-update>
(or `az storage account update --help`). `update` changes settings on an existing
account — same flags as `create`.

## Move 1 — see the exposure

Get the blob's URL (setup printed it, but here's how to find it yourself), then
request it with no credentials:

```bash
ACCT=$(az storage account list -g lab-storage-blob03-rg --query "[0].name" -o tsv)

URL=$(az storage blob url --account-name "$ACCT" \
  --container-name public-data --name secret.txt --auth-mode key -o tsv)

curl -i "$URL"      # -> HTTP/1.1 200 OK, and the file contents. Anyone could read this.
```

The URL is just `https://<account>.blob.core.windows.net/<container>/<blob>` — a
plain public web address. That is why an exposed container is dangerous.

## Move 2 — harden the account

**What you're changing:**

- **`--allow-blob-public-access false`** — turns off *anonymous* read access for
  the whole account. This account-level switch overrides the container's own
  `public-access` setting, so it shuts the door even though the container is still
  marked `blob`. New accounts default to `false`; setup turned it on.
- **`--min-tls-version TLS1_3`** — run `az storage account update --help` for the
  allowed values (`TLS1_0, TLS1_1, TLS1_2, TLS1_3`); **TLS 1.3 is the current
  version**. The account **default is `TLS1_0`** (per the docs), which is *not*
  secure — so you set this one deliberately.

```bash
az storage account update -g lab-storage-blob03-rg -n "$ACCT" \
  --allow-blob-public-access false --min-tls-version TLS1_3
```

## Move 3 — confirm it's closed

```bash
curl -i "$URL"      # -> HTTP/1.1 403, <Error><Code>PublicAccessNotPermitted</Code>...
```

The same URL that served the file a minute ago now refuses it. (TLS is harder to
see with curl — modern curl already speaks 1.2/1.3 — so verify that one from the
control plane below.)

**Verify settings:** `az storage account show -g lab-storage-blob03-rg -n "$ACCT" --query "{public:allowBlobPublicAccess, tls:minimumTlsVersion}" -o table`

| Goal | Command |
|------|---------|
| Get a blob's public URL | `az storage blob url --account-name <acct> --container-name <c> --name <b> --auth-mode key -o tsv` |
| Test anonymous access | `curl -i "<url>"` (200 = exposed, 403 = blocked) |
| See update flags + allowed values | `az storage account update --help` |
| Block public blob access | `az storage account update -g <rg> -n <acct> --allow-blob-public-access false` |
| Enforce TLS 1.3 | `az storage account update -g <rg> -n <acct> --min-tls-version TLS1_3` |
| Check current settings | `az storage account show -g <rg> -n <acct> --query "{public:allowBlobPublicAccess, tls:minimumTlsVersion}" -o table` |
