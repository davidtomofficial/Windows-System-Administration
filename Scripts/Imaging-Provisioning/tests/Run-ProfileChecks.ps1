#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Native)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$modulePath=Join-Path $root 'src/ProfileInventory.psm1'
$wrapperPath=Join-Path $root 'src/Get-DTOProfileInventory.ps1'
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
function Has-Property($Value,[string]$Name) {
    return ($null -ne $Value.PSObject.Properties[$Name])
}
function Check-NoSelection($Snapshot,[string]$Name) {
    Check (-not $Snapshot.CandidateSelectionImplemented -and -not $Snapshot.ChangesAllowed -and
        -not $Snapshot.RemovalAllowed) ($Name+' no mutation or candidate approval')
    Check ($Snapshot.SessionCoverage -ceq 'NotCollected') ($Name+' session coverage remains uncollected')
    foreach ($profile in $Snapshot.Profiles) {
        Check (-not $profile.Selected -and -not $profile.CandidateEligible -and
            -not $profile.RemovalAllowed -and $profile.ReviewDisposition -ceq 'ExcludedFromSelection') ($Name+' row excluded')
        foreach ($reason in @('SessionCoverageUnknown','ProtectedAndSharedPolicyUnknown','OwnershipUnverified')) {
            Check ($profile.ExclusionReasons -contains $reason) ($Name+' retains '+$reason)
        }
    }
}
foreach ($file in @($modulePath,$wrapperPath,$PSCommandPath)) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)
    Check ($errors.Count -eq 0) ('parse '+[IO.Path]::GetFileName($file))
}
$oldOS=$env:OS
try {
    $env:OS='Windows_NT'
    Import-Module $modulePath -Force
    $m=Get-Module ProfileInventory
    Check ($null -ne $m) 'module imported'
    Check (@($m.ExportedFunctions.Keys).Count -eq 1 -and
        $m.ExportedFunctions.ContainsKey('Get-DTOProfileInventory')) 'only inventory API exported'
    & $m {
        $script:TestClock=[DateTime]::SpecifyKind([DateTime]'2026-11-06T12:00:00',[DateTimeKind]::Utc)
        $script:TestScenario='good'
        $script:TestField=$null
        $script:TestReplacement=$null
        $script:RequestedProperties=@()
        $script:RequestedTimeout=$null
        function script:Get-DTOProfileClock { $script:TestClock }
        function script:Get-DTOProfileCurrentSid {
            if ($script:TestScenario -eq 'identity-unavailable') { throw 'PRIVATE-IDENTITY-ERROR' }
            if ($script:TestScenario -eq 'identity-invalid') { return 'PRIVATE-INVALID-IDENTITY' }
            'S-1-5-21-1000-2000-3000-1101'
        }
        function script:Invoke-DTOProfileQuery([string[]]$Properties,[int]$Timeout) {
            $script:RequestedProperties=@($Properties)
            $script:RequestedTimeout=$Timeout
            if ($script:TestScenario -eq 'throw') { throw 'PRIVATE-PROVIDER-ERROR' }
            if ($script:TestScenario -eq 'none') { return }
            $count=if ($script:TestScenario -eq 'bytes') {1024} elseif ($script:TestScenario -eq 'cap') {5}
                elseif ($script:TestScenario -eq 'duplicate') {2} else {1}
            for ($i=0;$i -lt $count;$i++) {
                $row=[ordered]@{
                    SID=('S-1-5-21-1000-2000-3000-'+(1001+$i))
                    LocalPath='C:\Users\PRIVATE-FIXTURE-PATH'
                    Loaded=$false; Special=$false; RoamingConfigured=$false
                    Status=[uint32]0; LastUseTime=$script:TestClock.AddDays(-120)
                    AccountName='PRIVATE-ACCOUNT-NAME'; ProviderExtra='PRIVATE-PROVIDER-EXTRA'
                }
                switch ($script:TestScenario) {
                    'current' { $row.SID='S-1-5-21-1000-2000-3000-1101' }
                    'loaded' { $row.Loaded=$true }
                    'special' { $row.Special=$true }
                    'roaming' { $row.RoamingConfigured=$true }
                    'duplicate' { $row.SID='S-1-5-21-1000-2000-3000-1001' }
                    'bytes' { $row.LocalPath='C:\Users\PRIVATE-'+(([string][char]0x4e00)*300)+$i }
                    'field' { $row[$script:TestField]=$script:TestReplacement }
                    'missing-field' { $row.Remove($script:TestField) }
                }
                [pscustomobject]$row
                if ($script:TestScenario -eq 'late') { throw 'PRIVATE-LATE-PROVIDER-ERROR' }
            }
        }
    }
    function Scenario([string]$Name,[string]$Field,$Replacement) {
        & $m {param($n,$f,$r) $script:TestScenario=$n; $script:TestField=$f; $script:TestReplacement=$r} $Name $Field $Replacement
    }
    $clock=[DateTime]::SpecifyKind([DateTime]'2026-11-06T12:00:00',[DateTimeKind]::Utc)
    Scenario 'good'
    $s=Get-DTOProfileInventory
    Check ($s.SchemaVersion -eq 1 -and $s.Version -ceq '0.2.0' -and
        $s.AssessmentType -ceq 'ReadOnlyProfileInventory') 'inventory schema and preview version'
    Check ($s.Coverage.Status -ceq 'Complete' -and $s.Coverage.CollectionComplete -and
        $s.Coverage.EnumerationComplete) 'valid inventory collection complete'
    Check ($s.Coverage.Source -ceq 'Win32_UserProfile' -and $s.Profiles.Count -eq 1 -and
        $s.Coverage.ReturnedCount -eq 1) 'provider source and returned count'
    Check ($s.Coverage.RecordLimit -eq 256 -and $s.Coverage.RecordByteLimit -eq 131072) 'declared default bounds'
    Check ($s.AgeThresholdDays -eq 90 -and $s.Profiles[0].AgeDays -eq 120 -and
        $s.Profiles[0].AgeSignal -ceq 'AtOrBeyondThreshold') 'old observation is an age signal'
    Check ($s.Profiles[0].StatusCode -eq 0 -and $s.Profiles[0].StatusFlags -contains 'Undefined') 'zero provider status is undefined'
    Check ($s.CurrentIdentityStatus -ceq 'Observed' -and $s.Profiles[0].CurrentProcessProfile -eq $false) 'current process identity compared'
    Check (-not $s.IdentifiersIncluded -and -not (Has-Property $s.Profiles[0] 'SID') -and
        -not (Has-Property $s.Profiles[0] 'LocalPath')) 'identifier properties absent by default'
    $json=$s | ConvertTo-Json -Depth 10
    Check (-not $json.Contains('PRIVATE-') -and -not $json.Contains('S-1-5-21-1000-2000-3000')) 'default output excludes fixture identities and extras'
    $requested=@(& $m {$script:RequestedProperties})
    Check ($requested -notcontains 'LocalPath' -and $requested -notcontains 'AccountName' -and
        $requested.Count -eq 6) 'default CIM projection does not request paths or names'
    Check-NoSelection $s 'complete old inventory'

    $s=Get-DTOProfileInventory -IncludeIdentifiers -OperationTimeoutSec 7
    Check ($s.IdentifiersIncluded -and $s.Profiles[0].SID -ceq 'S-1-5-21-1000-2000-3000-1001' -and
        $s.Profiles[0].LocalPath -ceq 'C:\Users\PRIVATE-FIXTURE-PATH') 'identifiers require explicit option'
    Check ((@(& $m {$script:RequestedProperties}) -contains 'LocalPath') -and
        (& $m {$script:RequestedTimeout}) -eq 7) 'opt-in projection and timeout forwarded'
    Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-ACCOUNT-NAME'))) 'identifier option does not disclose account names'

    foreach ($case in @(
        @{Scenario='loaded'; Field='Loaded'; Reason='LoadedProfile'},
        @{Scenario='current'; Field='CurrentProcessProfile'; Reason='CurrentProcessProfile'},
        @{Scenario='special'; Field='Special'; Reason='SpecialSystemProfile'},
        @{Scenario='roaming'; Field='RoamingConfigured'; Reason='RoamingConfigured'}
    )) {
        Scenario $case.Scenario; $s=Get-DTOProfileInventory
        Check ($s.Profiles[0].($case.Field) -eq $true -and
            $s.Profiles[0].ExclusionReasons -contains $case.Reason) ($case.Scenario+' positive exclusion retained')
        Check ($s.Profiles[0].AgeSignal -ceq 'AtOrBeyondThreshold') ($case.Scenario+' old date does not suppress active/protected evidence')
        Check-NoSelection $s $case.Scenario
    }
    foreach ($field in @('Loaded','Special','RoamingConfigured')) {
        foreach ($value in @('false',0,1,$null)) {
            Scenario 'field' $field $value; $s=Get-DTOProfileInventory
            Check ($null -eq $s.Profiles[0].$field -and $s.Coverage.Status -ceq 'Partial' -and
                -not $s.Coverage.CollectionComplete) ($field+' rejects non-Boolean evidence')
        }
    }
    foreach ($case in @('identity-unavailable','identity-invalid')) {
        Scenario $case; $s=Get-DTOProfileInventory
        Check ($s.CurrentIdentityStatus -ceq 'Unavailable' -and $null -eq $s.Profiles[0].CurrentProcessProfile -and
            $s.Coverage.Status -ceq 'Partial') ($case+' remains unknown')
        Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) ($case+' private failure sanitized')
        Check-NoSelection $s $case
    }
    foreach ($value in @($null,'not-a-sid',('S-1-5-'+('1-'*100)+'1'))) {
        Scenario 'field' 'SID' $value; $s=Get-DTOProfileInventory
        Check ($s.Profiles[0].IdentityStatus -ceq 'Unknown' -and $null -eq $s.Profiles[0].CurrentProcessProfile -and
            $s.Coverage.Status -ceq 'Partial') 'invalid profile identity remains unknown'
    }
    foreach ($value in @($null,"C:\Users\bad`npath",('x'*1025))) {
        Scenario 'field' 'LocalPath' $value; $s=Get-DTOProfileInventory -IncludeIdentifiers
        Check ($null -eq $s.Profiles[0].LocalPath -and $s.Coverage.Status -ceq 'Partial' -and
            $s.Profiles[0].ExclusionReasons -contains 'LocalPathUnknown') 'invalid opt-in path is withheld'
    }
    foreach ($case in @(
        @{Value=1; Flag='Temporary'}, @{Value=2; Flag='Roaming'},
        @{Value=4; Flag='Mandatory'}, @{Value=8; Flag='Corrupted'}
    )) {
        Scenario 'field' 'Status' $case.Value; $s=Get-DTOProfileInventory
        Check ($s.Profiles[0].StatusFlags -contains $case.Flag -and
            $s.Profiles[0].ExclusionReasons -contains ('Status'+$case.Flag)) ('provider flag '+$case.Flag)
        Check-NoSelection $s ('status '+$case.Flag)
    }
    Scenario 'field' 'Status' 18; $s=Get-DTOProfileInventory
    Check ($s.Profiles[0].StatusCode -eq 18 -and $s.Profiles[0].StatusFlags -contains 'Roaming' -and
        $s.Profiles[0].StatusFlags -contains 'Unknown' -and $s.Coverage.Status -ceq 'Partial') 'unknown status bits preserve known flags and uncertainty'
    foreach ($value in @($null,'2',-1,[double]2,([uint64]4294967296))) {
        Scenario 'field' 'Status' $value; $s=Get-DTOProfileInventory
        Check ($null -eq $s.Profiles[0].StatusCode -and $s.Profiles[0].StatusFlags -contains 'Unknown' -and
            $s.Coverage.Status -ceq 'Partial') 'invalid status is not coerced'
    }
    foreach ($case in @(
        @{Value=$null; Status='Missing'},
        @{Value='20260701120000.000000+000'; Status='Invalid'},
        @{Value=$clock.AddMinutes(1); Status='Future'},
        @{Value=[DateTime]::SpecifyKind($clock.AddDays(-120),[DateTimeKind]::Unspecified); Status='TimezoneUnknown'},
        @{Value=[DateTime]::SpecifyKind([DateTime]::MinValue,[DateTimeKind]::Utc); Status='Invalid'}
    )) {
        Scenario 'field' 'LastUseTime' $case.Value; $s=Get-DTOProfileInventory
        Check ($s.Profiles[0].LastUseStatus -ceq $case.Status -and $s.Profiles[0].AgeSignal -ceq 'Unknown' -and
            $null -eq $s.Profiles[0].AgeDays -and $s.Coverage.Status -ceq 'Partial') ('last-use '+$case.Status+' is not stale evidence')
    }
    foreach ($case in @(
        @{Value=$clock.AddDays(-90).AddTicks(1); Signal='BelowThreshold'},
        @{Value=$clock.AddDays(-90); Signal='AtOrBeyondThreshold'},
        @{Value=$clock.AddDays(-90).AddTicks(-1); Signal='AtOrBeyondThreshold'}
    )) {
        Scenario 'field' 'LastUseTime' $case.Value; $s=Get-DTOProfileInventory
        Check ($s.Profiles[0].AgeDays -eq 90 -and $s.Profiles[0].AgeSignal -ceq $case.Signal) 'age threshold uses elapsed time before rounding'
    }
    $offsetDate=[DateTimeOffset]::Parse('2026-10-17T14:00:00+02:00',[Globalization.CultureInfo]::InvariantCulture)
    Scenario 'field' 'LastUseTime' $offsetDate; $s=Get-DTOProfileInventory -AgeThresholdDays 20
    Check ($s.Profiles[0].LastUseStatus -ceq 'Observed' -and $s.Profiles[0].AgeDays -eq 20 -and
        $s.Profiles[0].LastUseTimeUtc -ceq '2026-10-17T12:00:00.0000000Z' -and
        $s.Profiles[0].AgeSignal -ceq 'AtOrBeyondThreshold') 'known offset normalized and explicit age threshold honored'

    Scenario 'duplicate'; $s=Get-DTOProfileInventory
    Check ($s.Profiles.Count -eq 2 -and $s.Coverage.Status -ceq 'Partial' -and
        $s.Coverage.Reasons -contains 'DuplicateIdentity' -and
        $s.Profiles[1].ExclusionReasons -contains 'DuplicateIdentity') 'duplicate identities retained with uncertainty'
    Scenario 'cap'; $s=Get-DTOProfileInventory -MaximumRecords 3
    Check ($s.Coverage.Status -ceq 'Partial' -and $s.Coverage.EnumeratedCount -eq 4 -and
        $s.Coverage.InspectedCount -eq 3 -and $s.Profiles.Count -eq 3 -and
        -not $s.Coverage.EnumerationComplete -and $s.Coverage.Reasons -contains 'RecordLimit') 'sentinel exposes record truncation'
    Scenario 'bytes'; $s=Get-DTOProfileInventory -MaximumRecords 1024 -IncludeIdentifiers
    Check ($s.Coverage.Status -ceq 'Partial' -and $s.Coverage.Reasons -contains 'ByteLimit' -and
        $s.Coverage.ProjectedRecordBytes -le 131072 -and $s.Profiles.Count -gt 0 -and
        $s.Profiles.Count -lt 1024) 'UTF8 budget bounds retained observations'
    Scenario 'late'; $s=Get-DTOProfileInventory
    Check ($s.Coverage.Status -ceq 'Partial' -and $s.Profiles.Count -eq 1 -and
        $s.Coverage.Reasons -contains 'QueryFailed' -and -not $s.Coverage.EnumerationComplete) 'late provider failure preserves earlier observation'
    Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) 'late provider exception sanitized'
    Scenario 'throw'; $s=Get-DTOProfileInventory
    Check ($s.Coverage.Status -ceq 'Unavailable' -and $s.Profiles.Count -eq 0 -and
        -not $s.Coverage.CollectionComplete) 'provider failure is unavailable evidence'
    Check (-not (($s|ConvertTo-Json -Depth 10).Contains('PRIVATE-'))) 'immediate provider exception sanitized'
    Scenario 'none'; $s=Get-DTOProfileInventory
    Check ($s.Coverage.Status -ceq 'NoData' -and $s.Profiles.Count -eq 0 -and
        -not $s.Coverage.CollectionComplete) 'empty inventory is not absence proof'
    Check-NoSelection $s 'empty inventory'
    Scenario 'missing-field' 'Loaded'; $s=Get-DTOProfileInventory
    Check ($null -eq $s.Profiles[0].Loaded -and $s.Coverage.Status -ceq 'Partial') 'absent property remains unknown'

    Refuses {Get-DTOProfileInventory -MaximumRecords 0} 'zero record bound refused'
    Refuses {Get-DTOProfileInventory -MaximumRecords 1025} 'excessive record bound refused'
    Refuses {Get-DTOProfileInventory -OperationTimeoutSec 0} 'zero timeout refused'
    Refuses {Get-DTOProfileInventory -OperationTimeoutSec 31} 'excessive timeout refused'
    Refuses {Get-DTOProfileInventory -AgeThresholdDays 0} 'zero age threshold refused'
    Refuses {Get-DTOProfileInventory -AgeThresholdDays 36501} 'excessive age threshold refused'
    $env:OS='not-windows'
    Refuses {Get-DTOProfileInventory} 'non-Windows refused'
    $env:OS='Windows_NT'
    & $m { $script:TestClock=[DateTime]::SpecifyKind($script:TestClock,[DateTimeKind]::Unspecified) }
    Refuses {Get-DTOProfileInventory} 'ambiguous collection clock refused'

    if ($Native) {
        Check ($oldOS -ceq 'Windows_NT') 'native checks require a Windows host'
        Remove-Module ProfileInventory -Force
        # The entry point imports a clean module. No fixture functions survive this call.
        $nativeSnapshot=& $wrapperPath -MaximumRecords 16 -AgeThresholdDays 120 -OperationTimeoutSec 10
        Check ($nativeSnapshot.Coverage.Source -ceq 'Win32_UserProfile' -and
            $nativeSnapshot.Profiles.Count -gt 0 -and $nativeSnapshot.Profiles.Count -le 16) 'native provider returns bounded profile observations'
        Check ($nativeSnapshot.AgeThresholdDays -eq 120 -and $nativeSnapshot.Coverage.RecordLimit -eq 16) 'native entry point forwards options'
        Check (-not $nativeSnapshot.IdentifiersIncluded) 'native identifiers omitted'
        foreach ($profile in $nativeSnapshot.Profiles) {
            Check (-not (Has-Property $profile 'SID') -and -not (Has-Property $profile 'LocalPath')) 'native identity fields absent'
        }
        Check-NoSelection $nativeSnapshot 'native inventory'
    }
}
finally {
    $env:OS=$oldOS
    Remove-Module ProfileInventory -Force -ErrorAction SilentlyContinue
}
Write-Output ('DTO_PROFILE_CHECKS_PASSED='+$script:passed+'; NATIVE='+[bool]$Native+'; PS='+$PSVersionTable.PSVersion.ToString())
