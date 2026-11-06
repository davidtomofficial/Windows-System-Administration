#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Native)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$script:passed=0
function Check([bool]$Valid,[string]$Label) { if(-not $Valid){throw ('FAILED '+$Label)}; $script:passed++ }
function Refuses([scriptblock]$Action,[string]$Label){$caught=$false;try{& $Action|Out-Null}catch{$caught=$true};Check $caught $Label}
foreach($f in Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {$_.Extension -in @('.ps1','.psm1')}){
 $tokens=$null;$errs=$null;[void][Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$tokens,[ref]$errs)
 Check ($errs.Count -eq 0) ('syntax '+$f.Name)
}
Import-Module (Join-Path $root 'src/DeviceCare.psm1') -Force
$module=Get-Module DeviceCare
$originalOS=$env:OS
$originalDrive=$env:SystemDrive
try{
 $env:OS='Windows_NT';$env:SystemDrive='C:'
 & $module {
    function script:Get-DTOCimData {
        param([string]$ClassName,[string]$Filter)
        if($script:Scenario -eq 'failed'){throw 'private paths should never leak'}
        if($script:Scenario -eq 'none'){return}
        if($ClassName -eq 'Win32_OperatingSystem'){
            $total=8192000; $free=if($script:Scenario -eq 'highmemory'){819200}else{4096000}
            if($script:Scenario -eq 'invalidmemory'){$free=9000000}
            return [pscustomobject]@{Caption='Fixture OS';Version='10.0.26100';OSArchitecture='64-bit';TotalVisibleMemorySize=$total;FreePhysicalMemory=$free;MachineName='PRIVATE-SERVER'}
        }
        if($ClassName -eq 'Win32_LogicalDisk'){
            $free=if($script:Scenario -eq 'lowdisk'){6GB}else{50GB}
            if($script:Scenario -eq 'invaliddisk'){$free=150GB}
            if($script:Scenario -eq 'duplicate'){return @([pscustomobject]@{Size=100GB;FreeSpace=50GB},[pscustomobject]@{Size=100GB;FreeSpace=50GB})}
            return [pscustomobject]@{Size=100GB;FreeSpace=$free;SerialNumber='PRIVATE-SERIAL'}
        }
        throw 'unexpected class'
    }
 }
 function Scenario([string]$Name){ & $module {param($v) $script:Scenario=$v} $Name }
 Scenario 'normal'
 $s=Get-DTODeviceCareSnapshot
 Check ($s.OS.Status -eq 'Observed' -and $s.SystemDisk.Status -eq 'Observed') 'observed sections'
 Check (-not $s.ChangesAllowed -and $null -eq $s.DeviceHealthy) 'withhold readiness'
 $json=$s|ConvertTo-Json -Depth 8
 Check (-not $json.Contains('PRIVATE-')) 'no extra identifiers'
 Check (-not $json.Contains($env:COMPUTERNAME)) 'no default host'
 $f=Get-DTODeviceCareFindings -Snapshot $s
 Check ($f.Findings.Count -eq 2 -and $f.Findings[0].State -eq 'Observed') 'normal findings'
 Check (-not $f.MaintenanceAuthorized -and $null -eq $f.DeviceReady) 'no maintenance authorization'
 Scenario 'highmemory';$f=Get-DTODeviceCareFindings -Snapshot (Get-DTODeviceCareSnapshot)
 Check ($f.Findings[0].State -eq 'Review') 'memory threshold'
 Scenario 'lowdisk';$f=Get-DTODeviceCareFindings -Snapshot (Get-DTODeviceCareSnapshot)
 Check ($f.Findings[1].State -eq 'Review') 'disk threshold'
 foreach($scenario in @('failed','none','duplicate','invalidmemory','invaliddisk')){
    Scenario $scenario;$s=Get-DTODeviceCareSnapshot;$f=Get-DTODeviceCareFindings -Snapshot $s
    Check (-not $s.ChangesAllowed) ('readonly '+$scenario)
    Check ($f.Findings.Count -eq 2) ('two findings '+$scenario)
    Check (-not (($s|ConvertTo-Json -Depth 8).Contains('PRIVATE-'))) ('sanitized '+$scenario)
    if($scenario -eq 'failed' -or $scenario -eq 'none') {Check (@($f.Findings|Where-Object {$_.State -ne 'Unknown'}).Count -eq 0) ('no false green '+$scenario)}
    if($scenario -eq 'invalidmemory'){Check ($f.Findings[0].State -eq 'Unknown') 'invalid memory unknown'}
    if($scenario -eq 'invaliddisk'){Check ($f.Findings[1].State -eq 'Unknown') 'invalid disk unknown'}
 }
 $env:SystemDrive='unknown';Scenario 'normal';$s=Get-DTODeviceCareSnapshot
 Check ($s.SystemDisk.Status -eq 'Unknown') 'unknown disk cannot query arbitrary drive'
 $env:SystemDrive='C:'
 Refuses {Get-DTODeviceCareFindings -Snapshot ([pscustomobject]@{SchemaVersion=1;Product='Wrong';AssessmentType='LocalReadOnly';ChangesAllowed=$false})} 'wrong product'
 Refuses {Get-DTODeviceCareFindings -Snapshot ([pscustomobject]@{SchemaVersion=1;Product='DeviceCare';AssessmentType='LocalReadOnly';ChangesAllowed=$true})} 'mutating snapshot'
 Refuses {Get-DTODeviceCareFindings -Snapshot (Get-DTODeviceCareSnapshot) -MinimumDiskFreeGiB 0} 'threshold validation'
 $sample=Get-DTODeviceCareFindings -Snapshot (Get-DTODeviceCareSnapshot)
 $sample.Findings[0].Explanation='<script>alert(1)</script>'
 $html=ConvertTo-DTODeviceCareHtml -Assessment $sample
 Check (-not $html.Contains('<script>')) 'no injection'
 $match=[regex]::Match($html,'(?s)<pre>(.*?)</pre>')
 Check $match.Success 'report region'
 $decoded=([Net.WebUtility]::HtmlDecode($match.Groups[1].Value)|ConvertFrom-Json)
 Check ($decoded.Findings[0].Explanation -ceq '<script>alert(1)</script>') 'html roundtrip data'
 Check $html.Contains("default-src 'none'") 'offline csp'
 foreach($c in @('#0F2747','#F8F9FB','#D4A574','#E6ECF2')){Check ($html.Contains($c)) ('palette '+$c)}
 Refuses {ConvertTo-DTODeviceCareHtml -Assessment ([pscustomobject]@{AssessmentType='ReadOnlyRecommendations';MaintenanceAuthorized=$true})} 'no authorized report'
 $env:OS='Linux';Refuses {Get-DTODeviceCareSnapshot} 'Windows only'
 if($Native){
    $env:OS=$originalOS;$env:SystemDrive=$originalDrive
    Remove-Module DeviceCare -Force
    Import-Module (Join-Path $root 'src/DeviceCare.psm1') -Force -ErrorAction Stop
    if($env:OS -ne 'Windows_NT'){throw 'native check requires Windows'}
    $actual=Get-DTODeviceCareSnapshot
    Check ($actual.AssessmentType -eq 'LocalReadOnly') 'native result'
    Check ($null -eq $actual.DeviceHealthy) 'native unknown readiness'
    Check (-not ($actual|ConvertTo-Json -Depth 6).Contains('ComputerName')) 'native no hostname key'
    $af=Get-DTODeviceCareFindings -Snapshot $actual
    Check ($af.Findings.Count -eq 2) 'native two findings'
    Check (-not $af.MaintenanceAuthorized) 'native no changes'
 }
}finally{$env:OS=$originalOS;$env:SystemDrive=$originalDrive}
Write-Output ('DTO_DEVICECARE_CHECKS_PASSED='+$script:passed+'; NATIVE='+[bool]$Native+'; PS='+$PSVersionTable.PSVersion.ToString())
