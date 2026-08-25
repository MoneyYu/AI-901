###############################################################################
# AI-901 - Introduction to AI in Azure
# Backup / fallback demo environment (deployed, demo-ready end state).
#
# In class the trainer builds everything live from scratch; this stack is the
# fallback that stands up a completed Microsoft Foundry environment (resources
# AND data plane) so every module demo shows real results immediately.
#
# Providers and core scaffolding live here; all resources live in MOD.tf and
# outputs in OUTPUT.tf. Data-plane automation (sample-data upload + a Content
# Understanding analyzer) is wired via terraform_data in MOD.tf and implemented
# by the PowerShell scripts in ./scripts.
#
# Pattern mirrors MoneyYu/AI-3008 (azurerm ~>4.x Foundry surface, AAD-only).
###############################################################################

terraform {
  required_version = ">=1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 4.x is required for the modern Foundry surface:
      # azurerm_cognitive_account.project_management_enabled and
      # azurerm_cognitive_account_project.
      version = "~>4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}

provider "azurerm" {
  # Company policy forbids storage account access keys - use Entra ID (AAD)
  # for all storage data-plane operations.
  storage_use_azuread = true

  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

###############################################################################
# Variables
###############################################################################

variable "group_postfix" {
  description = "Unique suffix for the class/instance (keeps resource names unique). Lowercase letters and digits only, max 10 chars (storage account names allow nothing else)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.group_postfix))
    error_message = "group_postfix must be 1-10 lowercase letters/digits only (no hyphens, underscores, or uppercase) so the storage account name stays valid (<=24 chars, lowercase alphanumeric)."
  }
}

variable "model_profile" {
  description = "Chat model profile. current preserves gpt-5.4-mini 2026-03-17 (GA, retires 2027-09-21); parity matches the upstream lab with gpt-5-mini 2025-08-07 (GA, retires 2027-02-09)."
  type        = string
  default     = "current"

  validation {
    condition     = contains(["parity", "current"], var.model_profile)
    error_message = "model_profile must be either \"parity\" or \"current\"."
  }
}

# Token-based model capacities (thousands of tokens per minute). Adjust to the
# quota available in your subscription/region before apply.
variable "chat_capacity" {
  description = "Capacity for the selected chat/agents/vision/text deployment."
  type        = number
  default     = 30
}

variable "cu_completion_capacity" {
  description = "Capacity for the gpt-5.2 completion deployment used by Content Understanding."
  type        = number
  default     = 10
}

variable "embedding_capacity" {
  description = "Capacity for the text-embedding-3-large deployment (Content Understanding)."
  type        = number
  default     = 30
}

# Image generation (module 5). gpt-image-2 is GA (no access registration), so
# it can be deployed by Terraform. Gated by a toggle and parameterized so you
# can disable it or swap to a model you have quota for.
variable "enable_image_generation" {
  description = "Deploy a GA image-generation model (gpt-image-2) for the module 5 image-generation demo. Disable if your subscription lacks image quota in the region."
  type        = bool
  default     = true
}

variable "image_model_name" {
  description = "Image-generation model to deploy (module 5). Default gpt-image-2 (GA)."
  type        = string
  default     = "gpt-image-2"
}

variable "image_model_version" {
  description = "Version for image_model_name. Must match the model."
  type        = string
  default     = "2026-04-21"
}

variable "image_capacity" {
  description = "Capacity for the image-generation deployment (requests per minute for image models, which use a small per-region quota)."
  type        = number
  default     = 1
}

variable "deployer_object_id" {
  description = "Entra object ID that the data-plane scripts authenticate as (the `az login` identity). Defaults to the identity Terraform runs as. Override when Terraform runs under a different principal (e.g. a service principal) than `az`."
  type        = string
  default     = null
}

# Toggle the data-plane automation (sample-data upload + CU analyzer).
# Requires the PowerShell scripts and an authenticated `az` session.
variable "enable_data_plane" {
  description = "Run the PowerShell data-plane scripts after the resources are created."
  type        = bool
  default     = true
}

###############################################################################
# Locals
###############################################################################

locals {
  group_name       = "AI901-${var.group_postfix}"
  class_name       = "ai901"
  group_name_lower = lower(local.group_name)
  location         = "eastus2"
  # Suffix used in resource names. Fixed by default for predictable, stable
  # names. To use a fresh dynamic suffix instead (e.g. to avoid the ~48h
  # soft-delete name reservation on Cognitive accounts after a destroy/
  # recreate), change this one line to: random_str = random_string.rid.result
  random_str = "fnd"
  # Entra object ID that the data-plane scripts authenticate as (the `az`
  # identity). Defaults to the identity Terraform runs as.
  deployer_oid = coalesce(var.deployer_object_id, data.azurerm_client_config.current.object_id)
  fixed_models = {
    cu_completion = {
      name    = "gpt-5.2"
      version = "2025-12-11"
    }
    embedding = {
      name    = "text-embedding-3-large"
      version = "1"
    }
  }
  image_model = {
    name    = var.image_model_name
    version = var.image_model_version
  }
  model_profiles = {
    parity = {
      chat = {
        name    = "gpt-5-mini"
        version = "2025-08-07"
      }
      cu_completion = local.fixed_models.cu_completion
      embedding     = local.fixed_models.embedding
      image         = local.image_model
    }
    current = {
      chat = {
        name    = "gpt-5.4-mini"
        version = "2026-03-17"
      }
      cu_completion = local.fixed_models.cu_completion
      embedding     = local.fixed_models.embedding
      image         = local.image_model
    }
  }
  models = local.model_profiles[var.model_profile]

  # Shared tags applied to every taggable resource. SecurityControl = "Ignore"
  # exempts these lab/demo resources from security/CSPM policy.
  default_tags = {
    environment     = local.group_name
    SecurityControl = "Ignore"
  }
}

data "azurerm_client_config" "current" {}

# Dynamic random suffix. Kept available so you can switch resource naming from
# the fixed local.random_str to this (random_string.rid.result) when needed.
resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

###############################################################################
# Resource groups
###############################################################################

# Main resource group that holds the demo-ready backup environment.
resource "azurerm_resource_group" "rg" {
  name     = local.group_name
  location = local.location

  tags = local.default_tags
}

# Empty "Demo" resource group used when the trainer builds everything live
# from scratch during class.
resource "azurerm_resource_group" "demo_rg" {
  name     = "Demo${var.group_postfix}"
  location = local.location

  tags = local.default_tags
}
