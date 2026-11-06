#Requires -Version 5.1
# Synthetic DTO-WSA-010 regressions. No device collection or persistent writes.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:comparisonPassed=0
function Assert-Comparison([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('COMPARISON FAILED: '+$Name) }
    $script:comparisonPassed++
}
function Refuses-Comparison([scriptblock]$Action, [string]$Code, [string]$Name) {
    $observed=$null
    try { & $Action | Out-Null } catch { $observed=$_.Exception.Message }
    Assert-Comparison ($observed -ceq $Code) ($Name+' uses expected error code')
}
function New-ComparisonSection([string]$Source, [object[]]$Records, [int]$Limit=1) {
    [pscustomobject]@{
        Source=$Source; Status='Complete'; Reason=$null; Records=@($Records)
        EnumeratedCount=$Records.Count; InspectedCount=$Records.Count
        RecordLimit=$Limit; RecordByteLimit=131072
        EnumerationComplete=$true; CollectionComplete=$true
    }
}
function New-ComparisonSnapshot([string]$Time='2026-11-06T17:00:00.0000000Z') {
    [pscustomobject]@{
        SchemaVersion=2; Product='DTO Imaging & Provisioning'; Version='0.2.0'
        AssessmentType='ReadOnlyLocalSnapshot'; CollectedAtUtc=$Time
        ComputerNameIncluded=$false; CollectionComplete=$true; DeploymentAccepted=$false
        Sections=@(
            New-ComparisonSection 'Win32_OperatingSystem' @([pscustomobject]@{
                Caption='Fictional operating system'; Version='Fixture A'; OSArchitecture='64-bit'
            })
            New-ComparisonSection 'Win32_ComputerSystem' @([pscustomobject]@{
                Manufacturer='Fictional maker'; Model='Fixture model'
            })
            New-ComparisonSection 'Win32_BIOS' @([pscustomobject]@{SMBIOSBIOSVersion='Fixture BIOS'})
            New-ComparisonSection 'Win32_Processor' @(
                [pscustomobject]@{Name='CPU B'}; [pscustomobject]@{Name='CPU A'}
            ) 16
        )
    }
}
function Compare-Fixture($After) {
    Compare-DTOWorkstationSnapshot -Before (New-ComparisonSnapshot) -After $After
}
function Get-ComparisonRow($Result, [string]$Source, [string]$Field) {
    @($Result.Rows | Where-Object {$_.Source -ceq $Source -and $_.Field -ceq $Field})[0]
}
$component=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $component 'src/DTOSnapshotComparison.psm1') -Force
$before=New-ComparisonSnapshot
$after=New-ComparisonSnapshot '2026-11-06T18:00:00.0000000Z'
$beforeJson=$before | ConvertTo-Json -Depth 10 -Compress
$afterJson=$after | ConvertTo-Json -Depth 10 -Compress
$r=Compare-DTOWorkstationSnapshot $before $after
Assert-Comparison ($r.Rows.Count -eq 7 -and $r.ChangedCount -eq 0 -and $r.UnchangedCount -eq 7 -and $r.UnknownCount -eq 0) 'seven unchanged rows'
Assert-Comparison $r.ComparisonComplete 'complete selected fields'
Assert-Comparison ($r.BeforeCollectedAtUtc -ceq $before.CollectedAtUtc -and $r.AfterCollectedAtUtc -ceq $after.CollectedAtUtc -and $r.Chronology -ceq 'Forward') 'original observation times'
Assert-Comparison (($before | ConvertTo-Json -Depth 10 -Compress) -ceq $beforeJson -and ($after | ConvertTo-Json -Depth 10 -Compress) -ceq $afterJson) 'inputs and original CPU order unchanged'
Assert-Comparison ($r.SameDeviceVerified -is [bool] -and $r.SameDeviceVerified -eq $false -and $r.DeploymentAccepted -eq $false -and $r.ChangesAllowed -eq $false) 'no authority promotion'
Assert-Comparison ($r.ComparisonScope -ceq 'SelectedObservationsOnly') 'declared comparison scope'
Assert-Comparison (($r.Rows | Where-Object {$_.Source -ceq 'Win32_OperatingSystem'}).Count -eq 3) 'fixed source mapping'
Assert-Comparison ($r.Rows[0].BeforeValues -is [Array] -and $r.Rows[0].BeforeValues.Count -eq 1 -and $r.Rows[6].BeforeValues.Count -eq 2) 'single and multiple value arrays'

