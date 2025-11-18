# Troubleshooting Guide

Common issues and solutions for the AI-Assisted Azure Operations environment.

## Quick Diagnostics

Run these commands first to identify the issue:

```powershell
# Check Azure authentication
az account show

# Check Terraform state
cd terraform
terraform show

# Check MCP configuration
Get-Content "$env:APPDATA\Claude\claude_desktop_config.json" | ConvertFrom-Json

# Check service principal
az ad sp list --display-name "sp-aiops-*" --output table

# Check Key Vault access
az keyvault list --output table
```

---

## Deployment Issues

### Issue: Deploy-AIOps.ps1 Fails Immediately

**Symptoms**:
- Script stops with "Prerequisites check failed"
- Missing components error

**Solutions**:

1. **Check PowerShell version**:
   ```powershell
   $PSVersionTable.PSVersion
   # Must be 7.0 or higher
   ```
   
   Install PowerShell 7:
   ```powershell
   winget install Microsoft.PowerShell
   ```

2. **Install Azure CLI**:
   ```powershell
   winget install Microsoft.AzureCLI
   ```

3. **Install Terraform**:
   ```powershell
   winget install Hashicorp.Terraform
   ```

4. **Install Claude Desktop**:
   Download from: https://claude.ai/download

### Issue: Azure Login Fails

**Symptoms**:
- "az login" returns error
- Browser doesn't open
- Authentication timeout

**Solutions**:

1. **Clear Azure CLI cache**:
   ```powershell
   az account clear
   az login
   ```

2. **Try device code flow**:
   ```powershell
   az login --use-device-code
   ```

3. **Check network/proxy**:
   ```powershell
   # If behind corporate proxy
   $env:HTTP_PROXY = "http://proxy:port"
   $env:HTTPS_PROXY = "http://proxy:port"
   az login
   ```

4. **Verify Azure AD permissions**:
   - Must have permissions to create service principals
   - Contact Azure AD admin if needed

### Issue: Service Principal Creation Fails

**Symptoms**:
- "Insufficient privileges to complete the operation"
- Certificate generation error

**Solutions**:

1. **Check Azure AD role**:
   ```powershell
   # You need Application Developer or Application Administrator role
   az ad user show --id (az account show --query user.name -o tsv)
   ```

2. **Request elevated permissions**:
   - Contact Azure AD administrator
   - Need "Create applications" permission

3. **Use existing service principal**:
   - Skip service principal creation
   - Configure manually in Terraform variables

### Issue: Terraform Init Fails

**Symptoms**:
- "Error installing provider"
- "Registry service unreachable"

**Solutions**:

1. **Check Terraform version**:
   ```powershell
   terraform version
   # Must be 1.5.0 or higher
   ```

2. **Clear Terraform cache**:
   ```powershell
   Remove-Item -Recurse -Force .\.terraform
   Remove-Item -Force .\.terraform.lock.hcl
   terraform init
   ```

3. **Configure proxy** (if needed):
   ```powershell
   $env:HTTP_PROXY = "http://proxy:port"
   $env:HTTPS_PROXY = "http://proxy:port"
   terraform init
   ```

### Issue: Terraform Apply Fails

**Symptoms**:
- Resource creation errors
- "Resource already exists"
- Permission denied errors

**Solutions**:

1. **Check resource group**:
   ```powershell
   az group show --name rg-aiops-test
   # If exists, choose different name or delete:
   az group delete --name rg-aiops-test --yes
   ```

2. **Verify subscription permissions**:
   ```powershell
   az role assignment list --assignee (az account show --query user.name -o tsv) --output table
   # Need Contributor or Owner
   ```

3. **Check quota limits**:
   ```powershell
   az vm list-usage --location eastus --output table
   # Ensure B-series VMs available
   ```

4. **Review Terraform logs**:
   ```powershell
   $env:TF_LOG = "DEBUG"
   terraform apply
   ```

---

## MCP Server Issues

### Issue: MCP Servers Not Loading in Claude Desktop

**Symptoms**:
- Claude doesn't have access to filesystem
- "I don't have the ability to..." messages
- Tools not available

**Solutions**:

1. **Verify config file location**:
   ```powershell
   $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
   Test-Path $configPath
   ```

