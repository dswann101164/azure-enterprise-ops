# Security Best Practices

Comprehensive security guidance for AI-Assisted Azure Operations environments.

## Table of Contents

1. [Security Principles](#security-principles)
2. [Authentication & Authorization](#authentication--authorization)
3. [Secrets Management](#secrets-management)
4. [Network Security](#network-security)
5. [Monitoring & Auditing](#monitoring--auditing)
6. [Compliance](#compliance)
7. [Incident Response](#incident-response)
8. [Production Hardening](#production-hardening)

---

## Security Principles

### Defense in Depth

Multiple layers of security controls:

1. **Identity Layer**: Strong authentication (certificates, MFA)
2. **Perimeter Layer**: Network security groups, firewalls
3. **Network Layer**: Private endpoints, VNet isolation
4. **Compute Layer**: VM hardening, patch management
5. **Data Layer**: Encryption at rest and in transit
6. **Application Layer**: Secure coding, input validation
7. **Monitoring Layer**: Logging, alerting, SIEM integration

### Least Privilege

Grant minimum permissions required:

```powershell
# Bad: Owner role (too much access)
az role assignment create \
    --role "Owner" \
    --assignee $servicePrincipal \
    --scope /subscriptions/$subscriptionId

# Good: Specific role (just what's needed)
az role assignment create \
    --role "Contributor" \
    --assignee $servicePrincipal \
    --scope /subscriptions/$subscriptionId/resourceGroups/rg-aiops-test
```

### Zero Trust

Never trust, always verify:

- Verify every access request
- Use identity as primary security perimeter
- Assume breach (monitor everything)
- Segment access by resource

---

## Authentication & Authorization

### Service Principal Security

#### Use Certificate Authentication

**Why certificates over secrets:**
- No password rotation required
- Certificate expiration is manageable
- Harder to accidentally expose
- Audit trail in Key Vault
- Supports hardware security modules (HSM)

**Certificate Lifecycle Management:**

```powershell
# Check certificate expiration
$cert = Get-Item Cert:\CurrentUser\My\$thumbprint
$daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days

if ($daysUntilExpiration -lt 30) {
    Write-Warning "Certificate expires in $daysUntilExpiration days"
    # Trigger renewal process
}
```

**Certificate Storage:**

```powershell
# Secure certificate storage
$secureCertPath = "$env:USERPROFILE\Documents\Secure\Certificates"
New-Item -ItemType Directory -Path $secureCertPath -Force

# Set restrictive permissions
$acl = Get-Acl $secureCertPath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME,
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $secureCertPath $acl
```

#### Rotate Service Principals Regularly

**Rotation Schedule:**
- Development: Every 90 days
- Test: Every 60 days
- Production: Every 30 days

**Rotation Process:**

```powershell
# automation/rotate-service-principal.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ServicePrincipalId,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName
)

# Create new certificate
$newCertName = "aiops-cert-$(Get-Date -Format 'yyyyMMdd')"
az ad sp credential reset \
    --id $ServicePrincipalId \
    --create-cert \
    --cert $newCertName

# Store in Key Vault
$certPath = "$env:USERPROFILE\.azure\$newCertName.pem"
az keyvault secret set \
    --vault-name $KeyVaultName \
    --name "sp-certificate-$(Get-Date -Format 'yyyyMMdd')" \
    --file $certPath

# Update application configurations
# (Terraform, CI/CD pipelines, etc.)

# Set calendar reminder for 30 days
Write-Host "Certificate rotated successfully. Next rotation: $((Get-Date).AddDays(30).ToString('yyyy-MM-dd'))"
```

### Azure CLI Authentication

**Development/Test:**
```powershell
# Interactive login (MFA supported)
az login

# Select subscription
az account set --subscription "your-subscription-id"
```

**Production/Automation:**
```powershell
# Service principal with certificate
az login --service-principal \
    --username $appId \
    --password $certPath \
    --tenant $tenantId
```

### Multi-Factor Authentication

**Enable MFA for all human users:**

```powershell
# Check MFA status
az ad user list --query "[].{UPN:userPrincipalName, MFA:strongAuthenticationRequirements}" --output table

# Require MFA for all users (Azure Portal → Azure AD → Security → Conditional Access)
```

### Role-Based Access Control (RBAC)

**Principle of Least Privilege:**

| Role | Use Case | Scope |
|------|----------|-------|
| Reader | View-only access | Subscription/RG |
| Contributor | Manage resources | Resource Group |
| Owner | Full control + RBAC | Resource Group (limited) |
| Custom Role | Specific operations | Minimum scope |

**Custom Role Example:**

```json
{
  "Name": "AI-Ops Resource Reader",
  "Description": "Read Azure resources for AI analysis",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Compute/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.Storage/storageAccounts/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/your-subscription-id/resourceGroups/rg-aiops-test"
  ]
}
```

```powershell
# Create custom role
az role definition create --role-definition custom-role.json

# Assign to service principal
az role assignment create \
    --role "AI-Ops Resource Reader" \
    --assignee $servicePrincipalId \
    --scope /subscriptions/$subscriptionId/resourceGroups/rg-aiops-test
```

---

## Secrets Management

### Azure Key Vault Best Practices

#### Access Control

**Use RBAC (not access policies):**

```hcl
# Terraform configuration
resource "azurerm_key_vault" "aiops" {
  enable_rbac_authorization = true
  
  # Disable access policies
  # access_policy = []
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.aiops.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.service_principal_id
}
```

**Key Vault Roles:**

| Role | Permissions | Use Case |
|------|-------------|----------|
| Key Vault Reader | View metadata only | Auditors |
| Key Vault Secrets User | Read secrets | Applications |
| Key Vault Secrets Officer | Manage secrets | Admins |
| Key Vault Administrator | Full control | Emergency only |

#### Audit Logging

**Enable diagnostic settings:**

```powershell
# Send Key Vault logs to Log Analytics
az monitor diagnostic-settings create \
    --resource $(az keyvault show --name $kvName --query id -o tsv) \
    --name kv-audit-logs \
    --workspace $(az monitor log-analytics workspace show --resource-group rg-aiops-test --workspace-name $lawName --query id -o tsv) \
    --logs '[{"category": "AuditEvent", "enabled": true}]' \
    --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

**Query audit logs:**

```kusto
// Key Vault secret access
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet" or OperationName == "SecretList"
| project TimeGenerated, CallerIPAddress, identity_claim_upn_s, OperationName, ResultSignature
| order by TimeGenerated desc
```

#### Secret Rotation

**Automated secret rotation:**

```powershell
# automation/rotate-secrets.ps1

$secrets = @(
    "vm-admin-password",
    "storage-account-key",
    "database-connection-string"
)

foreach ($secret in $secrets) {
    # Check expiration
    $secretInfo = az keyvault secret show \
        --vault-name $kvName \
        --name $secret \
        --query "attributes.expires" -o tsv
    
    $expiresDate = [datetime]$secretInfo
    $daysUntilExpiration = ($expiresDate - (Get-Date)).Days
    
    if ($daysUntilExpiration -lt 7) {
        Write-Host "Rotating secret: $secret"
        
        # Generate new secret
        $newSecret = New-Guid | ConvertTo-SecureString -AsPlainText -Force
        
        # Update in Key Vault
        az keyvault secret set \
            --vault-name $kvName \
            --name $secret \
            --value $newSecret \
            --expires (Get-Date).AddDays(90).ToString("yyyy-MM-dd")
        
        # Update applications using this secret
        # (Restart services, update configurations, etc.)
    }
}
```

### Never Store Secrets in Code

**Bad (hardcoded secrets):**
```powershell
# NEVER DO THIS
$password = "SuperSecret123!"
$connectionString = "Server=sql.azure.com;User=admin;Password=Secret123"
```

**Good (Key Vault references):**
```powershell
# Retrieve from Key Vault
$password = az keyvault secret show \
    --vault-name $kvName \
    --name "vm-admin-password" \
    --query "value" -o tsv

$connectionString = az keyvault secret show \
    --vault-name $kvName \
    --name "sql-connection-string" \
    --query "value" -o tsv
```

### Git Security

**Never commit secrets:**

```bash
# .gitignore
*.pem
*.pfx
*.key
*.crt
*.env
*.env.local
terraform.tfvars
sp-config.json
*.backup
```

**Scan for secrets:**

```powershell
# Install git-secrets
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make install

# Configure for repository
cd your-repo
git secrets --install
git secrets --register-aws
git secrets --add 'password\s*=\s*.+'
git secrets --add 'secret\s*=\s*.+'
```

**Pre-commit hook:**

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for potential secrets
if git diff --cached --name-only | grep -E '\.(pem|pfx|key)$'; then
    echo "Error: Attempting to commit certificate or key file"
    exit 1
fi

# Check for hardcoded secrets
if git diff --cached | grep -iE 'password|secret|key|token' | grep -E '=\s*["\047][^"\047]{8,}["\047]'; then
    echo "Warning: Potential hardcoded secret detected"
    echo "Please use Key Vault or environment variables"
    exit 1
fi
```

---

## Network Security

### Network Security Groups (NSGs)

**Principle: Deny by default, allow explicitly**

**Good NSG Rules:**

```hcl
# Terraform: Restrictive SSH access
resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSHFromCorporate"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = ["203.0.113.0/24"]  # Corporate IP range
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aiops.name
  network_security_group_name = azurerm_network_security_group.aiops.name
}

# Explicit deny for everything else
resource "azurerm_network_security_rule" "deny_all" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aiops.name
  network_security_group_name = azurerm_network_security_group.aiops.name
}
```

**NSG Flow Logs:**

```powershell
# Enable NSG flow logs
az network watcher flow-log create \
    --location eastus \
    --name nsg-flow-logs \
    --nsg $(az network nsg show --resource-group rg-aiops-test --name aiops-nsg --query id -o tsv) \
    --storage-account $(az storage account show --resource-group rg-aiops-test --name aiopsstxxx --query id -o tsv) \
    --workspace $(az monitor log-analytics workspace show --resource-group rg-aiops-test --workspace-name aiops-law --query id -o tsv) \
    --enabled true \
    --retention 90
```

**Analyze NSG logs:**

```kusto
// Top denied connections
AzureNetworkAnalytics_CL
| where FlowStatus_s == "D"  // Denied
| summarize count() by SrcIP_s, DestPort_d, L7Protocol_s
| order by count_ desc
| take 20
```

### Private Endpoints

**Production pattern: No public access**

```hcl
# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "kv" {
  name                = "${local.prefix}-kv-pe"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "kv-private-connection"
    private_connection_resource_id = azurerm_key_vault.aiops.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# Disable public access
resource "azurerm_key_vault" "aiops" {
  public_network_access_enabled = false
  
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }
}
```

### Azure Firewall (Optional)

**For production environments:**

```hcl
resource "azurerm_firewall" "aiops" {
  name                = "${local.prefix}-fw"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Network rules
resource "azurerm_firewall_network_rule_collection" "aiops" {
  name                = "aiops-network-rules"
  azure_firewall_name = azurerm_firewall.aiops.name
  resource_group_name = azurerm_resource_group.aiops.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "AllowAzureServices"
    source_addresses = ["10.0.0.0/16"]
    destination_ports = ["443"]
    destination_addresses = [
      "AzureCloud",
      "AzureActiveDirectory"
    ]
    protocols = ["TCP"]
  }
}
```

---

## Monitoring & Auditing

### Azure Monitor

**Log everything:**

```hcl
# Diagnostic settings for all resources
resource "azurerm_monitor_diagnostic_setting" "resource" {
  name                       = "${var.resource_name}-diagnostics"
  target_resource_id         = var.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Enable all log categories
  dynamic "enabled_log" {
    for_each = var.log_categories
    content {
      category = enabled_log.value
    }
  }

  # Enable all metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### Security Alerts

**Critical alerts to configure:**

```kusto
// Alert: Unauthorized Key Vault access
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where ResultSignature == "Unauthorized"
| project TimeGenerated, CallerIPAddress, OperationName, ResultDescription
```

```kusto
// Alert: Failed authentication attempts
SigninLogs
| where ResultType != "0"  // 0 = success
| where TimeGenerated > ago(1h)
| summarize FailedAttempts = count() by UserPrincipalName, IPAddress
| where FailedAttempts > 5
```

```kusto
// Alert: Privileged role assignment changes
AuditLogs
| where OperationName == "Add member to role"
| where TargetResources has "Owner" or TargetResources has "Contributor"
| project TimeGenerated, InitiatedBy, TargetResources
```

**Create alert rules:**

```powershell
# Failed authentication alert
az monitor metrics alert create \
    --name "HighFailedAuthentications" \
    --resource-group rg-aiops-test \
    --scopes $(az monitor log-analytics workspace show --resource-group rg-aiops-test --workspace-name aiops-law --query id -o tsv) \
    --condition "count() > 10" \
    --window-size 5m \
    --evaluation-frequency 5m \
    --action email your-email@example.com
```

### Microsoft Defender for Cloud

**Enable for all resource types:**

```powershell
# Enable Defender for Cloud
az security pricing create \
    --name VirtualMachines \
    --tier Standard

az security pricing create \
    --name StorageAccounts \
    --tier Standard

az security pricing create \
    --name KeyVaults \
    --tier Standard
```

**Review recommendations:**

```powershell
# Get security recommendations
az security assessment list --output table

# Get specific recommendation details
az security assessment show \
    --name "recommendation-id" \
    --query "{Title:displayName, Status:status.code, Description:metadata.description}"
```

---

## Compliance

### Azure Policy

**Enforce security baselines:**

```hcl
# Require specific tags
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-security-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Security and Compliance Tags"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['DataClassification']", exists = "false" },
        { field = "tags['Compliance']", exists = "false" },
        { field = "tags['Owner']", exists = "false" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# Deny public IPs (except approved resources)
resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip-creation"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny Public IP Creation"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Network/publicIPAddresses" },
        { field = "tags['AllowPublicIP']", notEquals = "true" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}
```

**Compliance scanning:**

```powershell
# Check policy compliance
az policy state list \
    --resource-group rg-aiops-test \
    --query "[?complianceState=='NonCompliant'].{Resource:resourceId, Policy:policyDefinitionName}" \
    --output table
```

### Regulatory Compliance

**Common frameworks:**

- **SOC 2**: Service Organization Control 2
- **ISO 27001**: Information Security Management
- **HIPAA**: Health Insurance Portability
- **PCI DSS**: Payment Card Industry Data Security
- **GDPR**: General Data Protection Regulation

**Azure compliance tools:**

```powershell
# View compliance status
az security regulatory-compliance-standards list --output table

# Detailed compliance assessment
az security regulatory-compliance-controls list \
    --standard-name "Azure-CIS-1.1.0" \
    --output table
```

---

## Incident Response

### Incident Response Plan

**1. Detection**
- Automated alerts (Azure Monitor)
- Security Center notifications
- User reports

**2. Containment**
```powershell
# Immediate containment actions

# Disable compromised service principal
az ad sp update --id $compromisedAppId --set "accountEnabled=false"

# Revoke all sessions
az ad app credential reset --id $appId --append

# Block suspicious IP in NSG
az network nsg rule create \
    --resource-group rg-aiops-test \
    --nsg-name aiops-nsg \
    --name BlockSuspiciousIP \
    --priority 100 \
    --source-address-prefixes "suspicious.ip.address" \
    --destination-address-prefixes "*" \
    --access Deny \
    --protocol "*"
```

**3. Investigation**
```kusto
// Timeline of suspicious activity
union AzureActivity, AzureDiagnostics, SigninLogs
| where TimeGenerated between (datetime(incident-start) .. datetime(incident-end))
| where CallerIPAddress == "suspicious.ip.address" or 
        identity_claim_upn_s == "compromised.user@domain.com"
| project TimeGenerated, OperationName, ResourceProvider, ResultSignature, Properties
| order by TimeGenerated asc
```

**4. Eradication**
- Rotate all credentials
- Patch vulnerabilities
- Update security policies

**5. Recovery**
```powershell
# Restore from clean backup
terraform destroy -target=azurerm_resource_group.compromised
terraform apply

# Redeploy with hardened configuration
```

**6. Lessons Learned**
- Document incident timeline
- Update runbooks
- Improve detection capabilities

### Emergency Access

**Break-glass account:**

```powershell
# Create emergency admin account
az ad user create \
    --display-name "Emergency Admin" \
    --user-principal-name emergency-admin@yourdomain.com \
    --password "SecureRandomPassword123!" \
    --force-change-password-next-sign-in

# Assign Owner role (use sparingly)
az role assignment create \
    --role "Owner" \
    --assignee emergency-admin@yourdomain.com \
    --scope /subscriptions/$subscriptionId

# Store credentials in secure offline location
# Set up monitoring for emergency account usage
```

---

## Production Hardening

### Hardening Checklist

**Identity & Access:**
- [ ] MFA enabled for all users
- [ ] Service principals use certificates
- [ ] Privileged accounts require approval
- [ ] Just-in-time access configured
- [ ] Regular access reviews scheduled

**Network:**
- [ ] Private endpoints for all PaaS services
- [ ] NSGs on all subnets
- [ ] Azure Firewall deployed
- [ ] DDoS Protection Standard enabled
- [ ] Network segmentation implemented

**Data:**
- [ ] Encryption at rest enabled
- [ ] TLS 1.2+ enforced
- [ ] Key Vault for all secrets
- [ ] Backup retention configured
- [ ] Data classification tags applied

**Compute:**
- [ ] VMs use managed identities
- [ ] Auto-shutdown configured
- [ ] Azure Update Management enabled
- [ ] Antimalware extensions installed
- [ ] Boot diagnostics enabled

**Monitoring:**
- [ ] Diagnostic settings on all resources
- [ ] Security Center enabled
- [ ] Log retention ≥ 90 days
- [ ] Alert rules configured
- [ ] Automated response playbooks

**Compliance:**
- [ ] Azure Policy assigned
- [ ] Regulatory compliance validated
- [ ] Security baselines applied
- [ ] Audit logs preserved
- [ ] Compliance reports automated

### Security Automation

**Automated remediation:**

```powershell
# automation/auto-remediate.ps1

# Find unencrypted storage accounts
$unencryptedAccounts = az storage account list --query "[?encryption.services.blob.enabled==false]" | ConvertFrom-Json

foreach ($account in $unencryptedAccounts) {
    Write-Host "Enabling encryption for: $($account.name)"
    
    az storage account update \
        --name $account.name \
        --resource-group $account.resourceGroup \
        --encryption-services blob file
    
    # Log to Security Center
    Write-Log "Remediated unencrypted storage account: $($account.name)"
}
```

---

## Security Testing

### Penetration Testing

**Azure-approved testing:**

1. **Notification not required** for:
   - Automated scanning
   - Vulnerability assessments
   - Web application testing

2. **Notify Microsoft** for:
   - DDoS testing
   - Social engineering
   - Physical security testing

**Testing tools:**

```powershell
# Nmap scan (authorized networks only)
nmap -sV -sC -p- your-public-ip.azure.com

# OWASP ZAP for web apps
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://your-app.azurewebsites.net

# Azure Security Benchmark assessment
az security assessment list --query "[?status.code=='Unhealthy']"
```

### Security Reviews

**Quarterly security review:**

```powershell
# automation/security-review.ps1

# 1. Service principal audit
Write-Host "=== Service Principal Audit ==="
az ad sp list --all --query "[].{Name:displayName, Created:additionalProperties.createdDateTime, AppId:appId}" --output table

# 2. RBAC assignments
Write-Host "=== Privileged Role Assignments ==="
az role assignment list --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor'].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" --output table

# 3. Exposed resources
Write-Host "=== Resources with Public Access ==="
az network public-ip list --query "[].{Name:name, IP:ipAddress, Resource:ipConfiguration.id}" --output table

# 4. Key Vault secrets nearing expiration
Write-Host "=== Key Vault Secrets Expiring Soon ==="
$secrets = az keyvault secret list --vault-name $kvName | ConvertFrom-Json
foreach ($secret in $secrets) {
    $details = az keyvault secret show --vault-name $kvName --name $secret.name | ConvertFrom-Json
    if ($details.attributes.expires) {
        $expiresDate = [datetime]$details.attributes.expires
        $daysUntilExpiration = ($expiresDate - (Get-Date)).Days
        if ($daysUntilExpiration -lt 30) {
            Write-Host "$($secret.name): Expires in $daysUntilExpiration days"
        }
    }
}

# 5. Compliance status
Write-Host "=== Compliance Status ==="
az policy state summarize --query "results.{NonCompliant:nonCompliantResources, Compliant:compliantResources}"
```

---

## Additional Resources

### Microsoft Security Documentation
- [Azure Security Baseline](https://docs.microsoft.com/en-us/security/benchmark/azure/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [Well-Architected Framework - Security](https://docs.microsoft.com/en-us/azure/architecture/framework/security/)

### Security Tools
- [Azure Security Center](https://azure.microsoft.com/en-us/services/security-center/)
- [Microsoft Sentinel](https://azure.microsoft.com/en-us/services/microsoft-sentinel/)
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/)

### Compliance Frameworks
- [Azure Compliance Offerings](https://docs.microsoft.com/en-us/azure/compliance/)
- [Trust Center](https://www.microsoft.com/en-us/trust-center)

---

**Security is not a one-time setup - it's an ongoing process. Review and update these practices regularly based on new threats and Azure capabilities.**
