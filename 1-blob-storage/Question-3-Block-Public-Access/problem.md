# Question 3 — Lock Down the Storage Account

## Scenario

A security review flagged a storage account: a container is set to **anonymous
public access**, so anyone with the blob's URL can read it — no credentials
required. The account also still **accepts old TLS versions**. As the cloud
administrator, prove the exposure, then harden the account.

`setup.bash` provisions the account in this insecure state and uploads a file
(`secret.txt`) into a public container so there is something real to test.

## Do it in three moves — don't just run commands, *observe* them

**1. See the problem.** After `./setup.bash`, take the blob URL it prints and
open it in a browser, or `curl -i` it. You should get **HTTP 200** and the file
contents with no login. That is the vulnerability.

**2. Fix it.** Harden the account so it meets the requirements below.

**3. Confirm the fix.** `curl -i` the *same* URL again. You should now get
**HTTP 403** (`PublicAccessNotPermitted`) — the file is no longer readable
anonymously. Seeing the 200 turn into a 403 is the whole point of this question.

## Requirements

The storage account in `lab-storage-blob03-rg` must have:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | Public blob access **disabled** | `allowBlobPublicAccess = false` |
| 2 | Minimum TLS version | `minimumTlsVersion = TLS1_3` |

## Work the question

```bash
./setup.bash      # provisions the exposed account, prints the blob URL
curl -i "<url>"   # move 1: confirm HTTP 200 (publicly readable)
# ... harden it yourself (see solution.md if you get stuck) ...
curl -i "<url>"   # move 3: confirm HTTP 403 (blocked)
./validate.bash
./cleanup.bash
```
