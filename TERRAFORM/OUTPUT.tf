###############################################################################
# AI-901 - Outputs (endpoints, names).
# No secrets are emitted (the environment is Entra ID / AAD only).
###############################################################################

output "resource_group_name" {
  description = "Main resource group for the demo environment."
  value       = azurerm_resource_group.rg.name
}

output "location" {
  value = local.location
}

# --- Microsoft Foundry (AI Services) -----------------------------------------
output "foundry_name" {
  value = azurerm_cognitive_account.foundry.name
}

output "foundry_endpoint" {
  description = "Endpoint used for Azure OpenAI, Language, Speech, Vision, and Content Understanding calls (AAD auth)."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "foundry_project_name" {
  value = azurerm_cognitive_account_project.project.name
}

# --- Model deployments -------------------------------------------------------
output "chat_deployment" {
  description = "gpt-4.1-mini deployment (chat / agents / vision / text)."
  value       = azurerm_cognitive_deployment.gpt.name
}

output "cu_completion_deployment" {
  description = "gpt-4.1 deployment used by Content Understanding."
  value       = azurerm_cognitive_deployment.cu_completion.name
}

output "embedding_deployment" {
  value = azurerm_cognitive_deployment.embedding.name
}

output "image_deployment" {
  description = "Image-generation deployment (module 5), if enabled."
  value       = var.enable_image_generation ? azurerm_cognitive_deployment.image[0].name : null
}

output "video_deployment" {
  description = "Video-generation deployment (module 5), if enabled (Preview)."
  value       = var.enable_video_generation ? azurerm_cognitive_deployment.video[0].name : null
}

# --- Storage -----------------------------------------------------------------
output "storage_account_name" {
  value = azurerm_storage_account.default.name
}

# --- Content Understanding analyzer ------------------------------------------
output "cu_analyzer_id" {
  description = "Custom Content Understanding analyzer created by the data plane."
  value       = local.cu_analyzer_id
}
