# Solution — Configure the Server Firewall

**Reference:** *Azure CLI reference → SQL → `az sql server firewall-rule`*:
<https://learn.microsoft.com/cli/azure/sql/server/firewall-rule#az-sql-server-firewall-rule-create>
(or `az sql server firewall-rule create --help`).

The server firewall is an **allow-list of IP ranges** at the server (not the
database) level. Empty list = nobody connects. You add your client's public IP.

## Move 1 — see it blocked

```bash
SRV=$(az sql server list -g lab-storage-sql02-rg --query "[0].name" -o tsv)
FQDN=$(az sql server show -g lab-storage-sql02-rg -n "$SRV" \
  --query fullyQualifiedDomainName -o tsv)

sqlcmd -S "$FQDN" -U sqladmin -P '<your-password>' -d appdb -Q "SELECT 'connected' AS status"
# -> Cannot open server ... Client with IP address 'x.x.x.x' is not allowed...
```

> **No `sqlcmd`?** Easiest is **Azure Cloud Shell** (it's preinstalled — just add a
> firewall rule for Cloud Shell's egress IP the same way). To install it on the
> Ubuntu jumpbox, use Microsoft's `mssql-tools18` package (the `sqlcmd`/`bcp`
> tools). Note the package is **`mssql-tools18`**, *not* `sqlcmd`, it needs the
> EULA accepted, and it installs under `/opt/mssql-tools18/bin`:
>
> ```bash
> curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
> sudo dpkg -i packages-microsoft-prod.deb
> sudo apt-get update
> sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
> echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && source ~/.bashrc
> ```

## Move 2 — allow your IP

Find your public IP and open a rule for exactly that address:

```bash
MYIP=$(curl -s -4 https://api.ipify.org)          # your IPv4 (firewall is IPv4-only)

az sql server firewall-rule create -g lab-storage-sql02-rg -s "$SRV" \
  -n allow-my-client --start-ip-address "$MYIP" --end-ip-address "$MYIP"
```

Use your **one** IP for start and end. A range like `0.0.0.0`–`255.255.255.255`
would "work" but exposes the server to the entire internet — don't.

## Move 3 — confirm

```bash
sqlcmd -S "$FQDN" -U sqladmin -P '<your-password>' -d appdb -Q "SELECT 'connected' AS status"
# status
# ----------
# connected
```

The identical command that was refused now returns a row. (Firewall changes take
effect within a few seconds.)

| Goal | Command |
|------|---------|
| Get your public IPv4 | `curl -s -4 https://api.ipify.org` |
| See firewall-rule flags | `az sql server firewall-rule create --help` |
| Allow your IP | `az sql server firewall-rule create -g <rg> -s <server> -n allow-my-client --start-ip-address <ip> --end-ip-address <ip>` |
| List firewall rules | `az sql server firewall-rule list -g <rg> -s <server> -o table` |
| Server endpoint (FQDN) | `az sql server show -g <rg> -n <server> --query fullyQualifiedDomainName -o tsv` |