$after.Sections[0].Records[0].Version='Fixture B'
$r=Compare-Fixture $after
Assert-Comparison ($r.ChangedCount -eq 1 -and $r.UnchangedCount -eq 6 -and (Get-ComparisonRow $r 'Win32_OperatingSystem' 'Version').State -ceq 'Changed') 'one OS version change'
$after.Sections[2].Status='Unavailable'; $after.Sections[2].Records=@(); $after.CollectionComplete=$false
$r=Compare-Fixture $after
Assert-Comparison ($r.ChangedCount -eq 1 -and $r.UnchangedCount -eq 5 -and $r.UnknownCount -eq 1 -and -not $r.ComparisonComplete) 'mixed change and missing BIOS'
Assert-Comparison ($r.Rows[5].AfterValues -is [Array] -and $r.Rows[5].AfterValues.Count -eq 0) 'empty value array preserved'

$after=New-ComparisonSnapshot
$after.Sections[3].Records=@($after.Sections[3].Records[1],$after.Sections[3].Records[0])
$after.Sections=@($after.Sections[3],$after.Sections[1],$after.Sections[0],$after.Sections[2])
$r=Compare-Fixture $after
Assert-Comparison ($r.UnchangedCount -eq 7) 'CPU and section ordering ignored'
$after=New-ComparisonSnapshot
$after.Sections[3].Records=@([pscustomobject]@{Name='CPU A'},[pscustomobject]@{Name='CPU A'})
$left=New-ComparisonSnapshot
$left.Sections[3].Records=@([pscustomobject]@{Name='CPU A'})
$left.Sections[3].EnumeratedCount=1; $left.Sections[3].InspectedCount=1
$r=Compare-DTOWorkstationSnapshot $left $after
Assert-Comparison ($r.Rows[6].State -ceq 'Changed' -and $r.Rows[6].AfterValues.Count -eq 2) 'CPU duplicate multiplicity retained'
$after=New-ComparisonSnapshot; $after.Sections[3].Records[0].Name='cpu b'
Assert-Comparison ((Compare-Fixture $after).Rows[6].State -ceq 'Changed') 'ordinal CPU casing'

foreach($state in @('Partial','NoData','Unavailable')) {
    $after=New-ComparisonSnapshot; $after.Sections[0].Status=$state
    $after.Sections[0].Reason='PRIVATE-PROVIDER-DETAIL'
    $r=Compare-Fixture $after
    Assert-Comparison ($r.UnknownCount -eq 3 -and $r.UnchangedCount -eq 4) ('unknown source '+$state)
    Assert-Comparison ($r.Rows[0].AfterValues.Count -eq 1 -and $r.Rows[0].AfterCoverage.Complete -eq $false) ('retain positive data '+$state)
    Assert-Comparison (-not (($r | ConvertTo-Json -Depth 10).Contains('PRIVATE-PROVIDER-DETAIL'))) ('sanitize reason '+$state)
}
$after=New-ComparisonSnapshot; $after.Sections=@($after.Sections[1],$after.Sections[2],$after.Sections[3])
$r=Compare-Fixture $after
Assert-Comparison ($r.UnknownCount -eq 3 -and $r.Rows[0].AfterCoverage.Status -ceq 'Missing') 'missing source'
foreach($source in @('Win32_OperatingSystem','win32_operatingsystem')) {
    $after=New-ComparisonSnapshot; $extra=(New-ComparisonSnapshot).Sections[0]; $extra.Source=$source
    $after.Sections+=@($extra); $r=Compare-Fixture $after
    Assert-Comparison ($r.UnknownCount -eq 3 -and $r.Rows[0].AfterCoverage.Status -ceq 'Ambiguous') ('duplicate source '+$source)
}
$after=New-ComparisonSnapshot; $after.Sections[0].Source='win32_operatingsystem'; $r=Compare-Fixture $after
Assert-Comparison ($r.UnknownCount -eq 3 -and $r.Rows[0].AfterCoverage.Status -ceq 'Invalid') 'wrong-case source'