2. **Check JSON syntax**:
   ```powershell
   Get-Content $configPath | ConvertFrom-Json
   # If error, fix JSON syntax
   ```

3. **Restart Claude Desktop**:
   - Close all Claude windows
   - End process in Task Manager
   - Launch fresh instance

4. **Check Node.js installation**:
   ```powershell
   node --version
   npm --version
   # Must have Node.js 18 or higher
   ```
   
   Install Node.js:
   ```powershell
   winget install OpenJS.NodeJS.LTS
   ```

### Issue: Specific MCP Server Fails

**Symptoms**:
- One server works, another doesn't
- Error messages in Claude about specific tool

**Solutions**:

1. **Test npm package directly**:
   ```powershell
   npx -y @modelcontextprotocol/server-filesystem C:\Users\YourUsername\Documents
   # Should start without errors
   ```

2. **Clear npm cache**:
   ```powershell
   npm cache clean --force
   ```

3. **Update npm**:
   ```powershell
   npm install -g npm@latest
   ```

4. **Check file paths**:
   - Ensure paths in servers.json exist
   - Use double backslashes in JSON: `C:\\Users\\...`

### Issue: Filesystem Server Can't Access Directory

**Symptoms**:
- "Permission denied" in Claude
- Can't read/write files

**Solutions**:

1. **Check directory permissions**:
   ```powershell
   Get-Acl C:\Users\YourUsername\Documents\GitHub\ai-ops2 | Format-List
   ```

2. **Update allowed directories**:
   Edit `mcp/servers.json`:
   ```json
   "filesystem": {
     "args": [
       "-y",
       "@modelcontextprotocol/server-filesystem",
       "C:\\Your\\Allowed\\Path"
     ]
   }
   ```

3. **Run Claude as administrator** (not recommended for regular use):
   - Right-click Claude Desktop
   - "Run as administrator"

---

## Azure Authentication Issues

### Issue: Azure CLI Commands Fail

**Symptoms**:
- "Please run 'az login' to setup account"
- "The token is expired"

**Solutions**:

1. **Re-authenticate**:
   ```powershell
   az account clear
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Check token expiration**:
   ```powershell
   az account get-access-token --query "expiresOn"
   ```

3. **Use service principal**:
   ```powershell
   az login --service-principal `
     --username $appId `
     --password $certPath `
     --tenant $tenantId
   ```

### Issue: Service Principal Certificate Not Found

**Symptoms**:
- "Certificate file not found"
- Authentication fails with certificate

**Solutions**:

1. **Locate certificate**:
   ```powershell
   Get-ChildItem -Path . -Filter "aiops-cert-*.pem" -Recurse
   ```

2. **Regenerate certificate**:
   ```powershell
   # Delete old service principal
   az ad sp delete --id $appId
   
   # Re-run deployment script
   .\Deploy-AIOps.ps1
   ```

3. **Check certificate format**:
   ```powershell
   # Should be PEM format
   Get-Content .\aiops-cert-*.pem | Select-Object -First 1
   # Should show: -----BEGIN CERTIFICATE-----
   ```

### Issue: Key Vault Access Denied

**Symptoms**:
- "The user, group or application does not have secrets get permission"
- Can't read secrets from Key Vault

**Solutions**:

1. **Check RBAC assignment**:
   ```powershell
   az role assignment list --scope /subscriptions/.../resourceGroups/rg-aiops-test/providers/Microsoft.KeyVault/vaults/...
   ```

