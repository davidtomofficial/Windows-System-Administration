#Requires -Version 5.1
# Original, read-only DTO personal demonstration. No external dependencies.
Set-StrictMode -Version Latest

function Get-DTOCimData {
    param([Parameter(Mandatory)][string]$ClassName,[string]$Filter)
    if ([string]::IsNullOrWhiteSpace($Filter)) {
        @(Get-CimInstance -ClassName $ClassName -OperationTimeoutSec 5 -ErrorAction Stop | Select-Object -First 2)
    } else {
        @(Get-CimInstance -ClassName $ClassName -Filter $Filter -OperationTimeoutSec 5 -ErrorAction Stop | Select-Object -First 2)
    }
}
function Get-DTOProperty {
    param($Object,[string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}
function ConvertTo-DTOFiniteDecimal {
    param($Value)
    if ($null -eq $Value -or $Value -is [bool]) { return $null }
    try {
        if ($Value -is [string] -and $Value -notmatch '^\d+(\.\d+)?$') { return $null }
        $d = [double]$Value
        if ([double]::IsNaN($d) -or [double]::IsInfinity($d) -or $d -lt 0) { return $null }
        return $d
    } catch { return $null }
}
function Get-DTORecord {
    param([string]$ClassName,[string[]]$Names,[string]$Filter)
    try {
        $items = @(Get-DTOCimData -ClassName $ClassName -Filter $Filter)
        if ($items.Count -ne 1) {
            return [pscustomobject]@{ Status='Unknown'; Reason='UnavailableOrAmbiguous'; Data=$null }
        }
        $record = [ordered]@{}
        foreach ($name in $Names) {
            $value = Get-DTOProperty $items[0] $name
            if ($null -eq $value -or ($value -is [string] -and $value.Length -gt 200)) {
                return [pscustomobject]@{Status='Unknown';Reason='MissingOrInvalidValue';Data=$null}
            }
            $record[$name] = $value
        }
        return [pscustomobject]@{ Status='Observed'; Reason=$null; Data=[pscustomobject]$record }
    } catch {
        # Provider error text may reveal private paths, account names or device identities.
        return [pscustomobject]@{Status='Unknown';Reason='ProviderFailed';Data=$null}
    }
}
function Get-DTODeviceCareSnapshot {
    [CmdletBinding()]
    param()
    if ($env:OS -ne 'Windows_NT') { throw 'DTO.WindowsRequired' }
    $os = Get-DTORecord -ClassName 'Win32_OperatingSystem' -Names @('Caption','Version','OSArchitecture','TotalVisibleMemorySize','FreePhysicalMemory')
    $drive = if ($env:SystemDrive -match '^[A-Z]:$') { $env:SystemDrive } else { $null }
    $disk = if ($null -ne $drive) {
        Get-DTORecord -ClassName 'Win32_LogicalDisk' -Filter ("DeviceID='"+$drive+"'") -Names @('Size','FreeSpace')
    } else { [pscustomobject]@{Status='Unknown';Reason='SystemDriveUnknown';Data=$null} }
    # No machine name, username, serial, user data, installed software, service account or domain collected.
    [pscustomobject]@{
        SchemaVersion=1
        Product='DeviceCare'
        Publisher='David Tom Official'
        AssessmentType='LocalReadOnly'
        CollectedAtUtc=[DateTime]::UtcNow.ToString('o')
        OS=$os
        SystemDisk=$disk
        DeviceHealthy=$null
        ChangesAllowed=$false
        DataHandling='Local result only. Review before sharing.'
    }
}
function Get-DTODeviceCareFindings {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot,[ValidateRange(1,1024)][double]$MinimumDiskFreeGiB=15,[ValidateRange(1,99)][double]$MaximumMemoryUsedPercent=85)
    if ((Get-DTOProperty $Snapshot 'SchemaVersion') -ne 1 -or
        (Get-DTOProperty $Snapshot 'Product') -cne 'DeviceCare' -or
        (Get-DTOProperty $Snapshot 'AssessmentType') -cne 'LocalReadOnly' -or
        (Get-DTOProperty $Snapshot 'ChangesAllowed') -isnot [bool] -or
        (Get-DTOProperty $Snapshot 'ChangesAllowed') -ne $false) { throw 'DTO.InvalidSnapshot' }
    $findings = New-Object 'System.Collections.Generic.List[object]'
    $os = Get-DTOProperty $Snapshot 'OS'
    $disk = Get-DTOProperty $Snapshot 'SystemDisk'
    if ((Get-DTOProperty $os 'Status') -cne 'Observed') {
        $findings.Add([pscustomobject]@{Id='memory';State='Unknown';Explanation='Memory evidence unavailable';Observed=$null})
    } else {
        $data=Get-DTOProperty $os 'Data'
        $total=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $data 'TotalVisibleMemorySize')
        $free=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $data 'FreePhysicalMemory')
        if ($null -eq $total -or $null -eq $free -or $total -le 0 -or $free -gt $total) {
            $findings.Add([pscustomobject]@{Id='memory';State='Unknown';Explanation='Memory values incomplete or invalid';Observed=$null})
        } else {
            $rawUsed=100.0 * ($total-$free)/$total
            $used=[math]::Round($rawUsed,1)
            $state=if($rawUsed -ge $MaximumMemoryUsedPercent){'Review'}else{'Observed'}
            $findings.Add([pscustomobject]@{Id='memory';State=$state;Explanation=if($state -eq 'Review'){'Memory usage meets or exceeds selected review threshold'}else{'Memory usage below selected review threshold'};Observed=$used;Units='percent'})
        }
    }
    if ((Get-DTOProperty $disk 'Status') -cne 'Observed') {
        $findings.Add([pscustomobject]@{Id='system-disk';State='Unknown';Explanation='System disk evidence unavailable';Observed=$null})
    } else {
        $data=Get-DTOProperty $disk 'Data'
        $size=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $data 'Size')
        $free=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $data 'FreeSpace')
        if($null -eq $size -or $null -eq $free -or $size -le 0 -or $free -gt $size) {
            $findings.Add([pscustomobject]@{Id='system-disk';State='Unknown';Explanation='Disk values incomplete or invalid';Observed=$null})
        } else {
            $rawGiB=$free/1GB
            $gib=[math]::Round($rawGiB,2)
            $state=if($rawGiB -lt $MinimumDiskFreeGiB){'Review'}else{'Observed'}
            $findings.Add([pscustomobject]@{Id='system-disk';State=$state;Explanation=if($state -eq 'Review'){'Available space below selected review threshold'}else{'Available space at or above selected review threshold'};Observed=$gib;Units='GiB'})
        }
    }
    [pscustomobject]@{
        SchemaVersion=1
        Product='DeviceCare'
        AssessmentType='ReadOnlyRecommendations'
        RulesVersion='dto-0.2'
        CollectedAtUtc=Get-DTOProperty $Snapshot 'CollectedAtUtc'
        Thresholds=[pscustomobject]@{MinimumDiskFreeGiB=$MinimumDiskFreeGiB;MaximumMemoryUsedPercent=$MaximumMemoryUsedPercent}
        DeviceReady=$null
        MaintenanceAuthorized=$false
        Findings=@($findings.ToArray())
        Note='A selected threshold is not a device health certification. Unknown never means passing.'
    }
}
. (Join-Path $PSScriptRoot 'Presentation.ps1')
Export-ModuleMember -Function Get-DTODeviceCareSnapshot,Get-DTODeviceCareFindings,ConvertTo-DTODeviceCareHtml
