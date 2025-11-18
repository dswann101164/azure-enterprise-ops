# Terraform configuration for AI-Assisted Azure Operations
# Author: David Swann | azure-noob.com
# Version: 1.0.0

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }

  # Optional: Configure backend for state management
  # Uncomment and configure for production use
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstate"
  #   container_name       = "tfstate"
  #   key                  = "aiops.terraform.tfstate"
  # }
}

# Resource Group for AI Operations Test Environment
resource "azurerm_resource_group" "aiops" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Test"
    Project     = "AI-Ops"
    ManagedBy   = "Terraform"
    Purpose     = "AI-Assisted Azure Operations Lab"
    CostCenter  = "Lab"
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Tags to be applied to all resources
locals {
  common_tags = {
    Environment = "Test"
    Project     = "AI-Ops"
    ManagedBy   = "Terraform"
    DeployedBy  = "Deploy-AIOps.ps1"
    Repository  = "ai-ops2"
  }

  # Naming convention
  prefix = "aiops"
  suffix = random_string.suffix.result
}
