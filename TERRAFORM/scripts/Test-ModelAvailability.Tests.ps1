#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Test-ModelAvailability.ps1"

function Assert-Equal {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)][string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

$catalog = @(
    [pscustomobject]@{
        kind  = 'AIServices'
        model = [pscustomobject]@{
            name            = 'gpt-5.4-mini'
            version         = '2026-03-17'
            lifecycleStatus = 'GenerallyAvailable'
            skus            = @(
                [pscustomobject]@{
                    name            = 'GlobalStandard'
                    usageName       = 'OpenAI.GlobalStandard.gpt-5.4-mini'
                    deprecationDate = '2027-09-21T00:00:00Z'
                }
            )
        }
    },
    [pscustomobject]@{
        kind  = 'AIServices'
        model = [pscustomobject]@{
            name            = 'sora-2'
            version         = '2025-12-08'
            lifecycleStatus = 'Preview'
            skus            = @(
                [pscustomobject]@{
                    name            = 'GlobalStandard'
                    usageName       = 'OpenAI.GlobalStandard.sora-2'
                    deprecationDate = '2026-09-15T00:00:00Z'
                }
            )
        }
    }
)

$usage = @(
    [pscustomobject]@{
        name         = [pscustomobject]@{ value = 'OpenAI.GlobalStandard.gpt-5.4-mini' }
        currentValue = 100
        limit        = 120
    }
)

$requirements = @(
    [pscustomobject]@{
        name     = 'gpt-5.4-mini'
        version  = '2026-03-17'
        sku      = 'GlobalStandard'
        capacity = 30
    }
)

$existingDeployments = @(
    [pscustomobject]@{
        name       = 'gpt-5.4-mini'
        modelName  = 'gpt-5.4-mini'
        modelVersion = '2026-03-17'
        skuName    = 'GlobalStandard'
        capacity   = 30
    }
)

$failures = Get-PreflightFailures `
    -Requirements $requirements `
    -Catalog $catalog `
    -Usage $usage `
    -ExistingDeployments $existingDeployments `
    -AsOf ([datetimeoffset]'2026-08-26T00:00:00Z') `
    -NearRetirementDays 90

Assert-Equal -Actual $failures.Count -Expected 0 `
    -Message 'An existing deployment must reduce the required quota by its current capacity.'

$unrelatedDeploymentFailures = Get-PreflightFailures `
    -Requirements $requirements `
    -Catalog $catalog `
    -Usage $usage `
    -ExistingDeployments @(
        [pscustomobject]@{
            name         = 'unrelated-gpt-deployment'
            modelName    = 'gpt-5.4-mini'
            modelVersion = '2026-03-17'
            skuName      = 'GlobalStandard'
            capacity     = 30
        }
    ) `
    -AsOf ([datetimeoffset]'2026-08-26T00:00:00Z') `
    -NearRetirementDays 90

Assert-Equal -Actual $unrelatedDeploymentFailures.Count -Expected 1 `
    -Message 'A same-model deployment with a different deployment name must not offset this stack deployment quota.'

$previewFailures = Get-PreflightFailures `
    -Requirements @(
        [pscustomobject]@{
            name     = 'sora-2'
            version  = '2025-12-08'
            sku      = 'GlobalStandard'
            capacity = 1
        }
    ) `
    -Catalog $catalog `
    -Usage @() `
    -ExistingDeployments @() `
    -AsOf ([datetimeoffset]'2026-08-26T00:00:00Z') `
    -NearRetirementDays 90

Assert-Equal -Actual $previewFailures.Count -Expected 1 `
    -Message 'Preview models must fail the GA requirement.'

Assert-Equal -Actual $previewFailures[0] -Expected `
    'sora-2 2025-12-08: lifecycle is Preview, but GenerallyAvailable is required.' `
    -Message 'The preview failure must identify the lifecycle violation.'

$locationOutput = & pwsh -NoProfile -Command "function az { throw 'AZ_CALLED' }; & '$PSScriptRoot/Test-ModelAvailability.ps1' -Location westus3" 2>&1
if ("$locationOutput" -notmatch 'does not belong to the set|ValidateSet') {
    throw 'The preflight must reject a location that Terraform cannot deploy to before it calls Azure CLI.'
}

Write-Host 'PASS: Test-ModelAvailability.Tests.ps1'
