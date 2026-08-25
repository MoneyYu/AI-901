#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('eastus2')]
    [string]$Location = 'eastus2',

    [Parameter()]
    [ValidateSet('parity', 'current')]
    [string]$ModelProfile = 'current',

    [Parameter()]
    [bool]$EnableImageGeneration = $true,

    [Parameter()]
    [ValidateRange(0, 1000000)]
    [int]$ChatCapacity = 30,

    [Parameter()]
    [ValidateRange(0, 1000000)]
    [int]$CuCompletionCapacity = 10,

    [Parameter()]
    [ValidateRange(0, 1000000)]
    [int]$EmbeddingCapacity = 30,

    [Parameter()]
    [string]$ImageModelName = 'gpt-image-2',

    [Parameter()]
    [string]$ImageModelVersion = '2026-04-21',

    [Parameter()]
    [ValidateRange(0, 1000000)]
    [int]$ImageCapacity = 1,

    [Parameter()]
    [string]$TargetResourceGroupName,

    [Parameter()]
    [string]$TargetAccountName,

    [Parameter()]
    [datetimeoffset]$AsOf = [datetimeoffset]::UtcNow,

    [Parameter()]
    [ValidateRange(0, 3650)]
    [int]$NearRetirementDays = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:IsDotSourced = $MyInvocation.InvocationName -eq '.'

# Keep these CLI defaults, model profiles, and derived requirement definitions
# synchronized with TERRAFORM\MAIN.tf and TERRAFORM\MOD.tf.
$script:ModelProfiles = [ordered]@{
    parity = [pscustomobject]@{
        Name    = 'gpt-5-mini'
        Version = '2025-08-07'
    }
    current = [pscustomobject]@{
        Name    = 'gpt-5.4-mini'
        Version = '2026-03-17'
    }
}

function Get-NestedPropertyValue {
    param(
        [Parameter(Mandatory)]
        $InputObject,

        [Parameter(Mandatory)]
        [string[]]$Path
    )

    $current = $InputObject
    foreach ($segment in $Path) {
        if ($null -eq $current) {
            return $null
        }

        if ($current -is [System.Collections.IDictionary]) {
            if (-not $current.Contains($segment)) {
                return $null
            }

            $current = $current[$segment]
            continue
        }

        $property = $current.PSObject.Properties[$segment]
        if ($null -eq $property) {
            return $null
        }

        $current = $property.Value
    }

    return $current
}

function Get-Collection {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        return @($Value)
    }

    return @($Value)
}

function Get-DisplayValue {
    param($Value)

    if ($null -eq $Value) {
        return '<missing>'
    }

    $text = "$Value"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return '<missing>'
    }

    return $text
}

function Try-ConvertToDouble {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    $number = 0.0
    if ([double]::TryParse(
            "$Value",
            [System.Globalization.NumberStyles]::Float -bor [System.Globalization.NumberStyles]::AllowThousands,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$number)) {
        return $number
    }

    return $null
}

function Try-ConvertToDateTimeOffset {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [datetimeoffset]) {
        return $Value
    }

    if ($Value -is [datetime]) {
        return [datetimeoffset]$Value
    }

    $parsed = [datetimeoffset]::MinValue
    if ([datetimeoffset]::TryParse(
            "$Value",
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Get-UsageBucketName {
    param(
        [Parameter(Mandatory)]
        $UsageEntry
    )

    foreach ($path in @(
            @('name', 'value'),
            @('name'),
            @('usageName')
        )) {
        $value = Get-NestedPropertyValue -InputObject $UsageEntry -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$value")) {
            return "$value"
        }
    }

    return $null
}

function Get-NormalizedRequirement {
    param(
        [Parameter(Mandatory)]
        $Requirement
    )

    $modelName = $null
    foreach ($path in @(
            @('modelName'),
            @('name'),
            @('model', 'name')
        )) {
        $modelName = Get-NestedPropertyValue -InputObject $Requirement -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$modelName")) {
            break
        }
    }

    $deploymentName = $null
    foreach ($path in @(
            @('deploymentName'),
            @('deployment'),
            @('targetDeploymentName')
        )) {
        $deploymentName = Get-NestedPropertyValue -InputObject $Requirement -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$deploymentName")) {
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace("$deploymentName")) {
        $deploymentName = $modelName
    }

    $modelVersion = $null
    foreach ($path in @(
            @('modelVersion'),
            @('version'),
            @('model', 'version')
        )) {
        $modelVersion = Get-NestedPropertyValue -InputObject $Requirement -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$modelVersion")) {
            break
        }
    }

    $skuName = $null
    foreach ($path in @(
            @('skuName'),
            @('sku'),
            @('model', 'sku')
        )) {
        $skuName = Get-NestedPropertyValue -InputObject $Requirement -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$skuName")) {
            break
        }
    }

    return [pscustomobject]@{
        DeploymentName = (Get-DisplayValue $deploymentName)
        ModelName      = (Get-DisplayValue $modelName)
        ModelVersion   = (Get-DisplayValue $modelVersion)
        SkuName        = (Get-DisplayValue $skuName)
        Capacity       = (Try-ConvertToDouble (Get-NestedPropertyValue -InputObject $Requirement -Path @('capacity')))
    }
}

