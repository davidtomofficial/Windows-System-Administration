#Requires -Version 5.1
<#
.SYNOPSIS
Checks fictional DeviceCare inputs against an independently authored expectation.
.DESCRIPTION
Uses the findings and presentation functions only; never collects device data.
The success pipeline contains one compact JSON string. Files are written only
when OutputDirectory names a new directory with an existing filesystem parent.
#>
[CmdletBinding()]
param([string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$componentRoot = Split-Path $PSScriptRoot -Parent

function Assert-Proof([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('DTO.ProofMismatch: ' + $Name) }
}

function Assert-ProofRefusal([scriptblock]$Action, [string]$Message, [switch]$Threshold) {
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_ }
    Assert-Proof ($null -ne $failure) ('expected refusal ' + $Message)
    if ($Threshold) {
        $errorId = [string]$failure.FullyQualifiedErrorId
        $exceptionType = $failure.Exception.GetType().FullName
        Assert-Proof ($errorId -ceq 'ParameterArgumentValidationError,Get-DTODeviceCareFindings' -and
            $exceptionType -ceq 'System.Management.Automation.ParameterBindingValidationException') (
            'threshold validation refusal; FullyQualifiedErrorId=' + $errorId + '; ExceptionType=' + $exceptionType)
    } else {
        Assert-Proof ($failure.Exception.Message -ceq $Message) ('specific refusal ' + $Message)
    }
}

function ConvertTo-ProofFinding($Assessment, [string]$Id, [string]$Units) {
    $matches = @($Assessment.Findings | Where-Object { $_.Id -ceq $Id })
    Assert-Proof ($matches.Count -eq 1) ('single finding ' + $Id)
    $finding = $matches[0]
    Assert-Proof (@('Observed', 'Review', 'Unknown') -ccontains $finding.State) ('known state ' + $Id)
    $value = $null
    if ($finding.State -ceq 'Unknown') {
        Assert-Proof ($null -eq $finding.Observed) ('unknown value ' + $Id)
    } else {
        Assert-Proof ($null -ne $finding.Observed) ('available value ' + $Id)
        $value = ([double]$finding.Observed).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
    }
    [pscustomobject][ordered]@{ State = $finding.State; DisplayValue = $value; Units = $Units }
}

function Write-ProofFile([string]$Path, [string]$Content) {
    $encoding = New-Object System.Text.UTF8Encoding -ArgumentList $false
    $bytes = $encoding.GetBytes($Content)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}

$outputPath = $null
if ($PSBoundParameters.ContainsKey('OutputDirectory')) {
    Assert-Proof (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) 'nonempty output directory'
    $provider = $null
    $drive = $null
    $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory, [ref]$provider, [ref]$drive)
    Assert-Proof ($provider.Name -ceq 'FileSystem') 'filesystem output directory'
    if (Test-Path -LiteralPath $outputPath) { throw 'DTO.ProofOutputExists' }
    $outputParent = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) { throw 'DTO.ProofOutputParentMissing' }
}

Import-Module (Join-Path $componentRoot 'src/DeviceCare.psm1') -Force
$fixtures = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'synthetic-snapshots.json')) | ConvertFrom-Json
$expected = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'expected-summary.json')) | ConvertFrom-Json
$rows = New-Object 'System.Collections.Generic.List[object]'
$reportHtml = $null
$firstSnapshot = $null
$expectedTime = '2026-01-01T12:00:00.0000000Z'

foreach ($case in $fixtures.Cases) {
    $snapshot = $case.Snapshot
    # PowerShell 7 may parse a JSON timestamp as DateTime; restore its UTC text.
    if ($snapshot.CollectedAtUtc -is [DateTime]) {
        $snapshot.CollectedAtUtc = $snapshot.CollectedAtUtc.ToUniversalTime().ToString('o', [Globalization.CultureInfo]::InvariantCulture)
    }
    Assert-Proof ($snapshot.CollectedAtUtc -ceq $expectedTime) ('fictional observation time ' + $case.Id)
    $before = $snapshot | ConvertTo-Json -Depth 8 -Compress
    $parameters = @{ Snapshot = $snapshot }
    if ($null -ne $case.Thresholds) {
        $parameters.MinimumDiskFreeGiB = $case.Thresholds.MinimumDiskFreeGiB
        $parameters.MaximumMemoryUsedPercent = $case.Thresholds.MaximumMemoryUsedPercent
    }
    $assessment = Get-DTODeviceCareFindings @parameters
    Assert-Proof (($snapshot | ConvertTo-Json -Depth 8 -Compress) -ceq $before) ('input unchanged ' + $case.Id)
    Assert-Proof ($null -eq $assessment.DeviceReady -and $assessment.MaintenanceAuthorized -is [bool] -and -not $assessment.MaintenanceAuthorized) ('authority withheld ' + $case.Id)
    Assert-Proof ($assessment.CollectedAtUtc -ceq $expectedTime) ('time preserved ' + $case.Id)
    Assert-Proof ($assessment.Findings.Count -eq 2) ('two findings ' + $case.Id)

    $assessment | Add-Member -NotePropertyName FictionalExtra -NotePropertyValue 'DTO-FICTIONAL-OMIT'
    $html = ConvertTo-DTODeviceCareHtml -Assessment $assessment
    Assert-Proof ($html.Contains($expectedTime)) ('report observation time ' + $case.Id)
    Assert-Proof ($html.Contains("default-src 'none'")) ('offline report policy ' + $case.Id)
    Assert-Proof (-not $html.Contains('DTO-FICTIONAL-OMIT')) ('report projection ' + $case.Id)
    if ($case.Id -ceq 'review') { $reportHtml = $html }
    if ($case.Id -ceq 'observed') { $firstSnapshot = $snapshot }

    $rows.Add([pscustomobject][ordered]@{
        Id = $case.Id
        DiskMinimumGiB = ([double]$assessment.Thresholds.MinimumDiskFreeGiB).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
        MemoryMaximumPercent = ([double]$assessment.Thresholds.MaximumMemoryUsedPercent).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
        Memory = ConvertTo-ProofFinding $assessment 'memory' 'percent'
        SystemDisk = ConvertTo-ProofFinding $assessment 'system-disk' 'GiB'
    })
}
Assert-Proof ($null -ne $firstSnapshot -and $null -ne $reportHtml) 'required demonstration cases'

