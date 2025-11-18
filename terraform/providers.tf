# Azure Provider Configuration
# Authenticates using Azure CLI by default
# Can also use service principal with certificate

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Uncomment to use service principal authentication
  # client_id                  = var.service_principal_id
  # client_certificate_path    = var.certificate_path
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}
