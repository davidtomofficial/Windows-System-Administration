# DTO Imaging & Provisioning

**David Tom Official · Public source preview 0.2.0**

[Permission and license notice](LICENSE.md) · [Component TODO](TODO.md) · [Validation](docs/VALIDATION.md)

[Synthetic developer proof package](docs/PROOF-PACKAGE.md): run a fictional before/after comparison, check independently authored expected JSON, and optionally create an offline report. The default proof writes no files and does not collect device data.

Covered original software requires explicit written permission unless an applicable existing license or law already permits use. This source preview is not an installer, a bootable Windows image, or a production release.

## Technician download and setup

[Open the DTO download page](https://davidtomofficial.com/windows-imaging-provisioning/#technician-download)

Use the 0.9.64 owner preview from the Windows 11 Pro x64 desktop after reset and initial Windows setup. This owner preview is unsigned. On a PC using `RemoteSigned`, Windows PowerShell blocks the downloaded dashboard until DTO signs its scripts. If startup is blocked, contact DTO for an approved build.

1. **Sign in and download.** On the DTO website, sign in and open the private technician page. Use the Microsoft account with SharePoint access and choose the **Windows installer (MSI)** or the **portable ZIP**. The current preview is available only to the project owner.
2. **Check the file.** In Windows PowerShell, run `Get-FileHash -Algorithm SHA256 -LiteralPath 'C:\Downloads\your-download.msi'` using the path to your MSI or ZIP. Continue only if the result matches the SHA-256 beside that file on the private page.
3. **Install and open.** Open the verified MSI and choose **Install**. From Start, open **DTO Imaging & Provisioning (Owner Preview)**. For the portable ZIP, use **Extract All** and open `technician\Start-Imaging.cmd`. Choose **Standard standalone → Check this PC**, review the findings, then choose **Check and prepare files**.
4. **Review the result.** For publisher downloads, the footer shows how many files passed verification. In a linked handoff, choose **Open original preparation** to find the saved installer in the readable report. Use **Set up prepared apps** for the attended Chrome or VLC check. Open **Activity → Open readable report** for the inventory and results. Finish with **Verify before handoff → Check handoff readiness**. Keep the detailed report on the PC. **Save status summary** creates a smaller file for approved sharing.

To replace an earlier MSI, close the dashboard and uninstall **DTO Imaging & Provisioning (Owner Preview)** from **Settings → Apps → Installed apps** before opening the new MSI. Existing run reports stay on the PC.

Azure Artifact Signing awaits approval. Staff enrollment and sign-in at launch are pending. Downloaded copies currently have no second sign-in. [Staff access TODO](TODO.md#technician-sign-in-before-staff-release)

For installers in a synced SharePoint or OneDrive folder, choose **Always keep on this device** in File Explorer. Once the files are available, choose **Prepare local files** in DTO and select the folder. The progress line shows the active installer, its phase and the bytes copied. The private download page and `technician\USER-GUIDE.txt` cover publisher downloads, retries and handoff review.

### Which software can I set up?

**Standard standalone** selects Google Chrome Enterprise and VLC. Use **Set up prepared apps** to check whether an attended installation is available for this PC. The Enterprise plan lists 16 applications and nine capability, dependency and hardware checks. Select a client profile in **Software plan** to see what applies.

| Enterprise selection | How to finish setup |
|---|---|
| Chrome Enterprise and VLC | Prepare verifies the catalog installers. Review the saved installation actions for the active profile. |
| Firefox ESR, 7-Zip, Teams, OneDrive, LibreOffice, Zoom Workplace, Notepad++, Audacity, OBS Studio, Visual Studio Code, Bitwarden and TeamViewer | Online preparation can retrieve publisher files. Open the preparation report for their locations and follow the publisher’s deployment instructions. For a portable per-user 7-Zip command line, use **Tools**. |
| Microsoft 365 Apps and Adobe Creative Cloud | Open the publisher page and use the client’s authorized account and deployment package. |
| Edge PDF reader, five runtime dependencies and three manufacturer tools | Check the existing PDF capability, application dependencies and device manufacturer before deciding what the PC needs. |

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