2. **Add yourself to Key Vault**:
   ```powershell
   $kvName = "aiopskvxxxxxx"
   $objectId = az ad signed-in-user show --query id -o tsv
   
   az role assignment create `
     --role "Key Vault Secrets Officer" `
     --assignee $objectId `
     --scope "/subscriptions/.../resourceGroups/rg-aiops-test/providers/Microsoft.KeyVault/vaults/$kvName"
   ```

3. **Wait for RBAC propagation**:
   - RBAC changes can take 5-10 minutes
   - Try again after waiting

---

## Claude Desktop Issues

### Issue: Claude Doesn't Understand Azure Context

**Symptoms**:
- Claude gives generic answers
- Doesn't use MCP tools
- No awareness of your infrastructure

**Solutions**:

1. **Be specific in prompts**:
   ```
   Bad:  "Show me resources"
   Good: "Use the filesystem tool to read terraform/terraform.tfstate and show me deployed resources"
   ```

2. **Verify MCP servers loaded**:
   Ask Claude: "What tools do you have access to?"

3. **Provide explicit context**:
   ```
   "Our resource group is rg-aiops-test in the eastus region. 
   Query Azure to show all resources in this group."
   ```

### Issue: Claude Creates Files in Wrong Location

**Symptoms**:
- Files created in unexpected directories
- Can't find generated scripts

**Solutions**:

1. **Specify full paths**:
   ```
   "Create a PowerShell script at C:\Users\YourUsername\Documents\GitHub\ai-ops2\scripts\query-vms.ps1"
   ```

2. **Check allowed directories**:
   Review `mcp/servers.json` for filesystem server allowed paths

3. **Request current directory**:
   Ask Claude: "What directory are you currently in?"

### Issue: Generated Scripts Don't Work

**Symptoms**:
- PowerShell errors
- Azure CLI commands fail
- Syntax errors

**Solutions**:

1. **Test in smaller chunks**:
   - Ask Claude to explain the script
   - Test individual commands first

2. **Request error handling**:
   ```
   "Add error handling and verbose output to this script"
   ```

3. **Validate before running**:
   ```
   "Review this script for errors and security issues before I run it"
   ```

---

## Cost Issues

### Issue: Costs Higher Than Expected

**Symptoms**:
- Azure bill exceeds $50/month
- Budget alerts triggering

**Solutions**:

1. **Check VM auto-shutdown**:
   ```powershell
   az vm show --resource-group rg-aiops-test --name aiops-vm-* --query "tags.AutoShutdown"
   ```

2. **Verify VM is stopping**:
   ```powershell
   az vm get-instance-view --resource-group rg-aiops-test --name aiops-vm-* --query "instanceView.statuses[?starts_with(code, 'PowerState')].code"
   ```

3. **Review cost by resource**:
   ```powershell
   az consumption usage list --start-date (Get-Date).AddDays(-30).ToString('yyyy-MM-dd') --query "[].{Name:instanceName, Cost:pretaxCost}" --output table
   ```

4. **Stop VM manually**:
   ```powershell
   az vm stop --resource-group rg-aiops-test --name aiops-vm-*
   az vm deallocate --resource-group rg-aiops-test --name aiops-vm-*
   ```

### Issue: Can't See Cost Data

**Symptoms**:
- No costs showing in portal
- Cost Management APIs return empty

**Solutions**:

1. **Wait for data population**:
   - Cost data can lag 24-48 hours
   - Check back tomorrow

2. **Check permissions**:
   ```powershell
   az role assignment list --scope /subscriptions/... | Where-Object { $_.roleDefinitionName -like "*Cost*" }
   # Need Cost Management Reader
   ```

3. **Use Azure Advisor**:
   ```powershell
   az advisor recommendation list --output table
   ```

---

## Network Issues

### Issue: Can't SSH to VM

**Symptoms**:
- Connection timeout
- SSH connection refused
- Public IP not reachable

**Solutions**:

1. **Check VM is running**:
   ```powershell
   az vm show --resource-group rg-aiops-test --name aiops-vm-* --query "powerState"
   ```

2. **Get public IP**:
   ```powershell
   $pip = az network public-ip show --resource-group rg-aiops-test --name aiops-vm-pip-* --query ipAddress -o tsv
   Write-Host "Public IP: $pip"
   ```

3. **Test connectivity**:
   ```powershell
   Test-NetConnection -ComputerName $pip -Port 22
   ```

4. **Check NSG rules**:
   ```powershell
   az network nsg rule list --resource-group rg-aiops-test --nsg-name aiops-nsg-* --output table
   ```

5. **Add your IP to NSG**:
   ```powershell
   $myIp = (Invoke-WebRequest -Uri "https://api.ipify.org").Content
   az network nsg rule update --resource-group rg-aiops-test --nsg-name aiops-nsg-* --name AllowSSH --source-address-prefixes $myIp
   ```

### Issue: Azure Resources Not Accessible

**Symptoms**:
- Can't access Key Vault
- Storage account connection fails
- Network timeout errors

**Solutions**:

1. **Check network connectivity**:
   ```powershell
   Test-NetConnection -ComputerName vault.azure.net -Port 443
   ```

2. **Verify firewall rules**:
   - Check corporate firewall
   - Verify proxy settings
   - Test from different network

3. **Review resource firewall**:
   ```powershell
   # Key Vault network rules
   az keyvault network-rule list --name aiopskvxxxxxx
   
   # Storage account network rules
   az storage account show --name aiops stxxxxxx --query networkRuleSet
   ```

---

## Data Loss Prevention

### Issue: Accidentally Deleted Resources

**Symptoms**:
- Resources missing from Azure
- Terraform state out of sync

**Solutions**:

1. **Check soft delete (Key Vault)**:
   ```powershell
   az keyvault list-deleted --output table
   az keyvault recover --name aiopskvxxxxxx
   ```

2. **Restore from Terraform**:
   ```powershell
   cd terraform
   terraform plan
   terraform apply
   ```

3. **Recreate from scratch**:
   ```powershell
   .\Deploy-AIOps.ps1
   ```

### Issue: Lost Service Principal Certificate

**Symptoms**:
- Can't find certificate file
- Authentication not working

**Solutions**:

1. **Search for certificate**:
   ```powershell
   Get-ChildItem -Path C:\ -Filter "aiops-cert-*.pem" -Recurse -ErrorAction SilentlyContinue
   ```

2. **Check Azure CLI location**:
   ```powershell
   Get-ChildItem "$env:USERPROFILE\.azure" -Filter "*.pem"
   ```

3. **Recreate service principal**:
   ```powershell
   # Delete old
   az ad sp delete --id $appId
   
   # Create new
   .\Deploy-AIOps.ps1
   ```

---

## Performance Issues

### Issue: Terraform Operations Slow

**Symptoms**:
- Terraform takes minutes to plan
- Apply operations timeout

**Solutions**:

1. **Enable parallelism**:
   ```powershell
   terraform apply -parallelism=10
   ```

2. **Use smaller state**:
   - Split into multiple modules
   - Use remote state

3. **Upgrade Terraform**:
   ```powershell
   winget upgrade Hashicorp.Terraform
   ```

### Issue: Azure CLI Commands Slow

**Symptoms**:
- Commands take 30+ seconds
- Frequent timeouts

**Solutions**:

1. **Clear CLI cache**:
   ```powershell
   az cache purge
   az cache delete
   ```

2. **Use output formats**:
   ```powershell
   # Faster
   az vm list --output tsv
   
   # Slower
   az vm list --output json
   ```

3. **Upgrade Azure CLI**:
   ```powershell
   az upgrade
   ```

---

## Getting Help

### Before Opening an Issue

1. Check this troubleshooting guide
2. Review deployment logs
3. Test individual components
4. Gather diagnostic information

### Diagnostic Information to Collect

```powershell
# System information
$PSVersionTable | Out-File diagnostics.txt
az version >> diagnostics.txt
terraform version >> diagnostics.txt