$wrongProduct = [pscustomobject]@{ SchemaVersion = 1; Product = 'Other'; AssessmentType = 'LocalReadOnly'; ChangesAllowed = $false }
Assert-ProofRefusal { Get-DTODeviceCareFindings -Snapshot $wrongProduct } 'DTO.InvalidSnapshot'
$numericFlag = [pscustomobject]@{ SchemaVersion = 1; Product = 'DeviceCare'; AssessmentType = 'LocalReadOnly'; ChangesAllowed = 0 }
Assert-ProofRefusal { Get-DTODeviceCareFindings -Snapshot $numericFlag } 'DTO.InvalidSnapshot'
Assert-ProofRefusal { Get-DTODeviceCareFindings -Snapshot $firstSnapshot -MinimumDiskFreeGiB 0 } 'out-of-range threshold' -Threshold
$duplicate = Get-DTODeviceCareFindings -Snapshot $firstSnapshot
$duplicate.Findings[1].Id = 'memory'
Assert-ProofRefusal { ConvertTo-DTODeviceCareHtml -Assessment $duplicate } 'DTO.InvalidFindingIdentity'
$unsupported = Get-DTODeviceCareFindings -Snapshot $firstSnapshot
$unsupported.Findings[0].State = 'Healthy'
Assert-ProofRefusal { ConvertTo-DTODeviceCareHtml -Assessment $unsupported } 'DTO.InvalidFindingState'

$textCase = Get-DTODeviceCareFindings -Snapshot $firstSnapshot
$literalText = '<script>fictional-text</script>'
$textCase.Findings[0].Explanation = $literalText
$textHtml = ConvertTo-DTODeviceCareHtml -Assessment $textCase
Assert-Proof (-not $textHtml.Contains($literalText) -and $textHtml.Contains([Net.WebUtility]::HtmlEncode($literalText))) 'HTML text encoding'
$unknownCase = Get-DTODeviceCareFindings -Snapshot $firstSnapshot
$unknownCase.Findings[0].State = 'Unknown'
$unknownCase.Findings[0].Observed = 99
$unknownHtml = ConvertTo-DTODeviceCareHtml -Assessment $unknownCase
$detail = [regex]::Match($unknownHtml, '(?s)<pre>(.*?)</pre>')
Assert-Proof ($detail.Success) 'structured report detail'
$decoded = [Net.WebUtility]::HtmlDecode($detail.Groups[1].Value) | ConvertFrom-Json
$unknownMemory = @($decoded.Findings | Where-Object { $_.Id -ceq 'memory' })
Assert-Proof ($unknownMemory.Count -eq 1 -and $unknownMemory[0].State -ceq 'Unknown' -and $null -eq $unknownMemory[0].Observed) 'unknown report value suppressed'

$summary = [pscustomobject][ordered]@{
    Proof = $fixtures.FixtureSet
    FictionalData = $true
    DeviceReady = $null
    MaintenanceAuthorized = $false
    Cases = @($rows.ToArray())
    VerifiedRefusals = @('wrong-product', 'numeric-changes-flag', 'invalid-threshold', 'duplicate-finding', 'unsupported-state')
    VerifiedReportChecks = @('original-time', 'offline-policy', 'html-encoding', 'unknown-value-suppressed', 'extra-properties-omitted')
    InputsUnchanged = $true
}
$json = $summary | ConvertTo-Json -Depth 8 -Compress
$expectedJson = $expected | ConvertTo-Json -Depth 8 -Compress
Assert-Proof ($json -ceq $expectedJson) 'independently specified summary'
Assert-Proof (-not $json.Contains('DTO-FICTIONAL-OMIT')) 'summary projection'

if ($null -ne $outputPath) {
    # New-Item without Force refuses a directory created since the earlier check.
    New-Item -Path $outputParent -Name (Split-Path -Path $outputPath -Leaf) -ItemType Directory -ErrorAction Stop | Out-Null
    Write-ProofFile (Join-Path $outputPath 'summary.json') ($json + "`n")
    Write-ProofFile (Join-Path $outputPath 'report.html') $reportHtml
}
Write-Output $json
