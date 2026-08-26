###############################################################################
# AI-901 - Resources for the "Introduction to AI in Azure" demos.
#
# A single Microsoft Foundry (kind = AIServices) account hosts everything the
# course demos: Azure OpenAI model deployments (chat / agents / vision / text),
# Azure AI Language, Azure AI Speech, Azure AI Vision, and Azure Content
# Understanding. The trainer creates agents live in the portal; this stack
# deploys the models and a Content Understanding analyzer so module demos
# return real results immediately.
#
# Model selection is validated against the Foundry model retirement schedule
# (https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule).
# See README for the full table.
###############################################################################

###############################################################################
# Storage - holds the sample data used by the Content Understanding and vision
# demos.
#
# Company policy forbids storage account access keys, so the account is
# Entra ID (AAD) only: shared_access_key_enabled = false, containers are
# created via the management plane (storage_account_id), and every principal
# that touches blob data gets an explicit RBAC role (below). The upload script
# uses `az ... --auth-mode login` (AAD), never a key.
###############################################################################
resource "azurerm_storage_account" "default" {
  name                            = "${local.class_name}${var.group_postfix}st${local.random_str}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  # Company policy forbids access keys - enforce Entra ID (AAD) auth only.
  shared_access_key_enabled = false

  tags = local.default_tags
}

# Sample documents for the Content Understanding analyzer demo (module 6).
# Containers use storage_account_id (management plane) so they can be created
# without storage data-plane keys (which policy forbids).
resource "azurerm_storage_container" "documents" {
  name                  = "sample-documents"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

# Sample images for the computer-vision / multimodal demos (module 5).
resource "azurerm_storage_container" "images" {
  name                  = "sample-images"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

###############################################################################
# Role assignment for Entra ID (AAD) blob data access.
# Because access keys are disabled, the principal running Terraform (and the
# data-plane upload script) needs an explicit RBAC role to read/write blobs.
###############################################################################
resource "azurerm_role_assignment" "deployer_blob" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.deployer_oid
}

###############################################################################
# Microsoft Foundry account + project.
# kind = AIServices with project management enabled gives one multi-service
# resource that hosts Azure OpenAI model deployments AND Azure AI Language,
# Speech, Vision, and Content Understanding.
# Pattern follows the official docs:
# https://learn.microsoft.com/azure/foundry/how-to/create-resource-terraform
###############################################################################
resource "azurerm_cognitive_account" "foundry" {
  name                  = "${local.group_name_lower}-foundry-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = "${local.group_name_lower}-foundry-${local.random_str}"

  # Company policy enforces Entra ID (AAD) auth only - keys are disabled.
  # AAD auth requires a custom subdomain (regional endpoints reject AAD tokens).
  local_auth_enabled = false

  # Required for the modern Foundry (stateful) experience and projects.
  project_management_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.default_tags
}

# The principal running the Content Understanding data-plane script needs to
# call the AI Services data plane via AAD.
resource "azurerm_role_assignment" "deployer_cs_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = local.deployer_oid
}

# Azure allows only one Cognitive Services account child write at a time.
# azurerm 4.x deployment resources lock the parent account, but
# azurerm_cognitive_account_project lacked that lock through v4.81, so the
# first deployment must explicitly depend on the project. These provider locks
# and Terraform depends_on edges coordinate only within a single apply; they do
# not protect concurrent portal, Azure CLI, or other pipeline writes.
# Microsoft.Authorization role assignments remain parallel.
resource "azurerm_cognitive_account_project" "project" {
  name                 = "${local.group_name_lower}-project"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.default_tags
}

###############################################################################
# Model deployments.
# Deployments are created one at a time (depends_on chain) because the
# Cognitive Services control plane rejects parallel deployment writes.
# Deployment name == model name so the Content Understanding default mapping
# is an identity map.
#
# Versions are pinned to CU-supported / GA versions (checked 2026-08-26) and
# set to NoAutoUpgrade so the pin holds. Re-check the retirement schedule
# before each delivery and bump as needed:
# https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule
###############################################################################

# Primary model: chat, agents, text analysis (general-purpose), and vision.
# Used across modules 1, 2, 3, and 5. The current profile preserves
# gpt-5.4-mini 2026-03-17 (GA, retires 2027-09-21); parity switches only this
# deployment to gpt-5-mini 2025-08-07 (GA, retires 2027-02-09) to match the
# upstream lab.
resource "azurerm_cognitive_deployment" "gpt" {
  name                   = local.models.chat.name
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "NoAutoUpgrade"

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.chat.name
    version = local.models.chat.version
  }

  depends_on = [azurerm_cognitive_account_project.project]
}

