# Question 3 — Lock Down the Storage Account

## Scenario

A security review flagged a storage account: a container is set to **anonymous
public access**, so anyone with the blob's URL can read it — no credentials
required. The account also still **accepts old TLS versions**. As the cloud
administrator, prove the exposure, then harden the account.

`setup.bash` provisions the account in this insecure state and uploads a file
(`secret.txt`) into a public container so there is something real to test. Before
you harden anything, `curl` the blob URL it prints and watch it return the file —
then harden, and watch the same URL start refusing you. (Walkthrough in
`solution.md`.)

## Requirements

The storage account in `lab-storage-blob03-rg` must have:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | Public blob access **disabled** | `allowBlobPublicAccess = false` |
| 2 | Minimum TLS version | `minimumTlsVersion = TLS1_2` |

## Work the question

```bash
./setup.bash       # provisions the exposed account, prints the blob URL
# ... confirm it's public, harden it, confirm it's blocked (see solution.md) ...
./validate.bash
./cleanup.bash
```