$coverageCases=@(
    @{Name='false collection'; Change={param($s) $s.CollectionComplete=$false}},
    @{Name='string collection'; Change={param($s) $s.CollectionComplete='true'}},
    @{Name='null enumeration'; Change={param($s) $s.EnumerationComplete=$null}},
    @{Name='string enumeration'; Change={param($s) $s.EnumerationComplete='true'}},
    @{Name='wrong enumerated count'; Change={param($s) $s.EnumeratedCount=2}},
    @{Name='string inspected count'; Change={param($s) $s.InspectedCount='1'}},
    @{Name='zero limit'; Change={param($s) $s.RecordLimit=0}},
    @{Name='excessive limit'; Change={param($s) $s.RecordLimit=2}},
    @{Name='unexpected reason'; Change={param($s) $s.Reason='PRIVATE-REASON'}},
    @{Name='empty records'; Change={param($s) $s.Records=@()}},
    @{Name='scalar records'; Change={param($s) $s.Records=$s.Records[0]}},
    @{Name='null records'; Change={param($s) $s.Records=$null}}
)
foreach($case in $coverageCases) {
    $after=New-ComparisonSnapshot; & $case.Change $after.Sections[1]; $r=Compare-Fixture $after
    Assert-Comparison ($r.UnknownCount -eq 2 -and $r.UnchangedCount -eq 5) ('inconsistent coverage '+$case.Name)
}
$badValues=@('',42,('a'*257),("bad`nvalue"),('bad'+[char]0x200B+'value'))
foreach($value in $badValues) {
    $after=New-ComparisonSnapshot; $after.Sections[0].Records[0].Caption=$value; $r=Compare-Fixture $after
    Assert-Comparison ($r.UnknownCount -eq 1 -and $r.UnchangedCount -eq 6 -and $r.Rows[0].AfterCoverage.Reason -ceq 'MissingOrInvalidValue') 'invalid selected field'
}
$after=New-ComparisonSnapshot; $after.Sections[0].Records[0].PSObject.Properties.Remove('Caption')
Assert-Comparison ((Compare-Fixture $after).UnknownCount -eq 1) 'missing selected field'
$after=New-ComparisonSnapshot
$after.Sections[0].Records[0].PSObject.Properties.Remove('Caption')
$after.Sections[0].Records[0] | Add-Member -MemberType ScriptProperty -Name Caption -Value {throw 'GETTER-MUST-NOT-RUN'}
Assert-Comparison ((Compare-Fixture $after).UnknownCount -eq 1) 'script getter never evaluated'

$after=New-ComparisonSnapshot; $after.CollectionComplete=$false; $r=Compare-Fixture $after
Assert-Comparison ($r.ComparisonComplete -and $r.AfterSnapshotReportedComplete -eq $false) 'selected and reported completeness distinct'
$after=New-ComparisonSnapshot; $r=Compare-Fixture $after
Assert-Comparison ($r.Chronology -ceq 'SameTimestamp') 'equal times labeled'
$after=New-ComparisonSnapshot '2026-11-06T16:59:59.9999999Z'
Refuses-Comparison {Compare-Fixture $after} 'DTO.InvalidObservationOrder' 'reversed timestamps'
foreach($time in @($null,'not-a-time','2026-02-30T17:00:00.0000000Z','2026-11-06T17:00:00Z','2026-11-06T17:00:00.0000000+00:00')) {
    $after=New-ComparisonSnapshot; $after.CollectedAtUtc=$time
    Refuses-Comparison {Compare-Fixture $after} 'DTO.InvalidSnapshotTimestamp' 'invalid timestamp'
}
$after=New-ComparisonSnapshot
$after.CollectedAtUtc=[DateTime]::SpecifyKind([DateTime]::new(2026,11,6,18,0,0),[DateTimeKind]::Utc)
Assert-Comparison ((Compare-Fixture $after).AfterCollectedAtUtc -ceq '2026-11-06T18:00:00.0000000Z') 'UTC DateTime accepted'
$after.CollectedAtUtc=[DateTime]::SpecifyKind($after.CollectedAtUtc,[DateTimeKind]::Unspecified)
Refuses-Comparison {Compare-Fixture $after} 'DTO.InvalidSnapshotTimestamp' 'unspecified DateTime rejected'
$after=New-ComparisonSnapshot '2026-11-06T18:00:00.0000000Z'
$saved=$after | ConvertTo-Json -Depth 10 | ConvertFrom-Json
Assert-Comparison ((Compare-Fixture $saved).UnchangedCount -eq 7) 'saved JSON roundtrip'

