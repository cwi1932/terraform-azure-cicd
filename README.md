# Terraform + Azure CI/CD Pipeline

A complete Infrastructure-as-Code project: a Linux virtual machine deployed to Azure using Terraform, with remote state storage and a fully automated GitHub Actions CI/CD pipeline.

> A detailed write-up of the build process — including every real error encountered and how it was fixed — is available in [`docs/Terraform_Azure_CICD_Case_Study.docx`](./docs/Terraform_Azure_CICD_Case_Study.docx).

## What this deploys

| Resource | Purpose |
|---|---|
| Resource Group | Container for all project resources |
| Virtual Network + Subnet | Private network for the VM |
| Network Interface | Connects the VM to the subnet |
| Linux Virtual Machine (Ubuntu 22.04 Jammy) | The compute resource |
| TLS Key Pair (auto-generated) | SSH access, generated at `apply` time — no dependency on local files |

State is stored remotely in an Azure Storage Account (separate from the resources above), enabling the CI/CD pipeline to run on GitHub-hosted runners.

## Architecture

```
GitHub Push → GitHub Actions → Terraform Init (remote backend)
                              → Terraform Format Check
                              → Terraform Plan   (on pull request)
                              → Terraform Apply  (on push to main)
                                      ↓
                          Azure (Resource Group → VNet → Subnet → NIC → VM)
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.1.0
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in (`az login`)
- An Azure subscription
- A GitHub repository with the following **Actions secrets** configured:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Service Principal application (client) ID |
| `AZURE_CLIENT_SECRET` | Service Principal client secret |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION` | Azure subscription ID |

The Service Principal must have:
- `Contributor` on the target subscription
- `Storage Blob Data Contributor` on the remote state storage account

## Project structure

```
.
├── .github/
│   └── workflows/
│       └── terraform.yml      # CI/CD pipeline definition
├── main.tf                    # Resource group, network, VM, SSH key
├── provider.tf                # Provider, required_providers, backend config
└── README.md
```

## Usage — local

```bash
# Authenticate to Azure
az login

# Initialize (connects to the remote backend)
terraform init

# Check formatting
terraform fmt -check

# Preview changes
terraform plan

# Apply changes
terraform apply

# Tear down when done
terraform destroy
```

## Usage — CI/CD

The pipeline runs automatically:

- **Pull request → `main`** — runs `init`, `fmt -check`, and `plan`. No changes are applied; the plan is visible in the workflow logs for review.
- **Push → `main`** — runs `init`, `fmt -check`, and `apply -auto-approve`, deploying the changes to Azure automatically.

No manual `terraform apply` is needed once a change is merged.

## Remote state backend

State is stored in Azure Blob Storage rather than locally, so it can be safely shared between a local machine and the GitHub Actions runner:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate"
  storage_account_name = "<your-storage-account>"
  container_name        = "tfstate"
  key                    = "terraform.tfstate"
  use_azuread_auth       = true
}
```

`use_azuread_auth = true` authenticates to the backend using Azure AD (the same Service Principal used by the pipeline) rather than a storage account key.

## Notes

- The VM's SSH key pair is generated dynamically on every `apply` (via the `tls_private_key` resource), so the deployment has no dependency on any file on the local machine — required for it to run unmodified inside GitHub Actions.
- VM size and image are pinned to values confirmed available in the deployment region/subscription; see the case study document for the specific capacity and hypervisor-generation issues encountered and resolved.

## Author

Pramod Sasi — Azure & Terraform