# Azure state
az account show >> diagnostics.txt
az group list --output table >> diagnostics.txt

# Terraform state
cd terraform
terraform show >> diagnostics.txt

# MCP configuration
Get-Content "$env:APPDATA\Claude\claude_desktop_config.json" >> diagnostics.txt
```

### Where to Get Help

1. **GitHub Issues**: [Repository Issues](https://github.com/yourusername/ai-ops2/issues)
2. **Azure Support**: For Azure-specific issues
3. **Anthropic Discord**: For Claude/MCP issues
4. **Blog Comments**: [azure-noob.com](https://azure-noob.com)

### Common Error Messages

| Error | Solution |
|-------|----------|
| `The subscription is not registered` | `az provider register --namespace Microsoft.Compute` |
| `Operation could not be completed` | Wait 5 minutes, retry |
| `InvalidAuthenticationToken` | `az account clear && az login` |
| `MissingSubscriptionRegistration` | `az provider register --namespace ...` |
| `QuotaExceeded` | Request quota increase or use different region |
| `ResourceGroupNotFound` | Verify resource group name and region |
| `InvalidCertificate` | Regenerate service principal certificate |

---

**Still stuck?** Open an issue on GitHub with:
- What you're trying to do
- What's happening instead
- Diagnostic information
- Steps to reproduce

We're here to help!
