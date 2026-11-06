#Requires -Version 5.1
# Copyright (c) 2026 David Tom. Personal development preview; not deployment authority.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Only ordinary data properties are read. No caller-supplied getter is evaluated.
function Get-DTOComparisonProperty($InputObject, [string]$Name) {
    if ($InputObject -isnot [System.Management.Automation.PSCustomObject]) { throw 'DTO.InvalidSnapshotInput' }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $property.MemberType -ne 'NoteProperty') { throw 'DTO.InvalidSnapshotInput' }
    return ,$property.Value
}

function Test-DTOComparisonInteger($Value) {
    return ($Value -is [int] -or $Value -is [long] -or $Value -is [uint32] -or
        $Value -is [uint64] -or $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [byte] -or $Value -is [sbyte])
}

function Test-DTOComparisonText($Value) {
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value.Length -le 256 -and $Value -notmatch '[\p{Cc}\p{Cf}]')
}

function Get-DTOComparisonTimestamp($Value) {
    # PowerShell versions can deserialize ISO JSON dates into DateTime values.
    if ($Value -is [datetime] -and $Value.Kind -eq [DateTimeKind]::Utc) {
        return $Value.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [datetimeoffset] -and $Value.Offset -eq [TimeSpan]::Zero) {
        return $Value.UtcDateTime.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -isnot [string] -or
        $Value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|\+00:00)$') {
        throw 'DTO.InvalidSnapshotInput'
    }
    $parsed = [datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$parsed) -or $parsed.Offset -ne [TimeSpan]::Zero) {
        throw 'DTO.InvalidSnapshotInput'
    }
    return $Value
}

function Get-DTOComparisonLayout {
    @(
        [pscustomobject]@{ Source='Win32_OperatingSystem'; Properties=@('Caption','Version','OSArchitecture'); Limit=1 }
        [pscustomobject]@{ Source='Win32_ComputerSystem'; Properties=@('Manufacturer','Model'); Limit=1 }
        [pscustomobject]@{ Source='Win32_BIOS'; Properties=@('SMBIOSBIOSVersion'); Limit=1 }
        [pscustomobject]@{ Source='Win32_Processor'; Properties=@('Name'); Limit=16 }
    )
}

function Assert-DTOComparisonSection($Section, $Definition) {
    $status = Get-DTOComparisonProperty $Section 'Status'
    $reason = Get-DTOComparisonProperty $Section 'Reason'
    $records = Get-DTOComparisonProperty $Section 'Records'
    $enumerated = Get-DTOComparisonProperty $Section 'EnumeratedCount'
    $inspected = Get-DTOComparisonProperty $Section 'InspectedCount'
    $limit = Get-DTOComparisonProperty $Section 'RecordLimit'
    $byteLimit = Get-DTOComparisonProperty $Section 'RecordByteLimit'
    $enumerationComplete = Get-DTOComparisonProperty $Section 'EnumerationComplete'
    $collectionComplete = Get-DTOComparisonProperty $Section 'CollectionComplete'
    if ($status -isnot [string] -or $status -cnotin @('Complete','Partial','Unavailable','NoData') -or
        ($null -ne $reason -and ($reason -isnot [string] -or
            $reason -cnotin @('RecordLimit','QueryFailed','InvalidRecord','DuplicateName','ByteLimit','NoRows'))) -or
        $records -isnot [array] -or $records.Rank -ne 1 -or
        $enumerationComplete -isnot [bool] -or $collectionComplete -isnot [bool]) {
        throw 'DTO.InvalidSnapshotInput'
    }
    foreach ($number in @($enumerated, $inspected, $limit, $byteLimit)) {
        if (-not (Test-DTOComparisonInteger $number)) { throw 'DTO.InvalidSnapshotInput' }
    }
    if ($limit -ne $Definition.Limit -or $byteLimit -ne 131072 -or
        $enumerated -lt 0 -or $enumerated -gt ($limit + 1) -or
        $inspected -lt 0 -or $inspected -gt $limit -or $inspected -gt $enumerated -or
        $inspected -ne [Math]::Min([long]$enumerated, [long]$limit) -or $records.Count -gt $inspected) {
        throw 'DTO.InvalidSnapshotInput'
    }
    foreach ($record in $records) {
        foreach ($name in $Definition.Properties) {
            $value = Get-DTOComparisonProperty $record $name
            if (-not (Test-DTOComparisonText $value)) { throw 'DTO.InvalidSnapshotInput' }
        }
    }
    if ($status -ceq 'Complete') {
        if (-not $collectionComplete -or -not $enumerationComplete -or $null -ne $reason -or
            $records.Count -eq 0 -or $records.Count -ne $enumerated -or $inspected -ne $enumerated) {
            throw 'DTO.InvalidSnapshotInput'
        }
    } else {
        if ($collectionComplete -or $null -eq $reason) { throw 'DTO.InvalidSnapshotInput' }
        if ($status -ceq 'NoData') {
            if ($enumerated -ne 0 -or -not $enumerationComplete -or $reason -cne 'NoRows') {
                throw 'DTO.InvalidSnapshotInput'
            }
        } elseif ($status -ceq 'Unavailable') {
            if ($enumerated -ne 0 -or $enumerationComplete -or $reason -cne 'QueryFailed') {
                throw 'DTO.InvalidSnapshotInput'
            }
        } else {
            if ($enumerated -eq 0 -or $reason -ceq 'NoRows') { throw 'DTO.InvalidSnapshotInput' }
            if ($reason -ceq 'RecordLimit') {
                if ($enumerated -ne ($limit + 1) -or $enumerationComplete) { throw 'DTO.InvalidSnapshotInput' }
            } elseif ($reason -ceq 'QueryFailed') {
                if ($enumerated -gt $limit -or $enumerationComplete) { throw 'DTO.InvalidSnapshotInput' }
            } elseif ($enumerated -gt $limit -or -not $enumerationComplete -or $records.Count -ge $inspected) {
                throw 'DTO.InvalidSnapshotInput'
            }
        }
    }
}

