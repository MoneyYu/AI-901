#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "Terraform was not found on PATH."
}

$terraformRoot = Split-Path $PSScriptRoot -Parent
$chdirArgument = "-chdir=$terraformRoot"
$planPaths = @()

function Assert-GraphMatches {
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.HashSet[string]]$Edges,
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string]$To,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Edges.Contains("$From -> $To")) {
        throw $Message
    }
}

function Normalize-GraphNode {
    param(
        [Parameter(Mandatory)][string]$Node
    )

    $normalized = $Node -replace '^\[root\]\s*', ''
    $normalized = $normalized -replace '\s+\(expand\)$', ''
    return $normalized
}

function Get-GraphEdges {
    param(
        [Parameter(Mandatory)][string]$Graph
    )

    $edges = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($line in ($Graph -split '\r?\n')) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -match '^"(?<from>[^"]+)" -> "(?<to>[^"]+)"(?:\s+\[[^\]]+\])?;?$') {
            $from = Normalize-GraphNode -Node $matches.from
            $to = Normalize-GraphNode -Node $matches.to
            [void]$edges.Add("$from -> $to")
        }
    }

    return $edges
}

try {
    foreach ($imageEnabled in @($true, $false)) {
        $planPath = Join-Path $env:TEMP "ai901-graph-$imageEnabled.tfplan"
        $planPaths += $planPath
        $imageValue = if ($imageEnabled) { 'true' } else { 'false' }

        & terraform $chdirArgument plan `
            -input=false `
            -lock=false `
            -refresh=false `
            -no-color `
            -out $planPath `
            -var 'group_postfix=graphcheck' `
            -var 'enable_data_plane=false' `
            -var "enable_image_generation=$imageValue" | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "terraform plan failed for enable_image_generation=$imageEnabled."
        }

        $graph = (& terraform $chdirArgument graph -plan $planPath) -join "`n"
        $edges = Get-GraphEdges -Graph $graph

        foreach ($edge in @(
                @{ From = 'azurerm_cognitive_deployment.gpt'; To = 'azurerm_cognitive_account_project.project' },
                @{ From = 'azurerm_cognitive_deployment.cu_completion'; To = 'azurerm_cognitive_deployment.gpt' },
                @{ From = 'azurerm_cognitive_deployment.embedding'; To = 'azurerm_cognitive_deployment.cu_completion' }
            )) {
            Assert-GraphMatches `
                -Edges $edges `
                -From $edge.From `
                -To $edge.To `
                -Message "Missing serialization edge '$($edge.From) -> $($edge.To)' for enable_image_generation=$imageEnabled."
        }

        if ($imageEnabled) {
            Assert-GraphMatches `
                -Edges $edges `
                -From 'azurerm_cognitive_deployment.image' `
                -To 'azurerm_cognitive_deployment.embedding' `
                -Message 'Image deployment must depend on embedding when image generation is enabled.'
        }
        elseif ($graph -match 'azurerm_cognitive_deployment.image\[0\]') {
            throw 'Image deployment instance exists when enable_image_generation=false.'
        }

        Write-Host "PASS: serialization graph image=$imageEnabled"
    }
}
finally {
    foreach ($planPath in $planPaths) {
        Remove-Item -LiteralPath $planPath -Force -ErrorAction SilentlyContinue
    }
}
