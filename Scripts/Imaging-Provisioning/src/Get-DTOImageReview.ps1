#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ImagePath,[ValidateRange(0,65535)][int]$Index=0,[switch]$ComputeSha256)
Import-Module (Join-Path $PSScriptRoot 'DTOImaging.psm1') -Force -ErrorAction Stop
DTOImaging\Get-DTOImageReview @PSBoundParameters