$envelopeCases=@(
    @{Name='string schema'; Change={param($s) $s.SchemaVersion='2'}},
    @{Name='wrong schema'; Change={param($s) $s.SchemaVersion=1}},
    @{Name='product'; Change={param($s) $s.Product='wrong'}},
    @{Name='assessment'; Change={param($s) $s.AssessmentType='wrong'}},
    @{Name='string aggregate flag'; Change={param($s) $s.CollectionComplete='true'}},
    @{Name='numeric identity flag'; Change={param($s) $s.ComputerNameIncluded=0}},
    @{Name='numeric deployment flag'; Change={param($s) $s.DeploymentAccepted=0}},
    @{Name='deployment promotion'; Change={param($s) $s.DeploymentAccepted=$true}},
    @{Name='scalar sections'; Change={param($s) $s.Sections=$s.Sections[0]}},
    @{Name='too many sections'; Change={param($s) $s.Sections=@($s.Sections[0])*17}}
)
foreach($case in $envelopeCases) {
    $after=New-ComparisonSnapshot; & $case.Change $after
    Refuses-Comparison {Compare-Fixture $after} 'DTO.InvalidWorkstationSnapshot' ('invalid envelope '+$case.Name)
}
$after=New-ComparisonSnapshot; $after.Sections=@(); $r=Compare-Fixture $after
Assert-Comparison ($r.UnknownCount -eq 7 -and -not $r.ComparisonComplete) 'empty observations are all unknown'

$before=New-ComparisonSnapshot; $after=New-ComparisonSnapshot
$before | Add-Member -NotePropertyName ComputerName -NotePropertyValue 'PRIVATE-BEFORE-HOST'
$after | Add-Member -NotePropertyName ComputerName -NotePropertyValue 'PRIVATE-AFTER-HOST'
$before.ComputerNameIncluded=$true; $after.ComputerNameIncluded=$true
$after | Add-Member -NotePropertyName ArbitraryDetail -NotePropertyValue 'PRIVATE-ROOT'
$after.Sections[0] | Add-Member -NotePropertyName Detail -NotePropertyValue 'PRIVATE-SECTION'
$after.Sections[0].Records[0] | Add-Member -NotePropertyName SerialNumber -NotePropertyValue 'PRIVATE-RECORD'
$after.Sections+=@([pscustomobject]@{Source='Other';Data='PRIVATE-OTHER-SOURCE'})
$r=Compare-DTOWorkstationSnapshot $before $after
Assert-Comparison (-not (($r | ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) 'projected privacy at every level'
Assert-Comparison ($r.UnchangedCount -eq 7 -and $r.SameDeviceVerified -eq $false) 'different identifiers do not establish or alter pairing'

Import-Module (Join-Path $component 'src/DTOImaging.psm1') -Force
$after=New-ComparisonSnapshot; $after.Sections[0].Records[0].Version='<script>synthetic</script>'
$r=Compare-Fixture $after; $html=ConvertTo-DTOReviewHtml -Review $r
Assert-Comparison (-not $html.Contains('<script>')) 'comparison HTML encodes selected text'
$region=[regex]::Match($html,'(?s)<pre>(.*?)</pre>')
Assert-Comparison $region.Success 'comparison report evidence region'
$decoded=[Net.WebUtility]::HtmlDecode($region.Groups[1].Value) | ConvertFrom-Json
Assert-Comparison ($decoded.Rows[1].AfterValues[0] -ceq '<script>synthetic</script>' -and $decoded.ChangedCount -eq 1) 'HTML preserves comparison as data'
Write-Output ('DTO_COMPARISON_CHECKS_PASSED='+$script:comparisonPassed+'; PS='+$PSVersionTable.PSVersion.ToString())
