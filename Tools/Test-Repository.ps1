<#
.SYNOPSIS
Runs syntax, static-analysis and Pester checks using already-installed pinned tools.
.DESCRIPTION
Does not install dependencies or change execution policy. Writes only generated
quality reports to the ignored TestResults directory. Unit tests mock CIM;
real local Windows collection occurs only with IncludeRunnerSmoke.
.PARAMETER IncludeRunnerSmoke
Also run the read-only local CIM smoke test on this Windows host.
.EXAMPLE
.\Tools\Test-Repository.ps1
#>
[CmdletBinding()]
param([switch]$IncludeRunnerSmoke)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$versions = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'TestDependencies.psd1')
Import-Module PSScriptAnalyzer -RequiredVersion $versions.PSScriptAnalyzer -Force -ErrorAction Stop
Import-Module Pester -RequiredVersion $versions.Pester -Force -ErrorAction Stop

$sourcePaths = @('Modules', 'Scripts', 'Tools', 'Tests/PowerShell')
foreach ($relativePath in $sourcePaths) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { continue }
    $files = Get-ChildItem -LiteralPath $path -Recurse -File |
        Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') }
    foreach ($file in $files) {
        $tokens = $null
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
        if (@($parseErrors).Count -gt 0) {
            throw "PowerShell parse errors in $($file.FullName): $($parseErrors -join '; ')"
        }
    }
}

# Pester test doubles are parsed above but not linted as production commands.
$findings = @(foreach ($relativePath in @('Modules', 'Scripts', 'Tools')) {
    $path = Join-Path $root $relativePath
    if (Test-Path -LiteralPath $path -PathType Container) {
        Invoke-ScriptAnalyzer -Path $path -Recurse -Severity Error,Warning
    }
})
if ($findings.Count -gt 0) {
    $findings | Format-Table -AutoSize | Out-Host
    throw "PSScriptAnalyzer found $($findings.Count) error(s) or warning(s)."
}

$resultsPath = Join-Path $root 'TestResults'
$null = New-Item -ItemType Directory -Path $resultsPath -Force
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $root 'Tests/PowerShell'
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Run.Throw = $true
$config.Run.SkipRun = $false
$config.Should.DisableV5 = $false
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path $resultsPath 'pester.xml'
$config.TestResult.OutputFormat = 'NUnitXml'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = Join-Path $root 'Modules/WindowsSysAdmin/WindowsSysAdmin.psm1'
$config.CodeCoverage.OutputPath = Join-Path $resultsPath 'coverage.xml'
$config.CodeCoverage.CoveragePercentTarget = 80
if (-not $IncludeRunnerSmoke) {
    $config.Filter.ExcludeTag = @('RunnerSmoke')
}
$result = Invoke-Pester -Configuration $config
Write-Information "Quality result: $($result.Result); passed=$($result.PassedCount); failed=$($result.FailedCount); skipped=$($result.SkippedCount)" -InformationAction Continue
if ($result.PassedCount -eq 0 -or $result.Result -ne 'Passed') {
    throw 'Pester failed, discovered no tests, or did not meet the coverage target.'
}
