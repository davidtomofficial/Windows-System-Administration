#Requires -Version 5.1
[CmdletBinding()]
param([ValidateRange(1,1024)][double]$MinimumDiskFreeGiB=15,[ValidateRange(1,99)][double]$MaximumMemoryUsedPercent=85)
Import-Module (Join-Path $PSScriptRoot 'DeviceCare.psm1') -Force -ErrorAction Stop
$snapshot=Get-DTODeviceCareSnapshot
Get-DTODeviceCareFindings -Snapshot $snapshot -MinimumDiskFreeGiB $MinimumDiskFreeGiB -MaximumMemoryUsedPercent $MaximumMemoryUsedPercent
