#Requires -Version 5.1
# Copyright (c) 2026 David Tom. Read-only comparison of selected DTO observations.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DTOComparisonField($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    if ($Object -is [Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return ,$Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property -and $property.MemberType -in @('NoteProperty', 'Property')) {
        return ,$property.Value
    }
    return $null
}

function Test-DTOComparisonInteger($Value) {
    return ($Value -is [int] -or $Value -is [long] -or $Value -is [uint32])
}

function Test-DTOComparisonText($Value) {
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value.Length -le 256 -and $Value -notmatch '[\p{Cc}\p{Cf}]')
}

function Get-DTOComparisonTime($Value) {
    # The collector emits UTC round-trip strings. PowerShell JSON readers may
    # materialize those strings as DateTime values, which must still be UTC.
    if ($Value -is [DateTime] -and $Value.Kind -eq [DateTimeKind]::Utc) {
        return [pscustomobject]@{ Text=$Value.ToString('o'); Ticks=$Value.Ticks }
    }
    if ($Value -isnot [string] -or $Value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$') {
        throw 'DTO.InvalidSnapshotTimestamp'
    }
    try {
        $time = [DateTime]::ParseExact($Value, "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'",
            [Globalization.CultureInfo]::InvariantCulture,
            ([Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal))
    } catch { throw 'DTO.InvalidSnapshotTimestamp' }
    [pscustomobject]@{ Text=$Value; Ticks=$time.Ticks }
}

function Get-DTOComparisonInput($Snapshot) {
    $schema = Get-DTOComparisonField $Snapshot 'SchemaVersion'
    $product = Get-DTOComparisonField $Snapshot 'Product'
    $assessment = Get-DTOComparisonField $Snapshot 'AssessmentType'
    $complete = Get-DTOComparisonField $Snapshot 'CollectionComplete'
    $accepted = Get-DTOComparisonField $Snapshot 'DeploymentAccepted'
    $identity = Get-DTOComparisonField $Snapshot 'ComputerNameIncluded'
    $sections = Get-DTOComparisonField $Snapshot 'Sections'
    if (-not (Test-DTOComparisonInteger $schema) -or $schema -ne 2 -or
        $product -isnot [string] -or $product -cne 'DTO Imaging & Provisioning' -or
        $assessment -isnot [string] -or $assessment -cne 'ReadOnlyLocalSnapshot' -or
        $complete -isnot [bool] -or $accepted -isnot [bool] -or $accepted -ne $false -or
        $identity -isnot [bool] -or $sections -isnot [Array] -or $sections.Count -gt 16) {
        throw 'DTO.InvalidWorkstationSnapshot'
    }
    $time = Get-DTOComparisonTime (Get-DTOComparisonField $Snapshot 'CollectedAtUtc')
    [pscustomobject]@{ Time=$time; ReportedComplete=$complete; Sections=$sections }
}

function Get-DTOComparisonSection($Sections, [string]$Source, [int]$MaximumRecords) {
    $sourceMatches = @($Sections | Where-Object {
        $name = Get-DTOComparisonField $_ 'Source'
        $name -is [string] -and [StringComparer]::OrdinalIgnoreCase.Equals($name, $Source)
    })
    if ($sourceMatches.Count -eq 0) {
        return [pscustomobject]@{ Status='Missing'; Reason='MissingSource'; Complete=$false; Records=@() }
    }
    if ($sourceMatches.Count -ne 1) {
        return [pscustomobject]@{ Status='Ambiguous'; Reason='DuplicateSource'; Complete=$false; Records=@() }
    }
    $section = $sourceMatches[0]
    if ((Get-DTOComparisonField $section 'Source') -cne $Source) {
        return [pscustomobject]@{ Status='Invalid'; Reason='InvalidSource'; Complete=$false; Records=@() }
    }
    $status = Get-DTOComparisonField $section 'Status'
    $records = Get-DTOComparisonField $section 'Records'
    if ($records -isnot [Array] -or $records.Count -gt $MaximumRecords -or $status -isnot [string] -or
        $status -cnotin @('Complete', 'Partial', 'NoData', 'Unavailable')) {
        return [pscustomobject]@{ Status='Invalid'; Reason='InvalidSection'; Complete=$false; Records=@() }
    }
    if ($status -cne 'Complete') {
        return [pscustomobject]@{ Status=$status; Reason='IncompleteSource'; Complete=$false; Records=$records }
    }
    $collected = Get-DTOComparisonField $section 'CollectionComplete'
    $enumerated = Get-DTOComparisonField $section 'EnumerationComplete'
    $seen = Get-DTOComparisonField $section 'EnumeratedCount'
    $inspected = Get-DTOComparisonField $section 'InspectedCount'
    $limit = Get-DTOComparisonField $section 'RecordLimit'
    $valid = ($collected -is [bool] -and $collected -eq $true -and
        $enumerated -is [bool] -and $enumerated -eq $true -and
        (Test-DTOComparisonInteger $seen) -and (Test-DTOComparisonInteger $inspected) -and
        (Test-DTOComparisonInteger $limit) -and $limit -ge 1 -and $limit -le $MaximumRecords -and
        $records.Count -ge 1 -and $records.Count -le $limit -and
        $seen -eq $records.Count -and $inspected -eq $records.Count -and
        $null -eq (Get-DTOComparisonField $section 'Reason'))
    if (-not $valid) {
        return [pscustomobject]@{ Status='Invalid'; Reason='InvalidCoverage'; Complete=$false; Records=$records }
    }
    [pscustomobject]@{ Status='Complete'; Reason=$null; Complete=$true; Records=$records }
}

function Get-DTOComparisonValues($Section, [string]$Field) {
    $values = New-Object 'Collections.Generic.List[string]'
    $valid = $true
    foreach ($record in $Section.Records) {
        $value = Get-DTOComparisonField $record $Field
        if (Test-DTOComparisonText $value) { $values.Add($value) }
        else { $valid = $false }
    }
    $array = $values.ToArray()
    # CPUs have no stable per-socket identity in schema 2. Compare a multiset of
    # names, retaining duplicate counts, without inventing a socket mapping.
    [Array]::Sort($array, [StringComparer]::Ordinal)
    $complete = $Section.Complete -and $valid -and $array.Count -gt 0
    $reason = if (-not $valid) { 'MissingOrInvalidValue' } else { $Section.Reason }
    [pscustomobject]@{ Values=@($array); Coverage=[pscustomobject]@{
        Status=$Section.Status; Complete=[bool]$complete; Reason=$reason
    } }
}

function Compare-DTOWorkstationSnapshot {
    <#
    .SYNOPSIS
    Compares known fields in two selected schema 2 workstation observations.
    .DESCRIPTION
    Returns values and Changed/Unchanged/Unknown states. Performs no collection,
    file writes, transmission or changes. Caller selects and retains the inputs.
    Device identity, cause, readiness and human handoff are not established.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Before, [Parameter(Mandatory)]$After)
    $left = Get-DTOComparisonInput $Before
    $right = Get-DTOComparisonInput $After
    if ($right.Time.Ticks -lt $left.Time.Ticks) { throw 'DTO.InvalidObservationOrder' }
    $specifications = @(
        @{ Source='Win32_OperatingSystem'; Limit=1; Fields=@('Caption','Version','OSArchitecture') },
        @{ Source='Win32_ComputerSystem'; Limit=1; Fields=@('Manufacturer','Model') },
        @{ Source='Win32_BIOS'; Limit=1; Fields=@('SMBIOSBIOSVersion') },
        @{ Source='Win32_Processor'; Limit=16; Fields=@('Name') }
    )
    $rows = New-Object 'Collections.Generic.List[object]'
    foreach ($specification in $specifications) {
        $beforeSection = Get-DTOComparisonSection $left.Sections $specification.Source $specification.Limit
        $afterSection = Get-DTOComparisonSection $right.Sections $specification.Source $specification.Limit
        foreach ($field in $specification.Fields) {
            $beforeValue = Get-DTOComparisonValues $beforeSection $field
            $afterValue = Get-DTOComparisonValues $afterSection $field
            $state = 'Unknown'
            if ($beforeValue.Coverage.Complete -and $afterValue.Coverage.Complete) {
                $equal = $beforeValue.Values.Count -eq $afterValue.Values.Count
                if ($equal) {
                    for ($i=0; $i -lt $beforeValue.Values.Count; $i++) {
                        if (-not [StringComparer]::Ordinal.Equals($beforeValue.Values[$i], $afterValue.Values[$i])) {
                            $equal = $false
                            break
                        }
                    }
                }
                $state = if ($equal) { 'Unchanged' } else { 'Changed' }
            }
            $rows.Add([pscustomobject]@{
                Source=$specification.Source; Field=$field; State=$state;
                BeforeValues=@($beforeValue.Values); AfterValues=@($afterValue.Values);
                BeforeCoverage=$beforeValue.Coverage; AfterCoverage=$afterValue.Coverage
            })
        }
    }
    $changed = @($rows | Where-Object { $_.State -ceq 'Changed' }).Count
    $unchanged = @($rows | Where-Object { $_.State -ceq 'Unchanged' }).Count
    $unknown = @($rows | Where-Object { $_.State -ceq 'Unknown' }).Count
    [pscustomobject]@{
        SchemaVersion=1; Product='DTO Imaging & Provisioning'; AssessmentType='ReadOnlySnapshotComparison';
        ComparisonScope='SelectedObservationsOnly';
        BeforeCollectedAtUtc=$left.Time.Text; AfterCollectedAtUtc=$right.Time.Text;
        Chronology=if ($right.Time.Ticks -eq $left.Time.Ticks) { 'SameTimestamp' } else { 'Forward' };
        BeforeSnapshotReportedComplete=$left.ReportedComplete; AfterSnapshotReportedComplete=$right.ReportedComplete;
        ChangedCount=$changed; UnchangedCount=$unchanged; UnknownCount=$unknown;
        ComparisonComplete=($unknown -eq 0); Rows=@($rows.ToArray());
        SameDeviceVerified=$false; DeploymentAccepted=$false; ChangesAllowed=$false;
        Notice='Differences concern the selected observations only. Device identity, cause, readiness and human signoff are unverified. Unknown is not unchanged or passing. CPU names are compared as a multiset, not by socket. Identifiers and unrecognized fields are omitted; hardware and OS values can still be sensitive.'
    }
}

Export-ModuleMember -Function Compare-DTOWorkstationSnapshot
