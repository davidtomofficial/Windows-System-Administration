# Compare selected workstation observations

**DTO-WSA-010 / DTO-IMG-004 and DTO-IMG-007.** This implements the before/after observation comparison portion of the handoff backlog. It is a local, read-only development preview. Full handoff acceptance remains open.

## What this answers

Given two selected schema 2 `Get-DTOWorkstationSnapshot` results, which known values differ, which match, and which cannot be compared because evidence is missing or incomplete?

The caller chooses and retains both inputs. The comparison does not collect new device information, read files, save reports, contact a server, or change either input. Hardware and OS values can still be sensitive; choose private report storage when saving them yourself.

| Input source | Compared fields | Comparison |
|---|---|---|
| Win32_OperatingSystem | Caption, Version, OSArchitecture | Exact, case-sensitive text |
| Win32_ComputerSystem | Manufacturer, Model | Exact, case-sensitive text |
| Win32_BIOS | SMBIOSBIOSVersion | Exact, case-sensitive text |
| Win32_Processor | Name | Case-sensitive multiset; order ignored, duplicate counts retained |

There are seven result rows. CPU names have no stable socket identifier in schema 2, so the tool does not infer which processor moved or changed. Services, applications, drivers, peripherals and effective policies are not compared in this increment.

## Result and input rules

- `Changed`: both sides have complete, valid evidence for the field and their values differ.
- `Unchanged`: both sides have complete, valid evidence for the field and their values match.
- `Unknown`: either side is missing, partial, unavailable, ambiguous or inconsistent. Valid available values remain visible, with per-side coverage, without an absence or success claim.

Known sections must occur exactly once. Case variants cannot hide a duplicate source. Complete coverage requires exact Boolean flags, valid record limits and integer enumerated/inspected counts consistent with the record array. A missing or invalid field is unknown even if a source claims complete collection. Identifiers and unrecognized fields are never copied into the comparison.

Both original UTC observation timestamps are retained. The collector's round-trip UTC string format and a UTC `DateTime` materialized by a PowerShell JSON reader are accepted. Reversed time order is refused; equal times are labeled `SameTimestamp`. No elapsed-time, freshness or causal inference is made. Malformed snapshot envelopes are rejected with fixed error codes, without private exception details.

The inputs are trusted local data objects or the caller's selected parsed JSON records. This is not a sandbox for arbitrary PowerShell objects, a general JSON file importer, or authenticated evidence verification.

`ComparisonComplete` means all seven declared fields could be compared. The original `CollectionComplete` flags remain separately visible. `SameDeviceVerified`, `DeploymentAccepted` and `ChangesAllowed` are always false. Matching host names or hardware would not prove device identity; the caller must choose the correct observation pair. Human signoff and required/optional workflow checks remain separate work.

## Reproducible fictional example

From the repository root on an authorized PowerShell host:

```powershell
Import-Module .\Scripts\Imaging-Provisioning\src\DTOImaging.psm1 -Force
Import-Module .\Scripts\Imaging-Provisioning\src\DTOSnapshotComparison.psm1 -Force

function New-DemoSection([string]$Source, [object[]]$Records, [int]$Limit=1) {
    [pscustomobject]@{
        Source=$Source; Status='Complete'; Reason=$null; Records=@($Records)
        EnumeratedCount=$Records.Count; InspectedCount=$Records.Count
        RecordLimit=$Limit; RecordByteLimit=131072
        EnumerationComplete=$true; CollectionComplete=$true
    }
}

$before = [pscustomobject]@{
    SchemaVersion=2; Product='DTO Imaging & Provisioning'; Version='0.2.0'
    AssessmentType='ReadOnlyLocalSnapshot'
    CollectedAtUtc='2026-11-06T17:00:00.0000000Z'
    ComputerNameIncluded=$false; CollectionComplete=$true; DeploymentAccepted=$false
    Sections=@(
        New-DemoSection 'Win32_OperatingSystem' @([pscustomobject]@{
            Caption='Fictional operating system'; Version='Fixture version A'; OSArchitecture='64-bit'
        })
        New-DemoSection 'Win32_ComputerSystem' @([pscustomobject]@{
            Manufacturer='Fictional maker'; Model='Fixture model'
        })
        New-DemoSection 'Win32_BIOS' @([pscustomobject]@{ SMBIOSBIOSVersion='Fixture BIOS' })
        New-DemoSection 'Win32_Processor' @(
            [pscustomobject]@{ Name='Fixture CPU B' }
            [pscustomobject]@{ Name='Fixture CPU A' }
        ) 16
    )
}

# Deep-copy fictional input; keep the original observation intact.
$after = $before | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$after.CollectedAtUtc='2026-11-06T18:00:00.0000000Z'
$after.Sections[0].Records[0].Version='Fixture version B'
$after.Sections[2].Status='Unavailable'
$after.Sections[2].Reason='QueryFailed'
$after.Sections[2].Records=@()
$after.Sections[2].EnumeratedCount=0
$after.Sections[2].InspectedCount=0
$after.Sections[2].EnumerationComplete=$false
$after.Sections[2].CollectionComplete=$false
$after.CollectionComplete=$false
$after.Sections[3].Records=@($after.Sections[3].Records[1], $after.Sections[3].Records[0])

$comparison = Compare-DTOWorkstationSnapshot -Before $before -After $after
$comparison | Select-Object ChangedCount, UnchangedCount, UnknownCount, ComparisonComplete
$comparison.Rows | Select-Object Source, Field, State
# Optional: return an offline HTML string. No file is written here.
$html = ConvertTo-DTOReviewHtml -Review $comparison
```

Expected summary: **1 changed, 5 unchanged, 1 unknown; ComparisonComplete is false.** OS Version changed; BIOS evidence is unknown; reordered CPU names are unchanged. The original `$before` is unchanged. The two times are observation times, not the time of report rendering.

## Reproduce the checks

```powershell
.\Scripts\Imaging-Provisioning\tests\Run-ComparisonChecks.ps1
python .\Scripts\Imaging-Provisioning\tests\test_package.py
```

The comparison suite also runs from the existing Imaging `Run-Checks.ps1` entry point, in the Windows PowerShell 5.1 and PowerShell 7 integration jobs. See [dated execution evidence](../Scripts/Imaging-Provisioning/docs/VALIDATION.md#selected-observation-comparison) for source/run identities and actual outcomes. Tests existing in the source are not an execution result.

## Contribution and remaining work

This is David Tom's DTO personal portfolio project, implemented with AI assistance under the existing task scope. The key decisions are a separate pure module, a fixed projection, conservative unknown states, multiset comparison without invented CPU identity, and retention of the original collector source. The [permission notice](../LICENSE.md) continues to apply.

Required/optional baseline policies, device-pairing evidence, peripheral/user checks, action-result validation and human signoff remain open under DTO-WSA-010. The native dashboard, saved profile/catalog migration, attended Windows 11, deployment, installer and recovery gates retain their existing task authorities.

[Imaging usage](../Scripts/Imaging-Provisioning/README.md) | [Imaging TODO](../Scripts/Imaging-Provisioning/TODO.md) | [Windows active TODO](DTO-WINDOWS-ADMIN-TODO.md)
