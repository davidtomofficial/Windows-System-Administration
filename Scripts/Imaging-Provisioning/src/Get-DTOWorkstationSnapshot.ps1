#Requires -Version 5.1
[CmdletBinding()]
param([switch]$IncludeComputerName,[ValidateRange(1,30)][int]$OperationTimeoutSec=5)
Import-Module (Join-Path $PSScriptRoot 'DTOImaging.psm1') -Force -ErrorAction Stop
DTOImaging\Get-DTOWorkstationSnapshot @PSBoundParameters