function Get-DTOValidatedComparisonSnapshot($Snapshot, $Layout) {
    $schema = Get-DTOComparisonProperty $Snapshot 'SchemaVersion'
    $product = Get-DTOComparisonProperty $Snapshot 'Product'
    $version = Get-DTOComparisonProperty $Snapshot 'Version'
    $type = Get-DTOComparisonProperty $Snapshot 'AssessmentType'
    $included = Get-DTOComparisonProperty $Snapshot 'ComputerNameIncluded'
    $complete = Get-DTOComparisonProperty $Snapshot 'CollectionComplete'
    $accepted = Get-DTOComparisonProperty $Snapshot 'DeploymentAccepted'
    $sections = Get-DTOComparisonProperty $Snapshot 'Sections'
    if (-not (Test-DTOComparisonInteger $schema) -or $schema -ne 2 -or
        $product -isnot [string] -or $product -cne 'DTO Imaging & Provisioning' -or
        $version -isnot [string] -or $version -cne '0.2.0' -or
        $type -isnot [string] -or $type -cne 'ReadOnlyLocalSnapshot' -or
        $included -isnot [bool] -or $complete -isnot [bool] -or $accepted -isnot [bool] -or $accepted -or
        $sections -isnot [array] -or $sections.Rank -ne 1 -or $sections.Count -ne $Layout.Count) {
        throw 'DTO.InvalidSnapshotInput'
    }
    $timestamp = Get-DTOComparisonTimestamp (Get-DTOComparisonProperty $Snapshot 'CollectedAtUtc')
    $mapped = @{}
    foreach ($section in $sections) {
        $source = Get-DTOComparisonProperty $section 'Source'
        if ($source -isnot [string] -or $source -cnotin @($Layout.Source) -or $mapped.ContainsKey($source)) {
            throw 'DTO.InvalidSnapshotInput'
        }
        $definition = @($Layout | Where-Object { $_.Source -ceq $source })[0]
        Assert-DTOComparisonSection $section $definition
        if ($complete -and -not (Get-DTOComparisonProperty $section 'CollectionComplete')) {
            throw 'DTO.InvalidSnapshotInput'
        }
        $mapped[$source] = $section
    }
    # ComputerName and all unknown properties are deliberately neither read nor copied.
    [pscustomobject]@{ CollectedAtUtc=$timestamp; CollectionComplete=$complete; Sections=$mapped }
}

function Get-DTOComparisonValue($Section, [string]$Field, [bool]$Multiple) {
    if (-not (Get-DTOComparisonProperty $Section 'CollectionComplete')) { return $null }
    $records = Get-DTOComparisonProperty $Section 'Records'
    if ($Multiple) {
        [string[]]$values = @($records | ForEach-Object { Get-DTOComparisonProperty $_ $Field })
        # Compare observations as a multiset: ordering is irrelevant, multiplicity is evidence.
        [Array]::Sort($values, [StringComparer]::Ordinal)
        return ,$values
    }
    return (Get-DTOComparisonProperty $records[0] $Field)
}

