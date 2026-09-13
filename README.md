# Hands-on Lab Exercises: Azure Storage and Databases

> **Topic:** Storing and serving data in Azure with **Blob Storage** (object
> storage) and **Azure SQL Database** (a managed relational database).

Welcome back. This is the second lab in the Cloud Administrator series. The first
lab was about **compute** (Virtual Machines and App Service). This one is about
**data**: where it lives, who can reach it, and what it costs to keep.

A real admin does not memorize every command. They know which breadcrumbs to
follow. Each problem here is a short, real world scenario. Your job is to work out
what it demands and solve it with the Azure CLI. You get a script to check your
work and a full solution walkthrough, freely, because this is a low stakes place
to build competency. Break things here so you do not have to break them in
production.

## What you will build

Eight graded questions across two categories, plus ten practice exercises:

- **Blob Storage:** create an account and container, upload a blob, lock down
  anonymous public access, and optimize cost with access tiers.
- **Azure SQL Database:** create a logical server and database, open the firewall
  so a client can connect, scale a database up, and move it to a serverless model
  that auto pauses when idle.

## How this lab is different from the Compute lab

If you finished the Compute lab, the rhythm here is the same (one folder per
question, `./setup.bash`, solve, `./validate.bash`, `./cleanup.bash`), but the
subject matter brings several new ideas that compute did not:

- **Control plane versus data plane.** With a VM you mostly manage the resource
  itself. With storage and databases there are two layers: managing the resource
  (creating an account or a database) and working with the data inside it
  (uploading a blob, running a SQL query). They often use different tools and
  different permissions. You will feel this the first time an owner of the
  subscription still cannot read a blob without the right data plane access.
- **Globally unique names.** A VM name only has to be unique inside its resource
  group. A storage account name and a SQL server name become public DNS names, so
  they must be unique across all of Azure and all lowercase. Because of that, the
  validators discover the resource in your resource group rather than assuming a
  fixed name, and you are free to pick your own.
- **Resource providers.** Before a subscription can create a kind of resource, its
  provider must be registered. Storage is usually registered already; Azure SQL
  often is not, so the SQL setups register `Microsoft.Sql` for you the first time.
- **Connecting to your data.** For the SQL questions you actually connect to the
  database with `sqlcmd` and watch a query fail before a firewall rule and succeed
  after. That is a new muscle: the resource can be healthy and still unreachable
  until you open the door.
- **Security and cost as first class tasks.** You will make a public blob private
  and prove it with `curl`, and you will move data to cheaper tiers and a database
  to a serverless model. Securing and right sizing data is a large part of a real
  admin's week.
- **Observe, do not assume.** Every question asks you to see the effect with your
  own eyes: a `curl` that goes from readable to refused, a tier that flips from Hot
  to Cool, a connection that starts working. The validator confirms it, but you
  should see it first.

## The three skills we are building

1. **Reading documentation.** The first question an admin asks is "where are the
   provider's docs for X?" Learn to navigate them and you can learn any service.
2. **Tooling.** We use the **Azure CLI** (`az`) exclusively. No portal for the
   exercises. We like the hard way, because the hard way is the way that sticks.
3. **Troubleshooting.** When things break, composure first. Understand the cause,
   fix it, and write down what happened.

## Prerequisites

- **An Azure subscription**, paid (pay as you go). The labs use inexpensive
  resources (`Standard_LRS` storage and `Basic` or small SQL tiers).
- **A lab VM (jumpbox) to work from.** You created this in the Compute lab and it
  is meant to last the whole semester. Use that same jumpbox here. The Azure CLI
  runs there, not on your laptop.

> **No jumpbox yet?** Set one up using the "Set up your lab environment" section of
> the Compute lab README (an Ubuntu 24.04 LTS VM in its own `lab-jumpbox-rg`, with
> the Azure CLI installed and `az login` done). Then come back here. Everything
> below assumes that jumpbox exists and you are logged in with `az`.

> **Region tip.** Azure capacity and feature availability vary by region. The
> default is `centralus`. If a create fails with a capacity or availability error,
> change `LAB_LOCATION` in [`lab-config.sh`](lab-config.sh) and try another region
> such as `eastus2`, `westus2`, `westus3`, `southcentralus`, `westeurope`, or
> `northeurope`.

## Getting started on your jumpbox

**1. Connect to the jumpbox.** The easiest way is **VS Code Remote-SSH**: you get a
file explorer, a rendered preview of each `problem.md` and `solution.md`, and a
terminal, all running on the jumpbox. Plain `ssh <user>@<public-ip>` or the
Portal's Bastion work too. (See the Compute lab README if you need the Remote-SSH
walkthrough again.)

**2. Clone this repo onto the jumpbox:**

```bash
git clone https://github.com/sailplatform/cloud-admin-lab-exercises-storage.git
cd cloud-admin-lab-exercises-storage
```

**3. Do the two one time prep steps for the SQL questions** (the Blob questions
need nothing extra):

