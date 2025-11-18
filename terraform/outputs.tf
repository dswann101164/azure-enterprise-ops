# Output Values for AI-Ops Infrastructure

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aiops.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.aiops.id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.aiops.location
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.aiops.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.aiops.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.aiops.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.aiops.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.aiops.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.aiops.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.aiops.id
}

output "subnet_id" {
  description = "ID of the default subnet"
  value       = azurerm_subnet.default.id
}

output "test_vm_name" {
  description = "Name of the test VM"
  value       = azurerm_linux_virtual_machine.test.name
}

output "test_vm_id" {
  description = "ID of the test VM"
  value       = azurerm_linux_virtual_machine.test.id
}

output "test_vm_private_ip" {
  description = "Private IP address of the test VM"
  value       = azurerm_network_interface.test.private_ip_address
}

output "test_vm_public_ip" {
  description = "Public IP address of the test VM (if enabled)"
  value       = azurerm_public_ip.test.ip_address
}

output "service_principal_id" {
  description = "Service principal client ID"
  value       = var.service_principal_id
  sensitive   = true
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group    = azurerm_resource_group.aiops.name
    location         = azurerm_resource_group.aiops.location
    key_vault        = azurerm_key_vault.aiops.name
    storage_account  = azurerm_storage_account.aiops.name
    virtual_network  = azurerm_virtual_network.aiops.name
    test_vm          = azurerm_linux_virtual_machine.test.name
    vm_auto_shutdown = var.enable_auto_shutdown
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    Deployment Complete!
    
    Next Steps:
    1. Test Azure CLI authentication:
       az account show
    
    2. Access Key Vault:
       az keyvault secret list --vault-name ${azurerm_key_vault.aiops.name}
    
    3. Connect to test VM:
       az vm show -g ${azurerm_resource_group.aiops.name} -n ${azurerm_linux_virtual_machine.test.name}
    
    4. Configure Claude Desktop with MCP servers
    
    5. Test AI-assisted operations:
       - Query resources
       - Analyze costs
       - Review security configurations
    
    Resources:
    - Resource Group: ${azurerm_resource_group.aiops.name}
    - Key Vault: ${azurerm_key_vault.aiops.name}
    - VM: ${azurerm_linux_virtual_machine.test.name}
    
    Documentation: ../docs/
  EOT
}

output "cost_estimate" {
  description = "Estimated monthly cost breakdown"
  value = <<-EOT
    Estimated Monthly Costs:
    - Key Vault: ~$0.03 (per 10k operations)
    - Storage Account (Standard LRS): ~$0.50
    - Virtual Network: Free
    - Public IP (Static): ~$3.00
    - VM (${var.vm_size}): ~$15-30 (with auto-shutdown)
    
    Total Estimated: $20-35/month
    
    Cost Optimization:
    - Auto-shutdown enabled: ${var.enable_auto_shutdown}
    - Shutdown time: ${var.auto_shutdown_time} ${var.auto_shutdown_timezone}
    - Budget alert set: $${var.budget_amount}/month at ${var.budget_notification_threshold}%
    
    Delete resources when not in use:
    terraform destroy
  EOT
}
