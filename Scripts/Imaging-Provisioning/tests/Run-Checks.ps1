#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Native)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$script:passed=0
function Check([bool]$Condition,[string]$Name) {
    if (-not $Condition) { throw ('FAILED: '+$Name) }
    $script:passed++
}
function Refuses([scriptblock]$Action,[string]$Name) {
    $failed=$false
    try { & $Action | Out-Null } catch { $failed=$true }
    Check $failed $Name
}
foreach ($file in Get-ChildItem $root -Recurse -File | Where-Object {$_.Extension -in @('.ps1','.psm1')}) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    Check ($errors.Count -eq 0) ('parse '+$file.Name)
}
Import-Module (Join-Path $root 'src/DTOImaging.psm1') -Force
$m=Get-Module DTOImaging
Check ((Get-DTOProduct).version -ceq '0.2.0') 'product version'
$oldOS=$env:OS; $oldName=$env:COMPUTERNAME
$temp=Join-Path ([IO.Path]::GetTempPath()) ('dto-imaging-tests-'+[guid]::NewGuid().ToString('N'))
try {
    $env:OS='Windows_NT'; $env:COMPUTERNAME='DTO-TEST-DEVICE'
    & $m {
        function script:Invoke-DTOCimQuery($ClassName,$Properties,$Timeout) {
            if ($script:Scenario -eq 'throw') { throw 'PRIVATE-TEST-DETAIL' }
            if ($script:Scenario -eq 'none') { return }
            if ($ClassName -eq 'Win32_Service') {
                $n=if ($script:Scenario -eq 'bytes') {200} elseif ($script:Scenario -eq 'cap') {5} else {2}
                for ($i=0;$i -lt $n;$i++) {
                    $name=if ($script:Scenario -eq 'duplicate') {'same'} else {'Svc'+$i}
                    $display=if ($script:Scenario -eq 'bytes') {([string][char]0x4e00)*256} else {'Fixture service'}
                    $state=if ($script:Scenario -eq 'state') {'Broken'} else {'Stopped'}
                    [pscustomobject]@{Name=$name;DisplayName=$display;State=$state;StartMode='Manual';PathName='PRIVATE-PATH';StartName='PRIVATE-ACCOUNT'}
                    if ($script:Scenario -eq 'late') { throw 'PRIVATE-LATE-DETAIL' }
                }
                return
            }
            if ($ClassName -eq 'Win32_Processor') {
                $n=if ($script:Scenario -eq 'manycpu') {20} else {1}
                for($i=0;$i -lt $n;$i++) {[pscustomobject]@{Name='Fixture processor'}}
                return
            }
            $row=[ordered]@{}
            foreach($p in $Properties) {$row[$p]='Fixture value'}
            $row['SerialNumber']='PRIVATE-SERIAL'; $row['Name']='PRIVATE-HOST'
            if ($script:Scenario -eq 'missing') {$row.Remove($Properties[0])}
            if ($script:Scenario -eq 'empty') {$row[$Properties[0]]=' '}
            if ($script:Scenario -eq 'control') {$row[$Properties[0]]="bad`nvalue"}
            if ($script:Scenario -eq 'long') {$row[$Properties[0]]='a'*257}
            [pscustomobject]$row
        }
    }
    function Scenario([string]$Value) { & $m {param($v) $script:Scenario=$v} $Value }
    Scenario 'good'
    $s=Get-DTOWorkstationSnapshot
    Check $s.CollectionComplete 'normal complete'
    Check ($s.Sections.Count -eq 4) 'four sections'
    Check (-not $s.ComputerNameIncluded) 'identifier opt-in default'
    $json=$s | ConvertTo-Json -Depth 10
    Check (-not $json.Contains('DTO-TEST-DEVICE')) 'no default host value'
    Check (-not $json.Contains('PRIVATE-')) 'provider extras removed'
    Check (-not $s.DeploymentAccepted) 'no deployment approval'
    $s=Get-DTOWorkstationSnapshot -IncludeComputerName
    Check ($s.ComputerName -ceq 'DTO-TEST-DEVICE') 'explicit identifier consent'
    foreach($case in @('none','missing','empty','control','long','throw','manycpu')) {
        Scenario $case; $s=Get-DTOWorkstationSnapshot
        Check (-not $s.CollectionComplete) ('incomplete '+$case)
        Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) ('sanitized '+$case)
    }
    Scenario 'good'; $s=Get-DTOServiceSnapshot
    Check $s.Section.CollectionComplete 'service complete'
    Check ($s.Section.Records[0].State -ceq 'Stopped') 'stopped retained without fault inference'
    Check (-not $s.HealthAssessed -and -not $s.ChangesAllowed) 'service non-mutating'
    Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) 'no service accounts or commands'
    foreach($case in @('late','duplicate','cap','state','bytes')) {
        Scenario $case
        $limit=if($case -eq 'cap'){3}else{1024}
        $s=Get-DTOServiceSnapshot -MaximumRecords $limit
        Check ($s.Section.Status -ceq 'Partial') ('service partial '+$case)
        Check (-not $s.Section.CollectionComplete) ('service incomplete '+$case)
        if($case -eq 'late') {Check ($s.Section.Records.Count -eq 1) 'late failure retains positive evidence'}
        if($case -eq 'cap') {Check ($s.Section.EnumeratedCount -eq 4 -and $s.Section.InspectedCount -eq 3) 'sentinel counted'}
        if($case -eq 'bytes') {Check ($s.Section.Reason -ceq 'ByteLimit') 'UTF8 byte cap'}
    }
    Scenario 'none'; Check ((Get-DTOServiceSnapshot).Section.Status -ceq 'NoData') 'empty is not absence proof'
    Refuses {Get-DTOWorkstationSnapshot -OperationTimeoutSec 0} 'invalid timeout'
    $env:OS='not-windows'
    Refuses {Get-DTOWorkstationSnapshot} 'wrong OS refused'
    $env:OS='Windows_NT'
    $html=ConvertTo-DTOReviewHtml ([pscustomobject]@{Test='<script>alert("x")</script>'})
    Check (-not $html.Contains('<script>')) 'HTML escaped'
    $pre=[regex]::Match($html,'(?s)<pre>(.*?)</pre>')
    Check $pre.Success 'HTML evidence region'
    $roundtrip=[Net.WebUtility]::HtmlDecode($pre.Groups[1].Value) | ConvertFrom-Json
    Check ($roundtrip.Test -ceq '<script>alert("x")</script>') 'malicious text roundtrips only as data'
    Check ($html.Contains("default-src 'none'")) 'no external resources'
    foreach($color in @('#0F2747','#F8F9FB','#D4A574','#E6ECF2')) {Check $html.Contains($color) ('DTO color '+$color)}
    # Native path checks use disposable files; mocked DISM returns metadata only.
    if($oldOS -eq 'Windows_NT') {
        New-Item -ItemType Directory -Path $temp | Out-Null
        $wim=Join-Path $temp 'fixture.wim'; [IO.File]::WriteAllText($wim,'synthetic')
        & $m {
            function script:Invoke-DTOImageQuery($Path,$Index) {
                if($script:Scenario -eq 'throw') {throw 'PRIVATE-IMAGE-PATH'}
                if($script:Scenario -eq 'none') {return}
                if($script:Scenario -eq 'changed') {[IO.File]::AppendAllText($Path,'changed')}
                if($script:Scenario -eq 'badindex') {[pscustomobject]@{ImageIndex='1';ImageName='Fixture'};return}
                [pscustomobject]@{ImageIndex=1;ImageName='Fixture';ImagePath='PRIVATE-IMAGE-PATH'}
                if($script:Scenario -eq 'late') {throw 'PRIVATE-IMAGE-PATH'}
                if($script:Scenario -eq 'duplicate') {[pscustomobject]@{ImageIndex=1;ImageName='Duplicate'}}
            }
        }
        Scenario 'good'; $r=Get-DTOImageReview -ImagePath $wim -ComputeSha256
        Check ($r.Status -ceq 'Observed') 'image metadata observed'
        Check ($r.Sha256 -match '^[A-F0-9]{64}$') 'hash requested'
        Check (-not $r.DeploymentAccepted -and -not $r.PathIncluded) 'image not deployable and path omitted'
        Check (-not (($r|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) 'image projection'
        Check ((Get-DTOImageReview $wim).HashStatus -ceq 'NotRequested') 'hash not implicit'
        Check ((Get-DTOImageReview $wim -Index 2).Status -ceq 'Partial') 'index mismatch'
        foreach($case in @('throw','none','badindex','duplicate','late','changed')) {
            Scenario $case; $r=Get-DTOImageReview $wim
            Check ($r.Status -cne 'Observed') ('image failure '+$case)
            Check (-not $r.DeploymentAccepted) ('no promotion '+$case)
        }
        Scenario 'good'
        Refuses {Get-DTOImageReview '\\server\share\image.wim'} 'UNC refused'
        Refuses {Get-DTOImageReview 'C:\image.wim:stream'} 'ADS refused'
        Refuses {Get-DTOImageReview 'image.wim'} 'relative path refused'
        Refuses {Get-DTOImageReview (Join-Path $temp 'missing.wim')} 'missing image refused'
        Refuses {Get-DTOImageReview $wim -Index -1} 'invalid index refused'
        if($Native) {
            Remove-Module DTOImaging -Force
            Import-Module (Join-Path $root 'src/DTOImaging.psm1') -Force
            $native=Get-DTOWorkstationSnapshot
            Check ($native.Sections.Count -eq 4) 'native projected sections'
            Check (-not $native.ComputerNameIncluded) 'native identifiers omitted'
            Check (@($native.Sections|Where-Object {$_.RecordLimit -gt 0}).Count -eq 4) 'native limits retained'
            $services=Get-DTOServiceSnapshot
            Check ($services.Section.Records.Count -gt 0) 'native service rows'
            Check (-not $services.HealthAssessed) 'native service no health claim'
            $capture=Join-Path $temp 'capture'; New-Item -ItemType Directory -Path $capture | Out-Null
            [IO.File]::WriteAllText((Join-Path $capture 'fixture.txt'),'DTO synthetic image fixture - not an operating system')
            $nativeWim=Join-Path $temp 'native.wim'
            Dism\New-WindowsImage -ImagePath $nativeWim -CapturePath $capture -Name 'DTO synthetic fixture' -ErrorAction Stop | Out-Null
            $before=(Get-FileHash -LiteralPath $nativeWim -Algorithm SHA256).Hash
            $r=Get-DTOImageReview $nativeWim -Index 1 -ComputeSha256
            Check ($r.Status -ceq 'Observed') 'native WIM inspection'
            Check ($r.Images.Count -eq 1 -and $r.Images[0].Index -eq 1) 'native WIM selected index'
            Check ($r.Sha256 -ceq $before) 'native WIM stable hash'
            Check ((Get-FileHash -LiteralPath $nativeWim -Algorithm SHA256).Hash -ceq $before) 'native WIM not modified'
            Check (-not $r.DeploymentAccepted) 'native WIM no deployment acceptance'
        }
    } elseif($Native) {throw 'Native tests require Windows; not skipped.'}
} finally {
    $env:OS=$oldOS; $env:COMPUTERNAME=$oldName
    if(Test-Path -LiteralPath $temp) {Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output ('DTO_CHECKS_PASSED='+$script:passed+'; NATIVE='+[bool]$Native+'; PS='+$PSVersionTable.PSVersion.ToString())
