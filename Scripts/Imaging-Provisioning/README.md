# DTO Imaging & Provisioning

**David Tom Official · Public source preview 0.2.0**

[Permission and license notice](LICENSE.md) · [Component TODO](TODO.md) · [Validation](docs/VALIDATION.md)

[Synthetic developer proof package](docs/PROOF-PACKAGE.md): run a fictional before/after comparison, check independently authored expected JSON, and optionally create an offline report. The default proof writes no files and does not collect device data.

Covered original software requires explicit written permission unless an applicable existing license or law already permits use. This source preview is not an installer, a bootable Windows image, or a production release.

## Technician download and setup

Get the Windows technician package from the DTO website. The private page lists the package version and SHA-256. Sign in to WordPress to open that page, then use the Microsoft account authorized to download the ZIP. Only the project owner currently has file access. The downloaded launcher currently runs without a second DTO sign-in. Staff enrollment and launcher authentication are planned. [Go to technician downloads](https://davidtomofficial.com/windows-imaging-provisioning/#technician-download)

To start an authorized copy on Windows 11 Pro x64:

1. At the Windows desktop after reset and initial setup, download the ZIP through the DTO website. Compare its SHA-256 with the value listed for that release. You can calculate it in PowerShell with `Get-FileHash -Algorithm SHA256 -LiteralPath 'C:\Downloads\your-package.zip'`, substituting the path to your file.
2. In File Explorer, choose **Extract All** and keep the extracted folders together. Open **technician** and run **Start-Imaging.cmd**. The current preview is unsigned. If Windows policy blocks it, contact DTO for an approved release.
3. Choose **Standard standalone → Check this PC**, review the findings, then choose **Check and prepare files**. If a download mirror fails, DTO tries the reviewed publisher when available. If you close the dashboard during setup, reopen it to follow the running task in **Activity**.
4. Choose **Set up prepared apps** to check Chrome or VLC. When the check is ready, select **Open Windows Installer** within 15 minutes. Follow its prompts, then return to **Continue setup**. Open the run’s report in **Activity** if a step stops.
5. Choose **Verify before handoff → Check handoff readiness**. Open that check in **Activity → Record handoff review** and confirm the items you verified. When all requirements are met, choose **Record completed handoff review**.
6. Keep the full device report on the PC. To share a limited summary, choose **Save status summary**. After downloading the file from the approved SharePoint folder, use **Verify received summary** to compare it with the saved version.

## Implemented scope

Privacy-conscious workstation observations, bounded service inventory, read-only local WIM metadata/index review, optional SHA-256 hashing and a DTO offline HTML report. A separate comparison module compares selected before/after workstation observations. An additional [profile inventory command](docs/PROFILE-INVENTORY.md) provides read-only profile observations for DTO-WSA-015. The original full desktop workflow has not been migrated.

## Authorized development use

Review the source and respect normal script-execution policy. No bypass or automatic elevation occurs; DISM image inspection may require elevation.

```powershell
Import-Module .\src\DTOImaging.psm1 -Force
$device = Get-DTOWorkstationSnapshot
$services = Get-DTOServiceSnapshot
$image = Get-DTOImageReview -ImagePath 'C:\Images\install.wim' -Index 1
# Optional full-file hash:
$image = Get-DTOImageReview -ImagePath 'C:\Images\install.wim' -Index 1 -ComputeSha256
$html = ConvertTo-DTOReviewHtml -Review ([pscustomobject]@{
    Device=$device; Services=$services; Image=$image
})
```

Computer name is opt-in through `-IncludeComputerName`. Snapshot schema 2 uses `Sections` and completeness fields, not the old flat fields. Partial, missing or failed evidence does not establish absence or device readiness. A stopped service is an observation, not a fault finding.

WIM inspection accepts nonempty local `.wim` files on fixed/removable drives without reparse traversal. It does not mount/apply images or modify partitions. DISM may write normal diagnostic logs. Hash/size/timestamp checks do not establish authenticity, licensing, supported OS contents, a concurrency lock or compatibility. ESD, split WIM, VHD and network paths are not accepted in this increment.

The HTML is returned as a string; no automatic save, upload or email. Hardware, service and image names can still be sensitive. Review before sharing.

## Compare selected workstation observations

DTO-WSA-010 / DTO-IMG-004 and DTO-IMG-007 now have a bounded comparison implementation. Keep both original observations and choose the intended pair yourself. The comparison never establishes that the records came from the same device, that a change was successful, or that the workstation is ready for handoff.

```powershell
Import-Module .\src\DTOImaging.psm1 -Force
Import-Module .\src\DTOSnapshotComparison.psm1 -Force
# $before and $after are separately retained Get-DTOWorkstationSnapshot results.
# For a selected saved JSON observation, use Get-Content -LiteralPath ... -Raw | ConvertFrom-Json.
$comparison = Compare-DTOWorkstationSnapshot -Before $before -After $after
$comparison.Rows | Select-Object Source, Field, State, BeforeValues, AfterValues
$html = ConvertTo-DTOReviewHtml -Review $comparison
```

Seven known OS, hardware, BIOS and processor-name fields have `Changed`, `Unchanged` or `Unknown` results. Missing, partial, duplicate or contradictory source evidence stays unknown; available valid values remain visible for review. CPU names form a case-sensitive multiset: order is ignored, repeated names still count, and no socket mapping is inferred. Other text values are compared exactly. Both original UTC timestamps are retained; reversed time order is refused and equal times are labeled. This is an in-process data contract for trusted local objects, not a parser for arbitrary untrusted PowerShell objects.

Computer names, serials, paths and unrecognized fields are omitted. Hardware and OS values may still be sensitive. `ComparisonComplete` describes the seven compared fields only; `SameDeviceVerified`, `DeploymentAccepted` and `ChangesAllowed` remain false. Required/optional workflow checks, peripheral validation and human signoff remain open. See the [worked example and contract](https://github.com/davidtomofficial/Windows-System-Administration/blob/main/Docs/WORKSTATION-COMPARISON.md).

## Checks and packaging

```powershell
.\tests\Run-Checks.ps1
# Disposable Windows lab: creates/removes a synthetic text-file WIM.
.\tests\Run-Checks.ps1 -Native
.\tests\Run-ProfileChecks.ps1
# Reads profile metadata on the authorized Windows test host:
.\tests\Run-ProfileChecks.ps1 -Native
python .\tests\test_package.py
python .\tools\package.py --output DTO-Imaging-0.2.0.zip
python .\tools\package.py --verify DTO-Imaging-0.2.0.zip
```

The explicit allowlist in `tools/package.py` packages source, tests, documentation and LICENSE.md with MANIFEST.json. Python 3.9+ is for packaging; it is not required by the Windows observation scripts. A package checksum is not publisher trust or deployment acceptance.

## Identity and future check-ins

DTO colors and public contact remain in the report. Full WPF and official native icon integration remain open. Contact: david.tom@davidtomofficial.com.

**Periodic check-ins are not implemented or active.** The future permission-licensed-build requirement is DTO-IMG-014, linked to shared DTO-WSA-042–046 in the [repository review TODO](../../Docs/REPOSITORY-REVIEW-TODO.md) and [check-in contract](../../Docs/USAGE-CHECK-IN.md). These repository-level documents are outside the standalone ZIP; the [online contract](https://github.com/davidtomofficial/Windows-System-Administration/blob/main/Docs/USAGE-CHECK-IN.md) is separate. A check-in outage must never interrupt imaging/recovery.

[Windows administration master](../../Docs/DTO-WINDOWS-ADMIN-TODO.md) · [Migration scope](docs/MIGRATION.md) · [Portfolio](https://davidtomofficial.com/)