function Get-NormalizedExistingDeployment {
    param(
        [Parameter(Mandatory)]
        $Deployment
    )

    $capacityValue = $null
    foreach ($path in @(
            @('capacity'),
            @('sku', 'capacity'),
            @('properties', 'capacity'),
            @('properties', 'sku', 'capacity')
        )) {
        $capacityValue = Get-NestedPropertyValue -InputObject $Deployment -Path $path
        if ($null -ne $capacityValue) {
            break
        }
    }

    $deploymentName = $null
    foreach ($path in @(
            @('deploymentName'),
            @('name'),
            @('properties', 'deploymentName')
        )) {
        $deploymentName = Get-NestedPropertyValue -InputObject $Deployment -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$deploymentName")) {
            break
        }
    }

    $modelName = $null
    foreach ($path in @(
            @('modelName'),
            @('model', 'name'),
            @('properties', 'model', 'name')
        )) {
        $modelName = Get-NestedPropertyValue -InputObject $Deployment -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$modelName")) {
            break
        }
    }

    $modelVersion = $null
    foreach ($path in @(
            @('modelVersion'),
            @('model', 'version'),
            @('properties', 'model', 'version')
        )) {
        $modelVersion = Get-NestedPropertyValue -InputObject $Deployment -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$modelVersion")) {
            break
        }
    }

    $skuName = $null
    foreach ($path in @(
            @('skuName'),
            @('sku', 'name'),
            @('properties', 'sku', 'name')
        )) {
        $skuName = Get-NestedPropertyValue -InputObject $Deployment -Path $path
        if (-not [string]::IsNullOrWhiteSpace("$skuName")) {
            break
        }
    }

    return [pscustomobject]@{
        DeploymentName = (Get-DisplayValue $deploymentName)
        ModelName      = (Get-DisplayValue $modelName)
        ModelVersion   = (Get-DisplayValue $modelVersion)
        SkuName        = (Get-DisplayValue $skuName)
        Capacity       = (Try-ConvertToDouble $capacityValue)
    }
}