function Compare-DTOWorkstationSnapshot {
    <#
    .SYNOPSIS
    Compares seven known observations from two schema 2 workstation snapshots.
    .DESCRIPTION
    Accepts the current 0.2.0 collector's in-memory data objects. It performs no
    collection, file access, network access, machine change or deployment action.
    A complete comparison says only whether the selected observations differ;
    it does not establish device identity, health, suitability or acceptance.
    Incomplete evidence takes precedence over an aggregate Changed result.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][object]$Before,
        [Parameter(Mandatory)][AllowNull()][object]$After
    )
    $layout = @(Get-DTOComparisonLayout)
    try {
        $left = Get-DTOValidatedComparisonSnapshot $Before $layout
        $right = Get-DTOValidatedComparisonSnapshot $After $layout
        $leftInstant = [datetimeoffset]::Parse($left.CollectedAtUtc, [Globalization.CultureInfo]::InvariantCulture)
        $rightInstant = [datetimeoffset]::Parse($right.CollectedAtUtc, [Globalization.CultureInfo]::InvariantCulture)
        if ($rightInstant -lt $leftInstant) { throw 'DTO.InvalidSnapshotInput' }
    } catch {
        # Do not echo an untrusted field, source, exception or machine identifier.
        throw 'DTO.InvalidSnapshotInput'
    }
    $fields = New-Object 'Collections.Generic.List[object]'
    $sources = New-Object 'Collections.Generic.List[object]'
    $changed = 0; $unchanged = 0; $unknown = 0
    foreach ($definition in $layout) {
        $leftSection = $left.Sections[$definition.Source]
        $rightSection = $right.Sections[$definition.Source]
        $sources.Add([pscustomobject][ordered]@{
            Source=$definition.Source
            BeforeStatus=(Get-DTOComparisonProperty $leftSection 'Status')
            BeforeReason=(Get-DTOComparisonProperty $leftSection 'Reason')
            BeforeCollectionComplete=(Get-DTOComparisonProperty $leftSection 'CollectionComplete')
            AfterStatus=(Get-DTOComparisonProperty $rightSection 'Status')
            AfterReason=(Get-DTOComparisonProperty $rightSection 'Reason')
            AfterCollectionComplete=(Get-DTOComparisonProperty $rightSection 'CollectionComplete')
        })
        $available = (Get-DTOComparisonProperty $leftSection 'CollectionComplete') -and
            (Get-DTOComparisonProperty $rightSection 'CollectionComplete')
        foreach ($field in $definition.Properties) {
            $multiple = $definition.Source -ceq 'Win32_Processor'
            $beforeValue = Get-DTOComparisonValue $leftSection $field $multiple
            $afterValue = Get-DTOComparisonValue $rightSection $field $multiple
            $reason = $null
            if (-not $available) {
                $status = 'Unknown'; $reason = 'IncompleteEvidence'; $unknown++
            } else {
                $equal = $true
                if ($multiple) {
                    $equal = $beforeValue.Count -eq $afterValue.Count
                    if ($equal) {
                        for ($i = 0; $i -lt $beforeValue.Count; $i++) {
                            if (-not [StringComparer]::Ordinal.Equals($beforeValue[$i], $afterValue[$i])) { $equal = $false; break }
                        }
                    }
                } else { $equal = [StringComparer]::Ordinal.Equals($beforeValue, $afterValue) }
                if ($equal) { $status = 'Unchanged'; $unchanged++ }
                else { $status = 'Changed'; $changed++ }
            }
            $fields.Add([pscustomobject][ordered]@{
                Source=$definition.Source; Field=$field; Status=$status
                Before=$beforeValue; After=$afterValue; Reason=$reason
            })
        }
    }
    $complete = $left.CollectionComplete -and $right.CollectionComplete -and $unknown -eq 0
    $status = if (-not $complete) { 'Unknown' } elseif ($changed -gt 0) { 'Changed' } else { 'Unchanged' }
    [pscustomobject][ordered]@{
        SchemaVersion=1; Product='DTO Imaging & Provisioning'; Version='0.2.0'
        AssessmentType='ReadOnlyBaselineComparison'
        BeforeCollectedAtUtc=$left.CollectedAtUtc; AfterCollectedAtUtc=$right.CollectedAtUtc
        Status=$status; CollectionComplete=$complete; IdentityEstablished=$false; DeploymentAccepted=$false
        Summary=[pscustomobject][ordered]@{
            TotalFieldCount=7; ComparedFieldCount=($changed + $unchanged)
            ChangedFieldCount=$changed; UnchangedFieldCount=$unchanged; UnknownFieldCount=$unknown
        }
        Coverage=[pscustomobject][ordered]@{
            BeforeCollectionComplete=$left.CollectionComplete; AfterCollectionComplete=$right.CollectionComplete
            Sources=@($sources.ToArray())
        }
        Fields=@($fields.ToArray())
        Notice='Observed fields only; workstation identity is not established. Incomplete evidence stays unknown. Hardware and OS details may be sensitive; review before sharing.'
    }
}

Export-ModuleMember -Function Compare-DTOWorkstationSnapshot
