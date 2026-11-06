#requires -Version 5.1
[CmdletBinding()]
param([switch]$Native)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$script:comparisonPassed=0
Import-Module (Join-Path $root 'src/DTOSnapshotComparison.psm1') -Force
$comparisonModule=Get-Module DTOSnapshotComparison

function Check-Comparison([bool]$Condition,[string]$Name) {
    if(-not $Condition) {throw ('Comparison check failed: '+$Name)}
    $script:comparisonPassed++
}

function Refuses-Comparison([scriptblock]$Action,[string]$Name) {
    $message=$null
    try {& $Action | Out-Null} catch {$message=$_.Exception.Message}
    Check-Comparison ($message -ceq 'DTO.InvalidSnapshotInput') $Name
}

function New-SnapshotFixture {
    param([string]$Timestamp='2026-01-02T03:04:05.0000000Z',[string[]]$CpuNames=@('CPU A'))
    $definitions=@(
        @{Source='Win32_OperatingSystem'; Limit=1; Rows=@([pscustomobject]@{Caption='Windows fixture'; Version='10.0.10000'; OSArchitecture='64-bit'})}
        @{Source='Win32_ComputerSystem'; Limit=1; Rows=@([pscustomobject]@{Manufacturer='Fixture vendor'; Model='Fixture model'})}
        @{Source='Win32_BIOS'; Limit=1; Rows=@([pscustomobject]@{SMBIOSBIOSVersion='1.0'})}
        @{Source='Win32_Processor'; Limit=16; Rows=@($CpuNames | ForEach-Object {[pscustomobject]@{Name=$_}})}
    )
    $sections=@(foreach($definition in $definitions) {
        [pscustomobject][ordered]@{
            Source=$definition.Source; Status='Complete'; Reason=$null; Records=@($definition.Rows)
            EnumeratedCount=$definition.Rows.Count; InspectedCount=$definition.Rows.Count
            RecordLimit=$definition.Limit; RecordByteLimit=131072
            EnumerationComplete=$true; CollectionComplete=$true
        }
    })
    [pscustomobject][ordered]@{
        SchemaVersion=2; Product='DTO Imaging & Provisioning'; Version='0.2.0'
        AssessmentType='ReadOnlyLocalSnapshot'; CollectedAtUtc=$Timestamp
        ComputerNameIncluded=$false; Sections=$sections; CollectionComplete=$true
        DeploymentAccepted=$false; Notice='Synthetic test fixture'
    }
}

function Set-UnavailableFixture([object]$Snapshot,[int]$Index) {
    $section=$Snapshot.Sections[$Index]
    $section.Status='Unavailable'; $section.Reason='QueryFailed'; $section.Records=@()
    $section.EnumeratedCount=0; $section.InspectedCount=0
    $section.EnumerationComplete=$false; $section.CollectionComplete=$false
    $Snapshot.CollectionComplete=$false
}

function Find-ComparisonField([object]$Review,[string]$Source,[string]$Field) {
    @($Review.Fields | Where-Object {$_.Source -ceq $Source -and $_.Field -ceq $Field})[0]
}

$before=New-SnapshotFixture
$after=New-SnapshotFixture -Timestamp '2026-01-02T03:05:05Z'
$review=Compare-DTOWorkstationSnapshot -Before $before -After $after
Check-Comparison ($review.Status -ceq 'Unchanged' -and $review.CollectionComplete -and $review.Fields.Count -eq 7 -and $review.Summary.UnchangedFieldCount -eq 7 -and $review.Summary.ComparedFieldCount -eq 7 -and $review.Summary.UnknownFieldCount -eq 0) 'complete equal observations'
Check-Comparison ($review.SchemaVersion -eq 1 -and $review.AssessmentType -ceq 'ReadOnlyBaselineComparison' -and $review.IdentityEstablished -is [bool] -and -not $review.IdentityEstablished -and $review.DeploymentAccepted -is [bool] -and -not $review.DeploymentAccepted -and $null -eq $review.PSObject.Properties['HealthAssessed']) 'comparison makes no identity health or deployment claim'
$expectedKeys=@('Win32_OperatingSystem.Caption','Win32_OperatingSystem.Version','Win32_OperatingSystem.OSArchitecture','Win32_ComputerSystem.Manufacturer','Win32_ComputerSystem.Model','Win32_BIOS.SMBIOSBIOSVersion','Win32_Processor.Name')
Check-Comparison ((@($review.Fields | ForEach-Object {$_.Source+'.'+$_.Field}) -join '|') -ceq ($expectedKeys -join '|')) 'only seven documented fields in stable order'
Check-Comparison ($review.BeforeCollectedAtUtc -ceq $before.CollectedAtUtc -and $review.AfterCollectedAtUtc -ceq $after.CollectedAtUtc) 'independent capture timestamps retained'

