#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$actualCommit = (& git -C $repo rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $actualCommit -cne $SourceCommit) {
    throw 'Proof source must match the checked-out Git commit.'
}
& git -C $repo diff --quiet HEAD --
if ($LASTEXITCODE -ne 0) { throw 'Proof source must have no tracked changes from the recorded commit.' }
$provider = $null
$drive = $null
$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputRoot, [ref]$provider, [ref]$drive)
if ($provider.Name -cne 'FileSystem') { throw 'Proof output requires a filesystem path.' }
if (Test-Path -LiteralPath $destination) { throw 'Proof output root already exists.' }
$null = [IO.Directory]::CreateDirectory($destination)

foreach ($component in @('DeviceCare', 'Imaging-Provisioning')) {
    $label = if ($component -eq 'DeviceCare') { 'DeviceCare' } else { 'Imaging' }
    $entry = Join-Path $repo ('Scripts/' + $component + '/examples/Invoke-SyntheticProof.ps1')
    $out = Join-Path $destination $label

    # Exercise the documented console command before requesting any export.
    $consoleJson = & $entry
    if ($consoleJson -isnot [string]) { throw "$label must emit exactly one JSON string." }
    $null = $consoleJson | ConvertFrom-Json
    if (Test-Path -LiteralPath $out) { throw "$label default run created an output directory." }

    $exportJson = & $entry -OutputDirectory $out
    if ($exportJson -isnot [string] -or $exportJson -cne $consoleJson) {
        throw "$label console and export results differ."
    }
    $names = @(Get-ChildItem -LiteralPath $out -Force | Sort-Object Name | ForEach-Object { $_.Name })
    if (($names -join '|') -cne 'report.html|summary.json') { throw "$label export membership differs." }
    $savedJson = Get-Content -LiteralPath (Join-Path $out 'summary.json') -Raw
    $saved = $savedJson | ConvertFrom-Json | ConvertTo-Json -Depth 30 -Compress
    $expected = $consoleJson | ConvertFrom-Json | ConvertTo-Json -Depth 30 -Compress
    if ($saved -cne $expected) { throw "$label saved and console evidence differ." }
    if ((Get-Item -LiteralPath (Join-Path $out 'report.html')).Length -eq 0) { throw "$label HTML is empty." }

    $before = @{}
    foreach ($name in $names) { $before[$name] = (Get-FileHash -LiteralPath (Join-Path $out $name) -Algorithm SHA256).Hash }
    $refused = $false
    try { $null = & $entry -OutputDirectory $out } catch {
        if ($_.Exception.Message -cne 'DTO.ProofOutputExists') { throw }
        $refused = $true
    }
    if (-not $refused) { throw "$label accepted an existing output directory." }
    $afterNames = @(Get-ChildItem -LiteralPath $out -Force | Sort-Object Name | ForEach-Object { $_.Name })
    if (($afterNames -join '|') -cne ($names -join '|')) { throw "$label refusal changed export membership." }
    foreach ($name in $names) {
        if ((Get-FileHash -LiteralPath (Join-Path $out $name) -Algorithm SHA256).Hash -cne $before[$name]) {
            throw "$label refusal changed $name."
        }
    }
    Write-Output ($label + ': console, fresh export, readback and overwrite-refusal checks passed.')
    Write-Output $consoleJson
}

$environment = [ordered]@{
    SchemaVersion = 1
    SourceCommit = $SourceCommit
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    PowerShellEdition = $PSVersionTable.PSEdition
    OperatingSystem = [Environment]::OSVersion.VersionString
    EvidenceKind = 'SyntheticDeveloperProof'
    LiveDeviceAcceptance = $false
    AttendedVisualOrAccessibilityAcceptance = $false
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $destination 'environment.json'), ($environment | ConvertTo-Json -Depth 5), $utf8)
Write-Output 'Both synthetic proof packages passed; runtime and exact source recorded in environment.json.'
