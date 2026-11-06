#Requires -Version 5.1
# Copyright (c) 2026 David Tom. Read-only development preview.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DTOProfileClock { [DateTime]::UtcNow }
function Get-DTOProfileCurrentSid {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try { $identity.User.Value } finally { $identity.Dispose() }
}
function Invoke-DTOProfileQuery([string[]]$Properties, [int]$Timeout) {
    Get-CimInstance -ClassName Win32_UserProfile -Property $Properties -OperationTimeoutSec $Timeout -ErrorAction Stop
}
function Get-DTOProfileValue($InputObject, [string]$Name) {
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property -and $property.MemberType -in @('NoteProperty', 'Property')) {
        return $property.Value
    }
    return $null
}
function ConvertTo-DTOProfileSid($Value) {
    if ($Value -isnot [string] -or $Value.Length -gt 184 -or $Value -notmatch '^S-1-[0-9]+(?:-[0-9]+){1,15}$') {
        return $null
    }
    try { (New-Object Security.Principal.SecurityIdentifier $Value).Value }
    catch { return $null }
}
function ConvertTo-DTOProfileBoolean($Value) {
    if ($Value -is [bool]) { return $Value }
    return $null
}
function ConvertTo-DTOProfileDate($Value, [DateTime]$Now, [int]$Threshold) {
    $result = [ordered]@{ Status='Missing'; TimeUtc=$null; AgeDays=$null; Signal='Unknown' }
    if ($null -eq $Value) { return [pscustomobject]$result }
    $utc = $null
    if ($Value -is [DateTimeOffset]) { $utc = $Value.UtcDateTime }
    elseif ($Value -is [DateTime]) {
        if ($Value.Kind -eq [DateTimeKind]::Unspecified) {
            $result.Status='TimezoneUnknown'; return [pscustomobject]$result
        }
        if ($Value.Kind -eq [DateTimeKind]::Local -and
            ([TimeZoneInfo]::Local.IsInvalidTime($Value) -or [TimeZoneInfo]::Local.IsAmbiguousTime($Value))) {
            $result.Status='TimezoneUnknown'; return [pscustomobject]$result
        }
        $utc = $Value.ToUniversalTime()
    }
    else { $result.Status='Invalid'; return [pscustomobject]$result }
    if ($utc.Ticks -eq 0) { $result.Status='Invalid'; return [pscustomobject]$result }
    $result.TimeUtc = $utc.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
    if ($utc -gt $Now) { $result.Status='Future'; return [pscustomobject]$result }
    $elapsed = $Now - $utc
    $result.Status = 'Observed'
    $result.AgeDays = [Math]::Round($elapsed.TotalDays, 2)
    # Compare elapsed ticks, not the rounded presentation value.
    $result.Signal = if ($elapsed.Ticks -ge [TimeSpan]::FromDays($Threshold).Ticks) {'AtOrBeyondThreshold'} else {'BelowThreshold'}
    [pscustomobject]$result
}
function ConvertTo-DTOProfileStatus($Value) {
    $knownInteger = $Value -is [byte] -or $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or $Value -is [int64] -or $Value -is [uint64]
    if (-not $knownInteger -or $Value -lt 0 -or $Value -gt 4294967295) {
        return [pscustomobject]@{ Code=$null; Flags=@('Unknown'); Known=$false }
    }
    $code = [uint32]$Value
    $flags = New-Object 'Collections.Generic.List[string]'
    if ($code -eq 0) { $flags.Add('Undefined') }
    if (($code -band 1) -ne 0) { $flags.Add('Temporary') }
    if (($code -band 2) -ne 0) { $flags.Add('Roaming') }
    if (($code -band 4) -ne 0) { $flags.Add('Mandatory') }
    if (($code -band 8) -ne 0) { $flags.Add('Corrupted') }
    $known = ($code -le 15)
    if (-not $known) { $flags.Add('Unknown') }
    [pscustomobject]@{ Code=$code; Flags=@($flags.ToArray()); Known=$known }
}

