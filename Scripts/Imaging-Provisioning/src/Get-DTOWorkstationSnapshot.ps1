# Copyright (c) 2026 David Tom. DTO portfolio development preview.
# Read-only Windows workstation snapshot. No network, installation, or configuration changes.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This read-only assessment requires Windows.'
}

function Get-DTOCimSafe {
    param([Parameter(Mandatory=$true)][string]$ClassName)
    try {
        Get-CimInstance -ClassName $ClassName -ErrorAction Stop
    } catch {
        Write-Warning ('Unable to collect {0}: {1}' -f $ClassName, $_.Exception.Message)
        $null
    }
}

$os = Get-DTOCimSafe -ClassName 'Win32_OperatingSystem'
$system = Get-DTOCimSafe -ClassName 'Win32_ComputerSystem'
$bios = Get-DTOCimSafe -ClassName 'Win32_BIOS'
$cpu = Get-DTOCimSafe -ClassName 'Win32_Processor'

$result = [pscustomobject]@{
    SchemaVersion = 1
    Product = 'DTO Imaging & Provisioning'
    AssessmentType = 'ReadOnlyLocalSnapshot'
    CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
    ComputerName = $env:COMPUTERNAME
    OperatingSystem = if ($null -ne $os) { [string]$os.Caption } else { $null }
    OSVersion = if ($null -ne $os) { [string]$os.Version } else { $null }
    Manufacturer = if ($null -ne $system) { [string]$system.Manufacturer } else { $null }
    Model = if ($null -ne $system) { [string]$system.Model } else { $null }
    BIOSVersion = if ($null -ne $bios) { [string]$bios.SMBIOSBIOSVersion } else { $null }
    ProcessorName = if ($null -ne $cpu) { [string]($cpu | Select-Object -First 1 -ExpandProperty Name) } else { $null }
    CollectionComplete = ($null -ne $os -and $null -ne $system -and $null -ne $bios -and $null -ne $cpu)
    Notice = 'Local device details may be sensitive. Review before sharing.'
}
$result
