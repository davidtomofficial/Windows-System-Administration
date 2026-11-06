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
 if(-not [string]::IsNullOrEmpty($env:COMPUTERNAME)){Check (-not $json.Contains($env:COMPUTERNAME)) 'no default host'}
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
 # DTO-DC-016: distinct raw measurements intentionally share a rounded display.
 # Defaults omit threshold arguments; configured cases must honor both overrides.
 Scenario 'normal'
 $thresholdSets=@(
    @{Name='default';Parameters=@{};DiskMinimum=15;MemoryMaximum=85;
      DiskFree=@((15GB-1),15GB,(15GB+1));MemoryFree=@(15040,15000,14960)},
    @{Name='configured';Parameters=@{MinimumDiskFreeGiB=20.25;MaximumMemoryUsedPercent=72.5};
      DiskMinimum=20.25;MemoryMaximum=72.5;
      DiskFree=@((20.25GB-1),20.25GB,(20.25GB+1));MemoryFree=@(27540,27500,27460)}
 )
 $positions=@('below','equal','above')
 $diskStates=@('Review','Observed','Observed')
 $memoryStates=@('Observed','Review','Review')
 foreach($thresholdSet in $thresholdSets){
    $parameters=$thresholdSet.Parameters
    for($i=0;$i -lt 3;$i++){
        $label=$thresholdSet.Name+' '+$positions[$i]
        $diskSnapshot=Get-DTODeviceCareSnapshot
        $diskSnapshot.SystemDisk.Data.FreeSpace=$thresholdSet.DiskFree[$i]
        $diskAssessment=Get-DTODeviceCareFindings -Snapshot $diskSnapshot @parameters
        $diskFinding=$diskAssessment.Findings|Where-Object {$_.Id -eq 'system-disk'}
        Check ($diskFinding.State -eq $diskStates[$i]) ('disk state '+$label)
        Check ($diskFinding.Observed -eq $thresholdSet.DiskMinimum) ('disk rounded display '+$label)
        Check ($diskAssessment.Thresholds.MinimumDiskFreeGiB -eq $thresholdSet.DiskMinimum -and
               $diskAssessment.Thresholds.MaximumMemoryUsedPercent -eq $thresholdSet.MemoryMaximum) ('disk effective thresholds '+$label)

        $memorySnapshot=Get-DTODeviceCareSnapshot
        $memorySnapshot.OS.Data.TotalVisibleMemorySize=100000
        $memorySnapshot.OS.Data.FreePhysicalMemory=$thresholdSet.MemoryFree[$i]
        $memoryAssessment=Get-DTODeviceCareFindings -Snapshot $memorySnapshot @parameters
        $memoryFinding=$memoryAssessment.Findings|Where-Object {$_.Id -eq 'memory'}
        Check ($memoryFinding.State -eq $memoryStates[$i]) ('memory state '+$label)
        Check ($memoryFinding.Observed -eq $thresholdSet.MemoryMaximum) ('memory rounded display '+$label)
        Check ($memoryAssessment.Thresholds.MinimumDiskFreeGiB -eq $thresholdSet.DiskMinimum -and
               $memoryAssessment.Thresholds.MaximumMemoryUsedPercent -eq $thresholdSet.MemoryMaximum) ('memory effective thresholds '+$label)
    }
 }
 $boundary=Get-DTODeviceCareSnapshot
 $boundary.ChangesAllowed=0
 Refuses {Get-DTODeviceCareFindings -Snapshot $boundary} 'numeric false refused'
 $sample|Add-Member -NotePropertyName PrivateIdentifier -NotePropertyValue 'DO-NOT-EXPORT'
 $html=ConvertTo-DTODeviceCareHtml -Assessment $sample
 Check (-not $html.Contains('DO-NOT-EXPORT')) 'extra properties not exported'
 Check ($html.Contains('data:image/svg+xml;base64,')) 'embedded approved artwork'
 Check ($html.Contains('<table>') -and $html.Contains('<details>')) 'readable findings and disclosure'
 $sample.MaintenanceAuthorized=0
 Refuses {ConvertTo-DTODeviceCareHtml -Assessment $sample} 'report numeric false refused'
 $sample.MaintenanceAuthorized=$false
 $sample.Findings[0].State='Healthy'
 Refuses {ConvertTo-DTODeviceCareHtml -Assessment $sample} 'unsupported state refused'
 $sample.Findings[0].State='Unknown';$sample.Findings[0].Observed=99
 $html=ConvertTo-DTODeviceCareHtml -Assessment $sample
 Check ($html.Contains('Not available')) 'unknown omits misleading number'

 Scenario 'normal';$dated=Get-DTODeviceCareFindings -Snapshot (Get-DTODeviceCareSnapshot)
 $dated.CollectedAtUtc='2026-11-05T12:34:56Z'
 $dated.Findings[0].Explanation='Literal {{DETAIL}} remains literal'
 $datedHtml=ConvertTo-DTODeviceCareHtml -Assessment $dated
 Check ($datedHtml.Contains('2026-11-05T12:34:56Z')) 'original timestamp retained'
 Check ($datedHtml.Contains('Literal {{DETAIL}} remains literal')) 'single-pass substitution'
 Check ($datedHtml.Contains('Disk minimum: 15 GiB')) 'effective threshold displayed'
 $dated.CollectedAtUtc='2026-11'
 Check ((ConvertTo-DTODeviceCareHtml -Assessment $dated).Contains('Observed at: Unknown')) 'partial timestamp unknown'
 $dated.Findings[1].Id='memory'
 Refuses {ConvertTo-DTODeviceCareHtml -Assessment $dated} 'duplicate finding refused'
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
