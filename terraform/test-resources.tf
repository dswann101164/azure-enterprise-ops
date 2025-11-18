# Test Resources for AI-Ops Lab Environment
# Creates safe, low-cost resources for experimentation

# Storage Account for logs and diagnostics
resource "azurerm_storage_account" "aiops" {
  name                     = "${local.prefix}st${local.suffix}"
  resource_group_name      = azurerm_resource_group.aiops.name
  location                 = azurerm_resource_group.aiops.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  
  # Security
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  # Network
  public_network_access_enabled   = true
  
  # Blob properties
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Storage"
      Purpose      = "Diagnostics and Logs"
    }
  )
}

# Storage container for VM diagnostics
resource "azurerm_storage_container" "diagnostics" {
  name                  = "vm-diagnostics"
  storage_account_name  = azurerm_storage_account.aiops.name
  container_access_type = "private"
}

# Virtual Network
resource "azurerm_virtual_network" "aiops" {
  name                = "${local.prefix}-vnet-${local.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Networking"
      Purpose      = "Test Environment Network"
    }
  )
}

# Default subnet
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.aiops.name
  virtual_network_name = azurerm_virtual_network.aiops.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "aiops" {
  name                = "${local.prefix}-nsg-${local.suffix}"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name

  # Allow SSH from specified IP ranges
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  # Allow HTTPS outbound
  security_rule {
    name                       = "AllowHTTPSOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Security"
      Purpose      = "Network Security Rules"
    }
  )
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.aiops.id
}

# Public IP for test VM
resource "azurerm_public_ip" "test" {
  name                = "${local.prefix}-vm-pip-${local.suffix}"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Networking"
      Purpose      = "VM Public Access"
    }
  )
}

# Network Interface for test VM
resource "azurerm_network_interface" "test" {
  name                = "${local.prefix}-vm-nic-${local.suffix}"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test.id
  }

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Networking"
      Purpose      = "VM Network Interface"
    }
  )
}

# SSH Key for VM
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Linux Virtual Machine for testing
resource "azurerm_linux_virtual_machine" "test" {
  name                = "${local.prefix}-vm-${local.suffix}"
  resource_group_name = azurerm_resource_group.aiops.name
  location            = azurerm_resource_group.aiops.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Authentication
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.test.id,
  ]

  os_disk {
    name                 = "${local.prefix}-vm-osdisk-${local.suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.aiops.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags,
    {
      ResourceType  = "Compute"
      Purpose       = "Test Virtual Machine"
      OS            = "Ubuntu 22.04 LTS"
      AutoShutdown  = var.enable_auto_shutdown ? "Enabled" : "Disabled"
    }
  )
}

# Store SSH private key in Key Vault
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "vm-ssh-private-key"
  value        = tls_private_key.ssh.private_key_pem
  key_vault_id = azurerm_key_vault.aiops.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets
  ]

  tags = {
    Purpose = "VM SSH Authentication"
  }
}

# Auto-shutdown schedule for cost optimization
resource "azurerm_dev_test_global_vm_shutdown_schedule" "test" {
  count              = var.enable_auto_shutdown ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.test.id
  location           = azurerm_resource_group.aiops.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

# Budget alert for cost management
resource "azurerm_consumption_budget_resource_group" "aiops" {
  name              = "${local.prefix}-budget"
  resource_group_id = azurerm_resource_group.aiops.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00Z", timeadd(timestamp(), "8760h"))
  }

  notification {
    enabled   = true
    threshold = var.budget_notification_threshold
    operator  = "GreaterThan"

    contact_emails = []
  }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "aiops" {
  name                = "${local.prefix}-law-${local.suffix}"
  location            = azurerm_resource_group.aiops.location
  resource_group_name = azurerm_resource_group.aiops.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    local.common_tags,
    {
      ResourceType = "Monitoring"
      Purpose      = "Centralized Logging"
    }
  )
}

# VM Insights
resource "azurerm_monitor_diagnostic_setting" "vm" {
  name                       = "vm-diagnostics"
  target_resource_id         = azurerm_linux_virtual_machine.test.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aiops.id

  enabled_log {
    category = "Administrative"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Action Group for alerts (optional)
resource "azurerm_monitor_action_group" "aiops" {
  name                = "${local.prefix}-alerts"
  resource_group_name = azurerm_resource_group.aiops.name
  short_name          = "aiops"

  tags = local.common_tags
}

# Sample data disk (optional, uncomment if needed)
# resource "azurerm_managed_disk" "data" {
#   name                 = "${local.prefix}-vm-datadisk-${local.suffix}"
#   location             = azurerm_resource_group.aiops.location
#   resource_group_name  = azurerm_resource_group.aiops.name
#   storage_account_type = "Standard_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = 32
#
#   tags = merge(
#     local.common_tags,
#     {
#       ResourceType = "Storage"
#       Purpose      = "VM Data Disk"
#     }
#   )
# }