$after.Sections[2].Records[0].SMBIOSBIOSVersion='2.0'
$review=Compare-DTOWorkstationSnapshot $before $after
$field=Find-ComparisonField $review 'Win32_BIOS' 'SMBIOSBIOSVersion'
Check-Comparison ($review.Status -ceq 'Changed' -and $review.Summary.ChangedFieldCount -eq 1 -and $review.Summary.UnchangedFieldCount -eq 6 -and $field.Before -ceq '1.0' -and $field.After -ceq '2.0' -and $field.Status -ceq 'Changed') 'BIOS change preserves independent before and after'
$after=New-SnapshotFixture
$after.Sections[1].Records[0].Model='fixture model'
Check-Comparison ((Compare-DTOWorkstationSnapshot $before $after).Status -ceq 'Changed') 'scalar comparison is ordinal and case sensitive'

$before=New-SnapshotFixture -CpuNames @('CPU B','CPU A','CPU A')
$after=New-SnapshotFixture -CpuNames @('CPU A','CPU B','CPU A')
$review=Compare-DTOWorkstationSnapshot $before $after
$field=Find-ComparisonField $review 'Win32_Processor' 'Name'
Check-Comparison ($review.Status -ceq 'Unchanged' -and ($field.Before -join '|') -ceq 'CPU A|CPU A|CPU B' -and ($field.After -join '|') -ceq 'CPU A|CPU A|CPU B') 'CPU order independent multiset retains duplicates'
$after=New-SnapshotFixture -CpuNames @('CPU A','CPU B')
Check-Comparison ((Compare-DTOWorkstationSnapshot $before $after).Summary.ChangedFieldCount -eq 1) 'CPU multiplicity change is observed'
$review=Compare-DTOWorkstationSnapshot (New-SnapshotFixture) (New-SnapshotFixture)
$field=Find-ComparisonField $review 'Win32_Processor' 'Name'
Check-Comparison ($field.Before -is [array] -and $field.After -is [array] -and $field.Before.Count -eq 1 -and $field.After.Count -eq 1) 'single CPU remains an array'

$before=New-SnapshotFixture; $after=New-SnapshotFixture
Set-UnavailableFixture $before 0
$review=Compare-DTOWorkstationSnapshot $before $after
$field=Find-ComparisonField $review 'Win32_OperatingSystem' 'Caption'
Check-Comparison ($review.Status -ceq 'Unknown' -and -not $review.CollectionComplete -and $review.Summary.UnknownFieldCount -eq 3 -and $review.Summary.ComparedFieldCount -eq 4 -and $null -eq $field.Before -and $field.After -ceq 'Windows fixture' -and $field.Reason -ceq 'IncompleteEvidence') 'missing before evidence stays unknown while after remains visible'
Check-Comparison ($review.Coverage.Sources.Count -eq 4 -and $review.Coverage.Sources[0].BeforeStatus -ceq 'Unavailable' -and $review.Coverage.Sources[0].BeforeReason -ceq 'QueryFailed' -and -not $review.Coverage.Sources[0].BeforeCollectionComplete -and $review.Coverage.Sources[0].AfterCollectionComplete) 'source coverage explains incomplete evidence'
$before=New-SnapshotFixture; $after=New-SnapshotFixture
Set-UnavailableFixture $after 2
$after.Sections[2].Status='NoData'; $after.Sections[2].Reason='NoRows'; $after.Sections[2].EnumerationComplete=$true
$review=Compare-DTOWorkstationSnapshot $before $after
$field=Find-ComparisonField $review 'Win32_BIOS' 'SMBIOSBIOSVersion'
Check-Comparison ($review.Status -ceq 'Unknown' -and $review.Summary.UnknownFieldCount -eq 1 -and $field.Before -ceq '1.0' -and $null -eq $field.After) 'no after rows are unknown instead of removed'
$before=New-SnapshotFixture; $after=New-SnapshotFixture
$after.Sections[0].Status='Partial'; $after.Sections[0].Reason='InvalidRecord'; $after.Sections[0].Records=@(); $after.Sections[0].CollectionComplete=$false; $after.CollectionComplete=$false
$after.Sections[2].Records[0].SMBIOSBIOSVersion='2.0'
$review=Compare-DTOWorkstationSnapshot $before $after
Check-Comparison ($review.Status -ceq 'Unknown' -and $review.Summary.UnknownFieldCount -eq 3 -and $review.Summary.ChangedFieldCount -eq 1) 'partial coverage takes aggregate precedence over a known change'
$before=New-SnapshotFixture; $after=New-SnapshotFixture
$before.CollectionComplete=$false
$review=Compare-DTOWorkstationSnapshot $before $after
Check-Comparison ($review.Status -ceq 'Unknown' -and -not $review.CollectionComplete -and $review.Summary.ComparedFieldCount -eq 7 -and $review.Summary.UnknownFieldCount -eq 0 -and -not $review.Coverage.BeforeCollectionComplete) 'incomplete snapshot keeps aggregate unknown even with complete sections'

