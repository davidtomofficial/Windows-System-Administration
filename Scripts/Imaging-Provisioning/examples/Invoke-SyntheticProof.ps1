#Requires -Version 5.1
# Copyright (c) 2026 David Tom. Owner-directed, AI-assisted development proof.
# Uses only the adjacent fictional fixtures; never calls a live collector.
[CmdletBinding()]
param([string]$OutputDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProofRefusal([scriptblock]$Action, [string]$ExpectedCode) {
    $observed = $null
    try { & $Action | Out-Null } catch { $observed = $_.Exception.Message }
    if ($observed -cne $ExpectedCode) { throw 'DTO.SyntheticProofRefusalMismatch' }
    $observed
}

function Get-ProofRow($Result, [string]$Source, [string]$Field) {
    $selected = @($Result.Rows | Where-Object {
        $_.Source -ceq $Source -and $_.Field -ceq $Field
    })
    if ($selected.Count -ne 1) { throw 'DTO.SyntheticProofRowMismatch' }
    $selected[0]
}

function Write-NewProofFile([string]$Path, [string]$Content) {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Content)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}

$outputPath = $null
if ($PSBoundParameters.ContainsKey('OutputDirectory')) {
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { throw 'DTO.ProofOutputPathRequired' }
    $provider = $null
    $drive = $null
    $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        $OutputDirectory, [ref]$provider, [ref]$drive)
    if ($provider.Name -cne 'FileSystem') { throw 'DTO.ProofOutputRequiresFileSystem' }
    if (Test-Path -LiteralPath $outputPath) { throw 'DTO.ProofOutputExists' }
}

$component = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $component 'src/DTOSnapshotComparison.psm1') -Force
Import-Module (Join-Path $component 'src/DTOImaging.psm1') -Force

$beforeText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/workstation-before.json') -Raw -Encoding UTF8
$afterText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/workstation-after.json') -Raw -Encoding UTF8
$before = $beforeText | ConvertFrom-Json
$after = $afterText | ConvertFrom-Json
$beforeOriginal = $before | ConvertTo-Json -Depth 12 -Compress
$afterOriginal = $after | ConvertTo-Json -Depth 12 -Compress

$comparison = Compare-DTOWorkstationSnapshot -Before $before -After $after
$version = Get-ProofRow $comparison 'Win32_OperatingSystem' 'Version'
$cpu = Get-ProofRow $comparison 'Win32_Processor' 'Name'
$bios = Get-ProofRow $comparison 'Win32_BIOS' 'SMBIOSBIOSVersion'

# These cases require the specific refusal, not merely any exception.
$malformed = $afterText | ConvertFrom-Json
$malformed.SchemaVersion = '2'
$malformedRefusal = Get-ProofRefusal {
    Compare-DTOWorkstationSnapshot -Before $before -After $malformed
} 'DTO.InvalidWorkstationSnapshot'
$reversedRefusal = Get-ProofRefusal {
    Compare-DTOWorkstationSnapshot -Before $after -After $before
} 'DTO.InvalidObservationOrder'

$report = [pscustomobject][ordered]@{
    ProofId = 'DTO-GH-ORG-006-Imaging'
    DataOrigin = 'HandAuthoredSynthetic'
    Comparison = $comparison
}
$html = ConvertTo-DTOReviewHtml -Review $report
$region = [regex]::Match($html, '(?s)<pre>(.*?)</pre>')
$htmlEvidencePreserved = ($region.Success -and -not $html.Contains('<script>') -and
    [Net.WebUtility]::HtmlDecode($region.Groups[1].Value) -ceq ($report | ConvertTo-Json -Depth 12))

# Stable key order, arrays and ASCII values make this one JSON string comparable
# across Windows PowerShell 5.1 and PowerShell 7. Runtime versions are external evidence.
$summary = [pscustomobject][ordered]@{
    ProofId = 'DTO-GH-ORG-006-Imaging'
    DataOrigin = 'HandAuthoredSynthetic'
    ComparedFieldCount = $comparison.Rows.Count
    ChangedCount = $comparison.ChangedCount
    UnchangedCount = $comparison.UnchangedCount
    UnknownCount = $comparison.UnknownCount
    ChangedFields = @($comparison.Rows | Where-Object { $_.State -ceq 'Changed' } |
        ForEach-Object { $_.Source + '.' + $_.Field })
    UnchangedFields = @($comparison.Rows | Where-Object { $_.State -ceq 'Unchanged' } |
        ForEach-Object { $_.Source + '.' + $_.Field })
    UnknownFields = @($comparison.Rows | Where-Object { $_.State -ceq 'Unknown' } |
        ForEach-Object { $_.Source + '.' + $_.Field })
    VersionBefore = $version.BeforeValues[0]
    VersionAfter = $version.AfterValues[0]
    CpuNamesBefore = @($cpu.BeforeValues)
    CpuNamesAfter = @($cpu.AfterValues)
    BiosAfterCoverage = [pscustomobject][ordered]@{
        Status = $bios.AfterCoverage.Status
        Complete = $bios.AfterCoverage.Complete
        Reason = $bios.AfterCoverage.Reason
    }
    Chronology = $comparison.Chronology
    ComparisonComplete = $comparison.ComparisonComplete
    SameDeviceVerified = $comparison.SameDeviceVerified
    DeploymentAccepted = $comparison.DeploymentAccepted
    ChangesAllowed = $comparison.ChangesAllowed
    MalformedEnvelopeRefusal = $malformedRefusal
    ReversedOrderRefusal = $reversedRefusal
    ObservationTimesPreserved = (
        $comparison.BeforeCollectedAtUtc -ceq '2026-11-06T17:00:00.0000000Z' -and
        $comparison.AfterCollectedAtUtc -ceq '2026-11-06T18:00:00.0000000Z')
    InputsUnchanged = (($before | ConvertTo-Json -Depth 12 -Compress) -ceq $beforeOriginal -and
        ($after | ConvertTo-Json -Depth 12 -Compress) -ceq $afterOriginal)
    HtmlEvidencePreserved = $htmlEvidencePreserved
}
$summaryJson = $summary | ConvertTo-Json -Depth 8 -Compress
# Authored independently from the two fixture scenarios, never refreshed from
# this run's actual output. A mismatch stops before creating output files.
$expected = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'expected/workstation-summary.json') -Raw -Encoding UTF8 |
    ConvertFrom-Json
$expectedJson = $expected | ConvertTo-Json -Depth 8 -Compress
if ($summaryJson -cne $expectedJson) { throw 'DTO.SyntheticProofExpectedOutputMismatch' }

if ($null -ne $outputPath) {
    # Refuse pre-existing directories as well as files; exclusive file creation
    # also prevents overwriting a report introduced after the initial check.
    if (Test-Path -LiteralPath $outputPath) { throw 'DTO.ProofOutputExists' }
    New-Item -ItemType Directory -Path $outputPath -ErrorAction Stop | Out-Null
    Write-NewProofFile (Join-Path $outputPath 'summary.json') ($summaryJson + "`n")
    Write-NewProofFile (Join-Path $outputPath 'report.html') $html
}

# Exactly one success-stream value; no files are written without OutputDirectory.
$summaryJson
