# Azure Key Vault Configuration
# Stores secrets, certificates, and keys for AI-Ops environment

# Get current user/service principal for Key Vault access
data "azurerm_client_config" "current" {}

# Key Vault for secure storage
resource "azurerm_key_vault" "aiops" {
  name                = "${local.prefix}kv${local.suffix}"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Security settings
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = false # Set to true for production
  soft_delete_retention_days      = 7

  # Network access
  public_network_access_enabled = true
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Change to "Deny" and configure IP rules for production
    
    # Uncomment and configure for production
    # ip_rules = var.allowed_ip_ranges
  }

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Security"
      Purpose      = "Secrets Management"
    }
  )
}

# Key Vault Access Policy for current user (for initial setup)
resource "azurerm_role_assignment" "current_user_kv_secrets" {
  scope                = azurerm_key_vault.aiops.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "current_user_kv_certificates" {
  scope                = azurerm_key_vault.aiops.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Service Principal access to Key Vault
data "azuread_service_principal" "aiops" {
  client_id = var.service_principal_id
}

resource "azurerm_role_assignment" "sp_kv_secrets" {
  scope                = azurerm_key_vault.aiops.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.aiops.object_id
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "kv-diagnostics"
  target_resource_id         = azurerm_key_vault.aiops.id
  storage_account_id         = azurerm_storage_account.aiops.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Store VM admin password in Key Vault
resource "random_password" "vm_admin" {
  length  = 24
  special = true
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_admin.result
  key_vault_id = azurerm_key_vault.aiops.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets
  ]

  tags = {
    Purpose = "VM Administrator Password"
  }
}

# Store service principal details (for reference)
resource "azurerm_key_vault_secret" "sp_client_id" {
  name         = "service-principal-client-id"
  value        = var.service_principal_id
  key_vault_id = azurerm_key_vault.aiops.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets
  ]

  tags = {
    Purpose = "Service Principal Authentication"
  }
}

# Store subscription ID
resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "azure-subscription-id"
  value        = var.subscription_id
  key_vault_id = azurerm_key_vault.aiops.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets
  ]

  tags = {
    Purpose = "Azure Subscription Reference"
  }
}

# Key Vault Alerts
resource "azurerm_monitor_metric_alert" "key_vault_availability" {
  name                = "${azurerm_key_vault.aiops.name}-availability-alert"
  resource_group_name = azurerm_resource_group.aiops.name
  scopes              = [azurerm_key_vault.aiops.id]
  description         = "Alert when Key Vault availability drops below 99%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  tags = local.common_tags
}