function Get-DTOProfileInventory {
    [CmdletBinding()]
    param(
        [switch]$IncludeIdentifiers,
        [ValidateRange(1,36500)][int]$AgeThresholdDays=90,
        [ValidateRange(1,1024)][int]$MaximumRecords=256,
        [ValidateRange(1,30)][int]$OperationTimeoutSec=5
    )
    if ($env:OS -ne 'Windows_NT') { throw 'DTO.WindowsRequired' }
    $now = Get-DTOProfileClock
    if ($now -isnot [DateTime] -or $now.Kind -ne [DateTimeKind]::Utc) { throw 'DTO.InvalidCollectionClock' }
    $currentSid = $null
    try { $currentSid = ConvertTo-DTOProfileSid (Get-DTOProfileCurrentSid) } catch { $currentSid=$null }
    $identityStatus = if ($null -ne $currentSid) {'Observed'} else {'Unavailable'}
    $properties = @('SID','Loaded','Special','RoamingConfigured','Status','LastUseTime')
    if ($IncludeIdentifiers) { $properties += 'LocalPath' }
    $records = New-Object 'Collections.Generic.List[object]'
    $seen = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $counts = @{ Enumerated=0; Inspected=0; Uncertain=0; Duplicates=0; Failed=$false; ByteLimited=$false; Bytes=0 }
    $byteLimit = 131072
    try {
        Invoke-DTOProfileQuery $properties $OperationTimeoutSec | Select-Object -First ($MaximumRecords+1) | ForEach-Object {
            $counts.Enumerated++
            if ($counts.Enumerated -le $MaximumRecords) {
                $counts.Inspected++
                try {
                    $sid = ConvertTo-DTOProfileSid (Get-DTOProfileValue $_ 'SID')
                    $loaded = ConvertTo-DTOProfileBoolean (Get-DTOProfileValue $_ 'Loaded')
                    $special = ConvertTo-DTOProfileBoolean (Get-DTOProfileValue $_ 'Special')
                    $roaming = ConvertTo-DTOProfileBoolean (Get-DTOProfileValue $_ 'RoamingConfigured')
                    $status = ConvertTo-DTOProfileStatus (Get-DTOProfileValue $_ 'Status')
                    $lastUse = ConvertTo-DTOProfileDate (Get-DTOProfileValue $_ 'LastUseTime') $now $AgeThresholdDays
                    $current = if ($null -ne $sid -and $null -ne $currentSid) { $sid -ceq $currentSid } else { $null }
                    $reasons = New-Object 'Collections.Generic.List[string]'
                    $uncertain = $false
                    if ($null -eq $sid) { $reasons.Add('IdentityUnknown'); $uncertain=$true }
                    elseif (-not $seen.Add($sid)) { $reasons.Add('DuplicateIdentity'); $counts.Duplicates++; $uncertain=$true }
                    if ($null -eq $loaded) { $reasons.Add('LoadedStateUnknown'); $uncertain=$true }
                    elseif ($loaded) { $reasons.Add('LoadedProfile') }
                    if ($null -eq $special) { $reasons.Add('SpecialStateUnknown'); $uncertain=$true }
                    elseif ($special) { $reasons.Add('SpecialSystemProfile') }
                    if ($null -eq $current) { $reasons.Add('CurrentProcessProfileUnknown'); $uncertain=$true }
                    elseif ($current) { $reasons.Add('CurrentProcessProfile') }
                    if ($null -eq $roaming) { $reasons.Add('RoamingConfigurationUnknown'); $uncertain=$true }
                    elseif ($roaming) { $reasons.Add('RoamingConfigured') }
                    foreach ($flag in $status.Flags) {
                        if ($flag -in @('Temporary','Roaming','Mandatory','Corrupted')) { $reasons.Add('Status'+$flag) }
                    }
                    if (-not $status.Known) { $reasons.Add('StatusUnknown'); $uncertain=$true }
                    if ($lastUse.Status -ne 'Observed') { $reasons.Add('LastUse'+$lastUse.Status); $uncertain=$true }
                    # Inventory alone never establishes sessions, ownership or protected/shared-profile policy.
                    $reasons.Add('SessionCoverageUnknown')
                    $reasons.Add('ProtectedAndSharedPolicyUnknown')
                    $reasons.Add('OwnershipUnverified')
                    $row = [ordered]@{
                        ProfileNumber=$counts.Inspected
                        IdentityStatus=$(if ($null -ne $sid) {'Observed'} else {'Unknown'})
                        Loaded=$loaded; Special=$special; CurrentProcessProfile=$current
                        RoamingConfigured=$roaming; StatusCode=$status.Code; StatusFlags=$status.Flags
                        LastUseStatus=$lastUse.Status; LastUseTimeUtc=$lastUse.TimeUtc
                        AgeDays=$lastUse.AgeDays; AgeSignal=$lastUse.Signal
                        ExclusionReasons=@($reasons.ToArray()); ReviewDisposition='ExcludedFromSelection'
                        Selected=$false; CandidateEligible=$false; RemovalAllowed=$false
                    }
                    if ($IncludeIdentifiers) {
                        $row['SID']=$sid
                        $path=Get-DTOProfileValue $_ 'LocalPath'
                        if ($path -is [string] -and -not [string]::IsNullOrWhiteSpace($path) -and
                            $path.Length -le 1024 -and $path -notmatch '[\p{Cc}\p{Cf}]') {
                            $row['LocalPath']=$path
                        } else {
                            $row['LocalPath']=$null; $uncertain=$true
                            $row.ExclusionReasons += 'LocalPathUnknown'
                        }
                    }
                    $record=[pscustomobject]$row
                    $cost=[Text.Encoding]::UTF8.GetByteCount(($record | ConvertTo-Json -Depth 8 -Compress))
                    if ($counts.Bytes+$cost -gt $byteLimit) { $counts.ByteLimited=$true }
                    else { $records.Add($record); $counts.Bytes+=$cost }
                    if ($uncertain) { $counts.Uncertain++ }
                } catch { $counts.Uncertain++ }
            }
        }
    } catch { $counts.Failed=$true }
    $limited=$counts.Enumerated -gt $MaximumRecords
    $reasons=New-Object 'Collections.Generic.List[string]'
    if ($limited) { $reasons.Add('RecordLimit') }
    if ($counts.ByteLimited) { $reasons.Add('ByteLimit') }
    if ($counts.Failed) { $reasons.Add('QueryFailed') }
    if ($counts.Uncertain -gt 0) { $reasons.Add('UncertainRecord') }
    if ($counts.Duplicates -gt 0) { $reasons.Add('DuplicateIdentity') }
    if ($identityStatus -eq 'Unavailable') { $reasons.Add('CurrentIdentityUnavailable') }
    if ($counts.Enumerated -eq 0 -and -not $counts.Failed) { $reasons.Add('NoRows') }
    $complete=$counts.Enumerated -gt 0 -and $reasons.Count -eq 0
    $coverageStatus=if ($counts.Failed -and $counts.Enumerated -eq 0) {'Unavailable'}
        elseif ($counts.Enumerated -eq 0) {'NoData'} elseif ($complete) {'Complete'} else {'Partial'}
    [pscustomobject]@{
        SchemaVersion=1; Product='DTO Imaging & Provisioning'; Version='0.2.0'
        AssessmentType='ReadOnlyProfileInventory'; CollectedAtUtc=$now.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        AgeThresholdDays=$AgeThresholdDays; IdentifiersIncluded=[bool]$IncludeIdentifiers
        CurrentIdentityStatus=$identityStatus; SessionCoverage='NotCollected'
        CandidateSelectionImplemented=$false; ChangesAllowed=$false; RemovalAllowed=$false
        Coverage=[pscustomobject]@{
            Source='Win32_UserProfile'; Status=$coverageStatus; Reasons=@($reasons.ToArray())
            EnumeratedCount=$counts.Enumerated; InspectedCount=$counts.Inspected; ReturnedCount=$records.Count
            RecordLimit=$MaximumRecords; RecordByteLimit=$byteLimit; ProjectedRecordBytes=$counts.Bytes
            EnumerationComplete=(-not $limited -and -not $counts.Failed); CollectionComplete=$complete
        }
        Profiles=@($records.ToArray())
        Notice='Inventory only. The current process account is not necessarily the console user. Age and Loaded=false do not establish abandonment or session absence. All rows are excluded from selection. Review before sharing.'
    }
}
Export-ModuleMember -Function Get-DTOProfileInventory