# Completion model for Content Understanding (module 6). CU supports a fixed
# set of completion models; the gpt-4.1 family is Legacy (retires
# 2027-04-14), so gpt-5.2 is the non-Legacy CU completion model used here.
# GA, retires 2027-06-08 - re-check before each delivery.
resource "azurerm_cognitive_deployment" "cu_completion" {
  name                   = local.models.cu_completion.name
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "NoAutoUpgrade"

  sku {
    name     = "GlobalStandard"
    capacity = var.cu_completion_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.cu_completion.name
    version = local.models.cu_completion.version
  }

  depends_on = [azurerm_cognitive_deployment.gpt]
}

# Embedding model required by Content Understanding analyzers (module 6).
# text-embedding-3-large version 1 is GA and retires 2028-02-09.
resource "azurerm_cognitive_deployment" "embedding" {
  name                   = local.models.embedding.name
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "NoAutoUpgrade"

  sku {
    name     = "Standard"
    capacity = var.embedding_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.embedding.name
    version = local.models.embedding.version
  }

  depends_on = [azurerm_cognitive_deployment.cu_completion]
}

# Image-generation model (module 5). GA models such as gpt-image-2 deploy
# without access registration; this stays toggle-gated and parameterized so you
# can disable it or swap to a model you have quota for. Placed last in the
# depends_on chain (the control plane rejects parallel deployment writes).
resource "azurerm_cognitive_deployment" "image" {
  count                  = var.enable_image_generation ? 1 : 0
  name                   = local.models.image.name
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "NoAutoUpgrade"

  sku {
    name     = "GlobalStandard"
    capacity = var.image_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.image.name
    version = local.models.image.version
  }

  depends_on = [azurerm_cognitive_deployment.embedding]
}

###############################################################################
# Data-plane automation.
# Brings the environment to a "completed" demo-ready state:
#   1. upload sample data to blob storage (AAD auth)
#   2. create a Content Understanding analyzer over the sample documents
#
# Each step runs a PowerShell script (PowerShell 7 + az CLI). Requires an
# authenticated `az` session. Gated by var.enable_data_plane.
###############################################################################

locals {
  pwsh           = "pwsh"
  pwsh_args      = ["-NoProfile", "-File"]
  scripts_dir    = "${path.module}/scripts"
  sampledata_dir = "${path.module}/sample-data"
  cu_analyzer_id = "ai901receiptanalyzer"
}

resource "terraform_data" "upload_sample_data" {
  count = var.enable_data_plane ? 1 : 0

  triggers_replace = [
    azurerm_storage_account.default.id,
    filesha256("${local.scripts_dir}/upload-sample-data.ps1"),
  ]

  depends_on = [
    azurerm_storage_container.documents,
    azurerm_storage_container.images,
    azurerm_role_assignment.deployer_blob,
  ]

  provisioner "local-exec" {
    interpreter = concat([local.pwsh], local.pwsh_args)
    command     = "${local.scripts_dir}/upload-sample-data.ps1"

    environment = {
      STORAGE_ACCOUNT  = azurerm_storage_account.default.name
      SAMPLE_DATA_PATH = local.sampledata_dir
    }
  }
}

resource "terraform_data" "create_cu_analyzer" {
  count = var.enable_data_plane ? 1 : 0

  triggers_replace = [
    azurerm_cognitive_account.foundry.id,
    azurerm_cognitive_deployment.cu_completion.name,
    azurerm_cognitive_deployment.embedding.name,
    filesha256("${local.scripts_dir}/create-cu-analyzer.ps1"),
  ]

  depends_on = [
    terraform_data.upload_sample_data,
    azurerm_cognitive_deployment.cu_completion,
    azurerm_cognitive_deployment.embedding,
    azurerm_role_assignment.deployer_cs_user,
  ]

  provisioner "local-exec" {
    interpreter = concat([local.pwsh], local.pwsh_args)
    command     = "${local.scripts_dir}/create-cu-analyzer.ps1"

    environment = {
      CU_ENDPOINT           = azurerm_cognitive_account.foundry.endpoint
      ANALYZER_ID           = local.cu_analyzer_id
      COMPLETION_DEPLOYMENT = azurerm_cognitive_deployment.cu_completion.name
      EMBEDDING_DEPLOYMENT  = azurerm_cognitive_deployment.embedding.name
    }
  }
}