$valid=New-SnapshotFixture
$bad=New-SnapshotFixture; $bad.SchemaVersion=1
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'schema mismatch refused'
$bad=New-SnapshotFixture; $bad.CollectionComplete='true'
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'string snapshot Boolean refused'
$bad=New-SnapshotFixture; $bad.Sections[0].EnumerationComplete=1
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'numeric section Boolean refused'
$bad=New-SnapshotFixture; $bad.DeploymentAccepted='false'
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'string deployment Boolean refused'
$bad=New-SnapshotFixture; $bad.DeploymentAccepted=$true
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'deployment acceptance refused'
$bad=New-SnapshotFixture; $bad.Sections=@($bad.Sections[0],$bad.Sections[0],$bad.Sections[2],$bad.Sections[3])
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'duplicate source refused'
$bad=New-SnapshotFixture; $bad.Sections=@($bad.Sections[0],$bad.Sections[1],$bad.Sections[2])
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'omitted source envelope refused'
$bad=New-SnapshotFixture; $bad.Sections[0].Records=$bad.Sections[0].Records[0]
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'non-array records refused'
$bad=New-SnapshotFixture; $bad.Sections[0].EnumeratedCount=2
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'inconsistent complete count metadata refused'
$bad=New-SnapshotFixture; Set-UnavailableFixture $bad 0; $bad.CollectionComplete=$true
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'contradictory complete snapshot refused'
$bad=New-SnapshotFixture; $bad.Sections[0].Records[0].Caption="private`ninvalid"
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'invalid text refused without echoing it'

$bad=New-SnapshotFixture -Timestamp '2026-02-30T03:04:05Z'
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'invalid calendar timestamp refused'
$bad=New-SnapshotFixture -Timestamp '2026-01-02T03:04:05+01:00'
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'non-UTC timestamp refused'
$later=New-SnapshotFixture -Timestamp '2026-01-02T03:04:06Z'
Refuses-Comparison {Compare-DTOWorkstationSnapshot $later $valid} 'reversed capture chronology refused'
$equivalent=New-SnapshotFixture -Timestamp '2026-01-02T03:04:05+00:00'
Check-Comparison ((Compare-DTOWorkstationSnapshot $valid $equivalent).Status -ceq 'Unchanged') 'equal UTC instants accept alternate zero-offset notation'

$before=New-SnapshotFixture; $after=New-SnapshotFixture
$before.ComputerNameIncluded=$true; $after.ComputerNameIncluded=$true
$before | Add-Member NoteProperty ComputerName 'PRIVATE-BEFORE-HOST'
$after | Add-Member NoteProperty ComputerName 'PRIVATE-AFTER-HOST'
$after | Add-Member NoteProperty SerialNumber 'PRIVATE-SERIAL'
$after.Sections[1].Records[0] | Add-Member NoteProperty UserName 'PRIVATE-USER'
$getterState=@{Called=$false}
$getter={ $getterState.Called=$true; return 'PRIVATE-GETTER' }.GetNewClosure()
$after | Add-Member ScriptProperty UnrequestedSecret $getter
$review=Compare-DTOWorkstationSnapshot $before $after
$serialized=$review | ConvertTo-Json -Depth 12 -Compress
Check-Comparison ($review.Status -ceq 'Unchanged' -and -not $getterState.Called -and $serialized -notmatch 'PRIVATE-|ComputerName|SerialNumber|UserName|UnrequestedSecret') 'sensitive extra properties are neither read nor copied'
$bad=New-SnapshotFixture
$bad.Sections[0].Records[0].PSObject.Properties.Remove('Caption')
$bad.Sections[0].Records[0] | Add-Member ScriptProperty Caption $getter
Refuses-Comparison {Compare-DTOWorkstationSnapshot $bad $valid} 'required ScriptProperty refused'
Check-Comparison (-not $getterState.Called) 'required ScriptProperty getter never executes'

