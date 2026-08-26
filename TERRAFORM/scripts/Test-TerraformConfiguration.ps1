#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Matches {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

function Assert-DoesNotMatch {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Message
    )

    if ($Text -match $Pattern) {
        throw $Message
    }
}

$terraformRoot = Split-Path $PSScriptRoot -Parent
$main = Get-Content -Raw (Join-Path $terraformRoot 'MAIN.tf')
$mod = Get-Content -Raw (Join-Path $terraformRoot 'MOD.tf')
$outputs = Get-Content -Raw (Join-Path $terraformRoot 'OUTPUT.tf')

Assert-Matches -Text $main -Pattern '(?s)variable "model_profile".*?default\s*=\s*"current"' `
    -Message 'model_profile must default to current.'

Assert-Matches -Text $main -Pattern '(?s)model_profiles\s*=\s*\{.*?parity\s*=\s*\{.*?gpt-5-mini.*?current\s*=\s*\{.*?gpt-5\.4-mini' `
    -Message 'model_profiles must provide parity gpt-5-mini and current gpt-5.4-mini.'

Assert-Matches -Text $mod -Pattern '(?s)resource "azurerm_cognitive_deployment" "gpt"\s*\{.*?depends_on\s*=\s*\[\s*azurerm_cognitive_account_project\.project\s*\]' `
    -Message 'The first deployment must explicitly depend on the Foundry project.'

Assert-DoesNotMatch -Text $mod -Pattern 'resource "azurerm_cognitive_deployment" "video"' `
    -Message 'The retired Preview video deployment must be removed.'

Assert-DoesNotMatch -Text $main -Pattern 'variable "enable_video_generation"|variable "video_model_name"|variable "video_model_version"|variable "video_capacity"' `
    -Message 'Retired video toggle variables must be removed.'

Assert-DoesNotMatch -Text $outputs -Pattern 'output "video_deployment"' `
    -Message 'The retired video output must be removed.'

Write-Host 'PASS: Test-TerraformConfiguration.ps1'