function Get-PreflightFailures {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Requirements,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Catalog,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Usage,

        [Parameter()]
        [AllowEmptyCollection()]
        [object[]]$ExistingDeployments = @(),

        [Parameter(Mandatory)]
        [datetimeoffset]$AsOf,

        [Parameter(Mandatory)]
        [int]$NearRetirementDays
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    $validatedRequirements = [System.Collections.Generic.List[object]]::new()

    foreach ($requirement in @($Requirements)) {
        $normalizedRequirement = Get-NormalizedRequirement -Requirement $requirement
        $deploymentName = $normalizedRequirement.DeploymentName
        $name = $normalizedRequirement.ModelName
        $version = $normalizedRequirement.ModelVersion
        $skuName = $normalizedRequirement.SkuName
        $capacity = $normalizedRequirement.Capacity

        if ($null -eq $capacity) {
            $failures.Add(('{0} {1} / {2}: capacity is missing or invalid.' -f $name, $version, $skuName))
            continue
        }

        $matchedEntry = $null
        $matchedModel = $null
        foreach ($entry in @($Catalog)) {
            if ((Get-NestedPropertyValue -InputObject $entry -Path @('kind')) -cne 'AIServices') {
                continue
            }

            $candidateModel = Get-NestedPropertyValue -InputObject $entry -Path @('model')
            if ($null -eq $candidateModel) {
                continue
            }

            $candidateName = Get-NestedPropertyValue -InputObject $candidateModel -Path @('name')
            $candidateVersion = Get-NestedPropertyValue -InputObject $candidateModel -Path @('version')
            if ("$candidateName" -ceq $name -and "$candidateVersion" -ceq $version) {
                $matchedEntry = $entry
                $matchedModel = $candidateModel
                break
            }
        }

        if ($null -eq $matchedEntry) {
            $failures.Add(('{0} {1}: model version is not available in the AIServices catalog.' -f $name, $version))
            continue
        }

        $matchedSku = $null
        foreach ($catalogSku in (Get-Collection (Get-NestedPropertyValue -InputObject $matchedModel -Path @('skus')))) {
            if ($null -eq $catalogSku) {
                continue
            }

            if ("$(Get-NestedPropertyValue -InputObject $catalogSku -Path @('name'))" -ceq $skuName) {
                $matchedSku = $catalogSku
                break
            }
        }

        if ($null -eq $matchedSku) {
            $failures.Add(('{0} {1}: SKU {2} is not available in the AIServices catalog.' -f $name, $version, $skuName))
            continue
        }

        $lifecycleStatus = Get-DisplayValue (Get-NestedPropertyValue -InputObject $matchedModel -Path @('lifecycleStatus'))
        if ($lifecycleStatus -cne 'GenerallyAvailable') {
            $failures.Add(('{0} {1}: lifecycle is {2}, but GenerallyAvailable is required.' -f $name, $version, $lifecycleStatus))
            continue
        }

        $usageName = Get-NestedPropertyValue -InputObject $matchedSku -Path @('usageName')
        if ([string]::IsNullOrWhiteSpace("$usageName")) {
            $failures.Add(('{0} {1} / {2}: usageName is missing from the catalog SKU metadata.' -f $name, $version, $skuName))
            continue
        }

        $deprecationDate = Try-ConvertToDateTimeOffset (Get-NestedPropertyValue -InputObject $matchedSku -Path @('deprecationDate'))
        if ($null -eq $deprecationDate) {
            $failures.Add(('{0} {1} / {2}: deprecationDate is missing or invalid for quota bucket ''{3}''.' -f $name, $version, $skuName, $usageName))
            continue
        }

        if ($deprecationDate -le $AsOf) {
            $failures.Add(('{0} {1} / {2}: model retires on {3}, which is already on or before {4}.' -f $name, $version, $skuName, $deprecationDate.ToString('yyyy-MM-dd'), $AsOf.ToString('yyyy-MM-dd')))
            continue
        }

        $retirementCutoff = $AsOf.AddDays($NearRetirementDays)
        if ($deprecationDate -le $retirementCutoff) {
            $failures.Add(('{0} {1} / {2}: model retires on {3}, within {4} days of {5}.' -f $name, $version, $skuName, $deprecationDate.ToString('yyyy-MM-dd'), $NearRetirementDays, $AsOf.ToString('yyyy-MM-dd')))
            continue
        }

        $validatedRequirements.Add([pscustomobject]@{
                DeploymentName = $deploymentName
                ModelName      = $name
                ModelVersion   = $version
                SkuName        = $skuName
                UsageName      = "$usageName"
                Capacity       = $capacity
            })
    }

    $groupedRequirements = @{}
    foreach ($item in $validatedRequirements) {
        $groupKey = '{0}|{1}|{2}|{3}|{4}' -f $item.DeploymentName, $item.ModelName, $item.ModelVersion, $item.SkuName, $item.UsageName
        if (-not $groupedRequirements.ContainsKey($groupKey)) {
            $groupedRequirements[$groupKey] = [pscustomobject]@{
                DeploymentName = $item.DeploymentName
                ModelName      = $item.ModelName
                ModelVersion   = $item.ModelVersion
                SkuName        = $item.SkuName
                UsageName      = $item.UsageName
                Capacity       = 0.0
            }
        }

        $groupedRequirements[$groupKey].Capacity += $item.Capacity
    }

    $normalizedDeployments = foreach ($deployment in @($ExistingDeployments)) {
        Get-NormalizedExistingDeployment -Deployment $deployment
    }

    $incrementalDemandByBucket = @{}
    foreach ($group in $groupedRequirements.Values) {
        $existingCapacity = 0.0
        foreach ($deployment in $normalizedDeployments) {
            if ($deployment.DeploymentName -ceq $group.DeploymentName -and
                $deployment.ModelName -ceq $group.ModelName -and
                $deployment.ModelVersion -ceq $group.ModelVersion -and
                $deployment.SkuName -ceq $group.SkuName) {
                if ($null -eq $deployment.Capacity) {
                    $failures.Add("$($group.ModelName) $($group.ModelVersion) / $($group.SkuName) deployment '$($group.DeploymentName)': existing deployment capacity is missing or invalid.")
                    continue
                }

                $existingCapacity += $deployment.Capacity
            }
        }

        $incrementalCapacity = [Math]::Max($group.Capacity - $existingCapacity, 0.0)
        if ($incrementalCapacity -le 0.0) {
            continue
        }

        if ($incrementalDemandByBucket.ContainsKey($group.UsageName)) {
            $incrementalDemandByBucket[$group.UsageName] += $incrementalCapacity
        }
        else {
            $incrementalDemandByBucket[$group.UsageName] = $incrementalCapacity
        }
    }

    $usageLookup = @{}
    foreach ($usageEntry in @($Usage)) {
        $bucketName = Get-UsageBucketName -UsageEntry $usageEntry
        if ([string]::IsNullOrWhiteSpace($bucketName)) {
            continue
        }

        if (-not $usageLookup.ContainsKey($bucketName)) {
            $usageLookup[$bucketName] = $usageEntry
        }
    }

    foreach ($usageName in ($incrementalDemandByBucket.Keys | Sort-Object)) {
        if (-not $usageLookup.ContainsKey($usageName)) {
            $failures.Add("Quota bucket '$usageName' is missing from the usage list.")
            continue
        }

        $usageEntry = $usageLookup[$usageName]
        $currentValue = Try-ConvertToDouble (Get-NestedPropertyValue -InputObject $usageEntry -Path @('currentValue'))
        $limitValue = Try-ConvertToDouble (Get-NestedPropertyValue -InputObject $usageEntry -Path @('limit'))

        if ($null -eq $currentValue -or $null -eq $limitValue) {
            $failures.Add("Quota bucket '$usageName' has missing or invalid currentValue/limit data.")
            continue
        }

        $availableCapacity = $limitValue - $currentValue
        $requiredCapacity = $incrementalDemandByBucket[$usageName]
        if ($availableCapacity -lt $requiredCapacity) {
            $failures.Add(
                "Quota bucket '$usageName' needs $([int][Math]::Ceiling($requiredCapacity)) more capacity, but only $([int][Math]::Floor($availableCapacity)) is free ($([int]$currentValue)/$([int]$limitValue) used)."
            )
        }
    }

    return ,$failures.ToArray()
}

