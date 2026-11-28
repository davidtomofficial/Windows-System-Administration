#Requires -Version 5.1
# Optional explanation layer. The original collector and report remain unchanged.
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'DeviceCare.psm1') -ErrorAction Stop
. (Join-Path $PSScriptRoot 'Explanation.ps1')
. (Join-Path $PSScriptRoot 'ExplanationPresentation.ps1')
Export-ModuleMember -Function New-DTODeviceCareExplanationRequest,Get-DTODeviceCareExplanation,ConvertTo-DTODeviceCareExplainedHtml