$before=New-SnapshotFixture -CpuNames @('CPU B','CPU A')
$after=New-SnapshotFixture -CpuNames @('CPU A','CPU B')
$beforeJson=$before | ConvertTo-Json -Depth 12 -Compress
$afterJson=$after | ConvertTo-Json -Depth 12 -Compress
$review=Compare-DTOWorkstationSnapshot $before $after
Check-Comparison (($before | ConvertTo-Json -Depth 12 -Compress) -ceq $beforeJson -and ($after | ConvertTo-Json -Depth 12 -Compress) -ceq $afterJson) 'comparison never mutates input objects or CPU order'
$oldOS=$env:OS; $oldName=$env:COMPUTERNAME; $oldLocation=(Get-Location).Path
& $comparisonModule {
    $script:ForbiddenComparisonCalls=0
    foreach($name in @('Get-CimInstance','Invoke-DTOCimQuery','Get-Content','Set-Content','Add-Content','Out-File','Export-Clixml','Import-Clixml','Invoke-WebRequest','Invoke-RestMethod','Start-Process','Get-DTOWorkstationSnapshot','Get-Date')) {
        Set-Item -LiteralPath ('Function:script:'+$name) -Value {$script:ForbiddenComparisonCalls++; throw 'Unexpected environmental operation'}
    }
}
$review=Compare-DTOWorkstationSnapshot $before $after
$forbiddenCalls=& $comparisonModule {$script:ForbiddenComparisonCalls}
Check-Comparison ($forbiddenCalls -eq 0 -and $review.Status -ceq 'Unchanged' -and $env:OS -ceq $oldOS -and $env:COMPUTERNAME -ceq $oldName -and (Get-Location).Path -ceq $oldLocation) 'comparison needs no collector file network process clock or environment mutation'

Import-Module (Join-Path $root 'src/DTOImaging.psm1') -Force
$before=New-SnapshotFixture; $after=New-SnapshotFixture
$after.Sections[1].Records[0].Model='<script>alert("fixture")</script>&'
$review=Compare-DTOWorkstationSnapshot $before $after
$html=ConvertTo-DTOReviewHtml -Review $review
$pre=[regex]::Match($html,'(?s)<pre>(.*?)</pre>')
$roundtripAfter=$null
if($pre.Success) {
    $roundtrip=[Net.WebUtility]::HtmlDecode($pre.Groups[1].Value) | ConvertFrom-Json
    $roundtripAfter=(Find-ComparisonField $roundtrip 'Win32_ComputerSystem' 'Model').After
}
Check-Comparison ($pre.Success -and $roundtripAfter -ceq '<script>alert("fixture")</script>&' -and -not $html.Contains('<script>') -and $html.Contains('Content-Security-Policy') -and $html.Contains("default-src 'none'")) 'existing renderer encodes comparison values and retains CSP'

if($Native) {
    if($env:OS -cne 'Windows_NT') {throw 'Native comparison tests require Windows; not skipped.'}
    $nativeSnapshot=Get-DTOWorkstationSnapshot
    $nativeReview=Compare-DTOWorkstationSnapshot $nativeSnapshot $nativeSnapshot
    $expectedStatus=if($nativeSnapshot.CollectionComplete) {'Unchanged'} else {'Unknown'}
    Check-Comparison ($nativeReview.Fields.Count -eq 7 -and $nativeReview.Status -ceq $expectedStatus -and -not $nativeReview.IdentityEstablished -and -not $nativeReview.DeploymentAccepted) 'native collector objects satisfy comparison contract'
}

Write-Output ('DTO_COMPARISON_CHECKS_PASSED='+$script:comparisonPassed+'; NATIVE='+[bool]$Native+'; PS='+$PSVersionTable.PSVersion.ToString())