function New-Requirement {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Sku,

        [Parameter(Mandatory)]
        [int]$Capacity
    )

    return [pscustomobject]@{
        deploymentName = $Name
        name     = $Name
        version  = $Version
        sku      = $Sku
        capacity = $Capacity
    }
}

function Get-PreflightRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('parity', 'current')]
        [string]$ModelProfile,

        [Parameter(Mandatory)]
        [int]$ChatCapacity,

        [Parameter(Mandatory)]
        [int]$CuCompletionCapacity,

        [Parameter(Mandatory)]
        [int]$EmbeddingCapacity,

        [Parameter(Mandatory)]
        [bool]$EnableImageGeneration,

        [Parameter(Mandatory)]
        [string]$ImageModelName,

        [Parameter(Mandatory)]
        [string]$ImageModelVersion,

        [Parameter(Mandatory)]
        [int]$ImageCapacity
    )

    if (-not $script:ModelProfiles.Contains($ModelProfile)) {
        throw "Unknown model profile '$ModelProfile'."
    }

    $profile = $script:ModelProfiles[$ModelProfile]
    $requirements = [System.Collections.Generic.List[object]]::new()
    $requirements.Add((New-Requirement -Name $profile.Name -Version $profile.Version -Sku 'GlobalStandard' -Capacity $ChatCapacity))
    $requirements.Add((New-Requirement -Name 'gpt-5.2' -Version '2025-12-11' -Sku 'GlobalStandard' -Capacity $CuCompletionCapacity))
    $requirements.Add((New-Requirement -Name 'text-embedding-3-large' -Version '1' -Sku 'Standard' -Capacity $EmbeddingCapacity))

    if ($EnableImageGeneration) {
        $requirements.Add((New-Requirement -Name $ImageModelName -Version $ImageModelVersion -Sku 'GlobalStandard' -Capacity $ImageCapacity))
    }

    return ,$requirements.ToArray()
}

function Invoke-AzJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed: az $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }

    $json = $output -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($json)) {
        return $null
    }

    return $json | ConvertFrom-Json -Depth 100
}

