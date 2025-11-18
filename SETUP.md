# Detailed Setup Guide

Complete step-by-step instructions for deploying the AI-Assisted Azure Operations environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Manual Setup](#manual-setup)
4. [Configuration](#configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

| Software | Version | Download |
|----------|---------|----------|
| PowerShell | 7.0+ | [Download](https://github.com/PowerShell/PowerShell/releases) |
| Azure CLI | 2.50.0+ | [Download](https://aka.ms/installazurecliwindows) |
| Terraform | 1.5.0+ | [Download](https://www.terraform.io/downloads) |
| Claude Desktop | Latest | [Download](https://claude.ai/download) |
| Node.js | 18.0+ LTS | [Download](https://nodejs.org/) |
| Git | 2.40+ | [Download](https://git-scm.com/downloads) |

### Azure Requirements

- **Azure Subscription**: Active subscription with billing enabled
- **Permissions**: 
  - Contributor or Owner role on subscription
  - Application Developer or Application Administrator in Azure AD
- **Quota**: At least 2 cores available for B-series VMs
- **Budget**: $20-50/month recommended for test environment

### Network Requirements

- Internet access to:
  - Azure endpoints (*.azure.com, *.microsoft.com)
  - npm registry (registry.npmjs.org)
  - Terraform registry (registry.terraform.io)
  - Claude Desktop services (*.anthropic.com)

---

## Quick Start

### One-Command Deployment

```powershell
# Clone repository
git clone https://github.com/yourusername/ai-ops2.git
cd ai-ops2

# Run deployment
.\Deploy-AIOps.ps1
```

**Deployment time**: ~10-15 minutes

**What happens**:
1. ✓ Prerequisites checked
2. ✓ Azure authentication
3. ✓ Service principal created
4. ✓ Infrastructure deployed
5. ✓ MCP servers configured
6. ✓ Validation completed

---

## Manual Setup

If you prefer manual setup or need to customize:

### Step 1: Install Prerequisites

#### PowerShell 7

```powershell
# Check current version
$PSVersionTable.PSVersion

# Install via winget
winget install Microsoft.PowerShell

# Or download installer
# https://github.com/PowerShell/PowerShell/releases
```

#### Azure CLI

```powershell
# Install via winget
winget install Microsoft.AzureCLI

# Or use MSI installer
# https://aka.ms/installazurecliwindows

# Verify installation
az version
```

#### Terraform

```powershell
# Install via winget
winget install Hashicorp.Terraform

# Or download binary
# https://www.terraform.io/downloads

# Verify installation
terraform version
```

#### Claude Desktop

```powershell
# Download and install from:
# https://claude.ai/download

# Verify installation
Test-Path "$env:LOCALAPPDATA\Programs\claude-desktop\Claude.exe"
```

#### Node.js

```powershell
# Install LTS version via winget
winget install OpenJS.NodeJS.LTS

# Verify installation
node --version
npm --version
```

### Step 2: Clone Repository

```powershell
# Create directory
New-Item -ItemType Directory -Path "$env:USERPROFILE\Documents\GitHub" -Force
cd "$env:USERPROFILE\Documents\GitHub"

# Clone repository
git clone https://github.com/yourusername/ai-ops2.git
cd ai-ops2
```

### Step 3: Azure Authentication

```powershell
# Login to Azure
az login

# Select subscription (if you have multiple)
az account list --output table
az account set --subscription "your-subscription-name"

# Verify authentication
az account show
```

### Step 4: Create Service Principal

```powershell
# Set variables
$subscriptionId = (az account show --query id --output tsv)
$spName = "sp-aiops-claude-$(Get-Random -Minimum 1000 -Maximum 9999)"

# Create service principal with certificate
az ad sp create-for-rbac `
    --name $spName `
    --role "Contributor" `
    --scopes "/subscriptions/$subscriptionId" `
    --create-cert `
    --cert "aiops-cert"

# Certificate will be in: $env:USERPROFILE\.azure\aiops-cert.pem
# Copy to project directory
Copy-Item "$env:USERPROFILE\.azure\aiops-cert.pem" .
```

**Important**: Save the output - you'll need the appId and tenant

### Step 5: Configure Terraform Variables

```powershell
# Navigate to terraform directory
cd terraform

# Create terraform.tfvars
@"
subscription_id      = "your-subscription-id"
tenant_id           = "your-tenant-id"
service_principal_id = "your-app-id"
location            = "eastus"
resource_group_name = "rg-aiops-test"
"@ | Set-Content terraform.tfvars
```

### Step 6: Deploy Infrastructure

```powershell
# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Save outputs
terraform output > outputs.txt
```

### Step 7: Configure MCP Servers

#### Update MCP Configuration

Edit `mcp/servers.json` to match your paths:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2",
        "C:\\Users\\YourUsername\\Documents\\GitHub"
      ]
    }
  }
}
```

#### Install MCP Configuration

```powershell
# Create Claude config directory
$configDir = "$env:APPDATA\Claude"
New-Item -ItemType Directory -Path $configDir -Force

# Backup existing config
if (Test-Path "$configDir\claude_desktop_config.json") {
    Copy-Item "$configDir\claude_desktop_config.json" `
        "$configDir\claude_desktop_config.json.backup"
}

# Copy configuration
Copy-Item .\mcp\servers.json "$configDir\claude_desktop_config.json"
```

### Step 8: Restart Claude Desktop

```powershell
# Close Claude Desktop
Stop-Process -Name "Claude" -ErrorAction SilentlyContinue

# Wait a moment
Start-Sleep -Seconds 3

# Launch Claude Desktop
Start-Process "$env:LOCALAPPDATA\Programs\claude-desktop\Claude.exe"
```

---

## Configuration

### Customizing Resource Names

Edit `terraform/variables.tf` to change defaults:

```hcl
variable "resource_group_name" {
  default     = "rg-your-custom-name"
}

variable "location" {
  default     = "westus2"  # Change region
}

variable "vm_size" {
  default     = "Standard_B2s"  # Change VM size
}
```

### Customizing Auto-Shutdown

```hcl
variable "enable_auto_shutdown" {
  default     = true
}

variable "auto_shutdown_time" {
  default     = "1900"  # 7 PM
}

variable "auto_shutdown_timezone" {
  default     = "Pacific Standard Time"  # Change timezone
}
```

### Customizing Budget Alert

```hcl
variable "budget_amount" {
  default     = 100  # $100/month
}

variable "budget_notification_threshold" {
  default     = 75  # 75%
}
```

### Adding Network Security Rules

Edit `terraform/test-resources.tf`:

```hcl
# Allow RDP (example)
security_rule {
  name                       = "AllowRDP"
  priority                   = 1100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefixes    = ["1.2.3.4/32"]
  destination_address_prefix = "*"
}
```

### Customizing MCP Servers

Add or remove servers in `mcp/servers.json`:

```json
{
  "mcpServers": {
    "your-custom-server": {
      "command": "npx",
      "args": [
        "-y",
        "@namespace/server-name",
        "--option",
        "value"
      ]
    }
  }
}
```

---

## Verification

### Test Azure Connection

```powershell
# Verify authentication
az account show

# List resources
az resource list --resource-group rg-aiops-test --output table

# Check VM status
az vm get-instance-view `
    --resource-group rg-aiops-test `
    --name $(az vm list -g rg-aiops-test --query "[0].name" -o tsv) `
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" `
    --output tsv
```

### Test Terraform State

```powershell
cd terraform

# Show current state
terraform show

# Validate configuration
terraform validate

# Check outputs
terraform output
```

### Test MCP Servers in Claude Desktop

Open Claude Desktop and try these prompts:

#### Test filesystem
```
List the contents of the ai-ops2 directory
```

#### Test git
```
Show me the recent commits in this repository
```

#### Test fetch
```
Fetch the latest Azure status from status.azure.com
```

#### Test memory
```
Remember that our test resource group is rg-aiops-test
```

#### Test time
```
What time is it in UTC?
```

#### Test Azure integration
```
Show me all resources in the rg-aiops-test resource group
```

### Verification Checklist

- [ ] PowerShell 7.0+ installed
- [ ] Azure CLI authenticated
- [ ] Terraform initialized and applied
- [ ] Service principal created
- [ ] Key Vault accessible
- [ ] VM deployed and accessible
- [ ] MCP servers configured
- [ ] Claude Desktop recognizes tools
- [ ] Can query Azure resources via Claude
- [ ] Budget alert configured
- [ ] Auto-shutdown working

---

## Post-Deployment Steps

### 1. Secure Your Certificate

```powershell
# Move certificate to secure location
$secureDir = "$env:USERPROFILE\Documents\Secure"
New-Item -ItemType Directory -Path $secureDir -Force

Move-Item .\aiops-cert-*.pem $secureDir

# Update Terraform variables with new path
```

### 2. Set Up Cost Alerts

```powershell
# Add email notifications to budget
$budgetId = az consumption budget list --query "[0].id" -o tsv

az consumption budget update `
    --budget-name $(az consumption budget list --query "[0].name" -o tsv) `
    --contact-emails "your-email@example.com" `
    --contact-groups "your-action-group-id"
```

### 3. Configure Log Analytics Queries

Create custom queries in Log Analytics:

```kusto
// VM Performance - CPU
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart

// VM Performance - Memory
Perf
| where ObjectName == "Memory" and CounterName == "Available MBytes"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart
```

### 4. Test Backup and Recovery

```powershell
# Test infrastructure recreation
cd terraform
terraform destroy -auto-approve

# Verify clean removal
az resource list --resource-group rg-aiops-test

# Recreate
terraform apply -auto-approve
```

---

## Troubleshooting

### Common Issues

See [troubleshooting.md](../docs/troubleshooting.md) for detailed solutions.

**Quick fixes**:

```powershell
# Azure CLI issues
az account clear
az login

# Terraform issues
Remove-Item -Recurse .terraform
terraform init

# MCP server issues
npm cache clean --force
# Restart Claude Desktop

# Certificate issues
az ad sp delete --id "your-app-id"
# Re-run deployment script
```

---

## Advanced Configuration

### Use Remote State

Configure Terraform remote state in Azure:

```powershell
# Create storage account for state
az group create --name rg-terraform-state --location eastus

az storage account create `
    --name sttfstate$(Get-Random) `
    --resource-group rg-terraform-state `
    --location eastus `
    --sku Standard_LRS

az storage container create `
    --name tfstate `
    --account-name sttfstate...
```

Update `terraform/main.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate..."
    container_name       = "tfstate"
    key                  = "aiops.tfstate"
  }
}
```

### Enable Private Endpoints

For production, use private endpoints:

```hcl
# In terraform/key-vault.tf
resource "azurerm_private_endpoint" "kv" {
  name                = "${local.prefix}-kv-pe"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.aiops.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}
```

---

## Next Steps

After successful deployment:

1. Review [architecture documentation](../docs/architecture.md)
2. Try [example queries](../examples/query-resources.md)
3. Explore [automation scenarios](../examples/automation-scenarios.md)
4. Read [security best practices](../docs/security.md)
5. Set up monitoring dashboards
6. Configure alerting
7. Plan production deployment

---

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/yourusername/ai-ops2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ai-ops2/discussions)
- **Blog**: [azure-noob.com](https://azure-noob.com)
- **Email**: contact@azure-noob.com

---

**Ready to start using AI-assisted Azure operations!** 🚀
