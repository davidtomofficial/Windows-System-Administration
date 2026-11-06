#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$IncludeIdentifiers,
    [ValidateRange(1,36500)][int]$AgeThresholdDays=90,
    [ValidateRange(1,1024)][int]$MaximumRecords=256,
    [ValidateRange(1,30)][int]$OperationTimeoutSec=5
)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'ProfileInventory.psm1') -Force
Get-DTOProfileInventory @PSBoundParameters
