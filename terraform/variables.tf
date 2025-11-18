# Input Variables for AI-Ops Infrastructure

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "centralus",
      "northcentralus", "southcentralus", "westcentralus",
      "canadacentral", "canadaeast",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "australiaeast", "australiasoutheast",
      "southeastasia", "eastasia"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group for AI-Ops resources"
  type        = string
  default     = "rg-aiops-test"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.\\(\\)]+$", var.resource_group_name))
    error_message = "Resource group name can only contain alphanumeric characters, hyphens, underscores, periods, and parentheses."
  }
}

variable "service_principal_id" {
  description = "Service principal client ID (application ID)"
  type        = string
}

variable "certificate_path" {
  description = "Path to the service principal certificate PEM file"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "test"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "enable_auto_shutdown" {
  description = "Enable auto-shutdown for VMs (cost optimization)"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time to auto-shutdown VMs (24-hour format, e.g., 1900 for 7 PM)"
  type        = string
  default     = "1900"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Auto shutdown time must be in 24-hour format (HHMM)."
  }
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown (e.g., Eastern Standard Time)"
  type        = string
  default     = "Eastern Standard Time"
}

variable "vm_size" {
  description = "Size of the test VM"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the test VM"
  type        = string
  default     = "azureadmin"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD for cost alerts"
  type        = number
  default     = 50

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "budget_notification_threshold" {
  description = "Percentage of budget to trigger notification (e.g., 80 for 80%)"
  type        = number
  default     = 80

  validation {
    condition     = var.budget_notification_threshold > 0 && var.budget_notification_threshold <= 100
    error_message = "Budget notification threshold must be between 0 and 100."
  }
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access resources (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change to your IP for production

  validation {
    condition     = alltrue([for ip in var.allowed_ip_ranges : can(cidrhost(ip, 0))])
    error_message = "All IP ranges must be in valid CIDR notation."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