function Invoke-ModelAvailabilityPreflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('eastus2')]
        [string]$Location,

        [Parameter(Mandatory)]
        [ValidateSet('parity', 'current')]
        [string]$ModelProfile,

        [Parameter(Mandatory)]
        [bool]$EnableImageGeneration,

        [Parameter(Mandatory)]
        [int]$ChatCapacity,

        [Parameter(Mandatory)]
        [int]$CuCompletionCapacity,

        [Parameter(Mandatory)]
        [int]$EmbeddingCapacity,

        [Parameter(Mandatory)]
        [string]$ImageModelName,

        [Parameter(Mandatory)]
        [string]$ImageModelVersion,

        [Parameter(Mandatory)]
        [int]$ImageCapacity,

        [Parameter()]
        [string]$TargetResourceGroupName,

        [Parameter()]
        [string]$TargetAccountName,

        [Parameter(Mandatory)]
        [datetimeoffset]$AsOf,

        [Parameter(Mandatory)]
        [int]$NearRetirementDays
    )

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI ('az') was not found on PATH. Install it from https://aka.ms/azcli."
    }

    $hasTargetResourceGroup = -not [string]::IsNullOrWhiteSpace($TargetResourceGroupName)
    $hasTargetAccount = -not [string]::IsNullOrWhiteSpace($TargetAccountName)
    if ($hasTargetResourceGroup -xor $hasTargetAccount) {
        throw "Provide both -TargetResourceGroupName and -TargetAccountName to account for existing deployments during re-apply."
    }

    Write-Host "Model availability preflight for location '$Location' (profile '$ModelProfile')."
    Write-Host "Keep this script's defaults, model profiles, and requirement definitions synchronized with TERRAFORM\\MAIN.tf and TERRAFORM\\MOD.tf."

    $account = Invoke-AzJson -Arguments @('account', 'show', '--only-show-errors', '-o', 'json')
    Write-Host "Using subscription '$($account.name)' ($($account.id))."

    $requirements = Get-PreflightRequirements `
        -ModelProfile $ModelProfile `
        -ChatCapacity $ChatCapacity `
        -CuCompletionCapacity $CuCompletionCapacity `
        -EmbeddingCapacity $EmbeddingCapacity `
        -EnableImageGeneration $EnableImageGeneration `
        -ImageModelName $ImageModelName `
        -ImageModelVersion $ImageModelVersion `
        -ImageCapacity $ImageCapacity

    Write-Host 'Requested model deployments:'
    foreach ($requirement in $requirements) {
        Write-Host "  - $($requirement.name) $($requirement.version) / $($requirement.sku) capacity $($requirement.capacity)"
    }

    $catalog = Invoke-AzJson -Arguments @('cognitiveservices', 'model', 'list', '--location', $Location, '--only-show-errors', '-o', 'json')
    $usage = Invoke-AzJson -Arguments @('cognitiveservices', 'usage', 'list', '--location', $Location, '--only-show-errors', '-o', 'json')

    $existingDeployments = @()
    if ($hasTargetResourceGroup -and $hasTargetAccount) {
        Write-Host "Loading existing deployments from '$TargetAccountName' in resource group '$TargetResourceGroupName' to calculate incremental quota demand."
        $existingDeployments = @(Invoke-AzJson -Arguments @(
                'cognitiveservices', 'account', 'deployment', 'list',
                '--resource-group', $TargetResourceGroupName,
                '--name', $TargetAccountName,
                '--only-show-errors',
                '-o', 'json'
            ))
    }
    else {
        Write-Host 'No target account provided; all requested capacity will be treated as new quota demand.'
    }

    $failures = Get-PreflightFailures `
        -Requirements $requirements `
        -Catalog @(Get-Collection $catalog) `
        -Usage @(Get-Collection $usage) `
        -ExistingDeployments @(Get-Collection $existingDeployments) `
        -AsOf $AsOf `
        -NearRetirementDays $NearRetirementDays

    if ($failures.Count -gt 0) {
        Write-Host 'Preflight failures:' -ForegroundColor Red
        foreach ($failure in $failures) {
            Write-Host "  - $failure" -ForegroundColor Red
        }

        throw "Model availability preflight failed with $($failures.Count) issue(s)."
    }

    Write-Host 'Model availability preflight passed.' -ForegroundColor Green
}

if (-not $script:IsDotSourced) {
    Invoke-ModelAvailabilityPreflight `
        -Location $Location `
        -ModelProfile $ModelProfile `
        -EnableImageGeneration $EnableImageGeneration `
        -ChatCapacity $ChatCapacity `
        -CuCompletionCapacity $CuCompletionCapacity `
        -EmbeddingCapacity $EmbeddingCapacity `
        -ImageModelName $ImageModelName `
        -ImageModelVersion $ImageModelVersion `
        -ImageCapacity $ImageCapacity `
        -TargetResourceGroupName $TargetResourceGroupName `
        -TargetAccountName $TargetAccountName `
        -AsOf $AsOf `
        -NearRetirementDays $NearRetirementDays
}