```bash
# a) Register the Azure SQL resource provider on your subscription (one time).
#    The SQL setups also do this, but running it now avoids a first run surprise.
az provider register --namespace Microsoft.Sql --wait

# b) Get a SQL client. Azure Cloud Shell has sqlcmd preinstalled. To install it on
#    the Ubuntu jumpbox, use Microsoft's mssql-tools18 package:
curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && source ~/.bashrc
```

**4. Open the repo in VS Code and start.** Use **File, Open Folder,**
`cloud-admin-lab-exercises-storage`. Open a question's `problem.md`, hit the
preview icon to read it rendered, then run the scripts in the terminal:

```bash
cd 1-blob-storage/Question-1-Create-Storage-Account
./setup.bash        # then read problem.md and solve it
```

> **Cost warning.** These labs create **real Azure resources that cost real
> money**. Each question is isolated in its own resource group and uses cheap SKUs.
> You are billed while resources exist, so the golden rule is: provision, solve,
> validate, then **run `./cleanup.bash` the moment you finish a question.** The
> General Purpose database in the serverless question costs more than the others,
> so be especially prompt cleaning that one up.

> **Keep your jumpbox for the whole semester; do not delete it.** Just **stop
> (deallocate)** it when you are done for the day so it stops charging for compute,
> and **Start** it again next time. Only delete `lab-jumpbox-rg` at the end of the
> course.

## How each question is structured

Every graded question lives in its own self contained folder with five files:

| File | What it is |
|------|-----------|
| `setup.bash`    | Prepares or pre checks the environment (and, where relevant, provisions the starting resource). |
| `problem.md`    | The scenario and the exact requirements ("done" criteria). |
| `validate.bash` | Automated PASS or FAIL checks against your subscription. |
| `solution.md`   | A concise walkthrough of how an admin reasons about it. Read this if you get stuck. |
| `cleanup.bash`  | Deletes everything the question created. |

`setup.bash`, `validate.bash`, and `cleanup.bash` are executable scripts you run
from inside the question folder. No central runner, no question numbers to
remember. All scripts are open source: read them.

## The workflow

Everything happens inside a single question folder. `cd` into it and go:

```bash
cd 1-blob-storage/Question-1-Create-Storage-Account

./setup.bash       # 1. Prepare or preflight (and, where relevant, provision a starting resource)

# 2. Read problem.md and solve it yourself with the Azure CLI.
#    Stuck? Open solution.md in the same folder.

./validate.bash    # 3. Check your work. Prints PASS or FAIL for each requirement.

./cleanup.bash     # 4. Delete the resources so they stop costing money.
```

## Configuration: make it yours

Shared settings live in [`lab-config.sh`](lab-config.sh) at the repo root: the
**region** (`LAB_LOCATION`, default `centralus`), the resource group prefix
(`LAB_RG_PREFIX`, default `lab-storage`), and the SQL admin login name
(`LAB_SQL_ADMIN`, default `sqladmin`; the password is never stored, you set it
yourself). Change a value once and every script follows, or override for a single
run:

```bash
LAB_LOCATION=westus3 ./validate.bash
```

> **A note on passwords.** For the SQL questions you choose the server's admin
> password. It is your secret: never commit it to a file or share it. The lab only
> ever stores the non secret login name.

## Available questions

The lab is organized by category. Work each question from inside its folder.

### [`1-blob-storage/`](1-blob-storage/): Blob Storage (object storage)

| # | Topic | Skill |
|---|-------|-------|
| 1 | Create a Storage Account and Container | Create an account (kind and SKU) and a blob container |
| 2 | Upload a Blob | Put a file into a container with the right data plane auth |
| 3 | Block Public Access | Prove a blob is public with curl, then make it private |
| 4 | Optimize Cost with the Access Tier | Move an account default tier from Hot to Cool |

### [`2-azure-sql/`](2-azure-sql/): Azure SQL Database

| # | Topic | Skill |
|---|-------|-------|
| 1 | Create a Logical Server and a Database | Create a server (you set the password) and a Basic database |
| 2 | Configure the Server Firewall | Connect with sqlcmd, see it refused, open your IP, connect again |
| 3 | Scale the Database | Change the performance level from Basic to Standard S0 |
| 4 | Serverless with Auto Pause | Convert to a serverless model that pauses compute when idle |

Plus [**ten practice exercises**](practice/exercises.md) (five Blob, five SQL:
redundancy, SAS tokens, soft delete, lifecycle policies, tables and data,
point in time restore, and a capstone that exports a database to Blob Storage).

## The practice mindset (why solutions are given freely)

First study the worked examples, the graded questions, each with a `solution.md`
walkthrough of how an admin reasons through the task. Then drill the practice set
(problems only, no solutions) to build muscle memory. The point is not to know how
to create a storage account or a database. It is to prove you can, and to build the
habit of finding the answer when you do not already have it.
