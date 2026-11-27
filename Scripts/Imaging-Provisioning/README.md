# DTO Imaging & Provisioning

**David Tom Official · Public source preview 0.2.0**

[Permission and license notice](LICENSE.md) · [Component TODO](TODO.md) · [Validation](docs/VALIDATION.md)

[Synthetic developer proof package](docs/PROOF-PACKAGE.md): run a fictional before/after comparison, check independently authored expected JSON, and optionally create an offline report. The default proof writes no files and does not collect device data.

Covered original software requires explicit written permission unless an applicable existing license or law already permits use. This source preview is not an installer, a bootable Windows image, or a production release.

## Technician download and setup

[Open the DTO download page](https://davidtomofficial.com/windows-imaging-provisioning/#technician-download)

Start at the Windows 11 Pro x64 desktop after reset and initial Windows setup. The private DTO page lists the current Azure-signed build for owner testing, with a Windows installer, portable ZIP and Standard offline trial disc (ISO). Staff rollout still needs the live DTO access service, managed publisher trust and a full post-reset trial.

1. **Sign in and download.** Sign in on the DTO website and open the private technician page. Use the Microsoft account authorized for the SharePoint library. Choose the **Standard offline trial disc** for standalone owner testing or the signed **Windows installer (MSI)** or **portable ZIP** for the managed staff pilot.
2. **Verify the file.** In Windows PowerShell, run `Get-FileHash -Algorithm SHA256 -LiteralPath 'C:\Downloads\your-download.msi'` with your actual file path. Compare the result with the SHA-256 shown beside that download.
3. **Open the signed build.** After installing the MSI, open **DTO Imaging & Provisioning (Staff)** from Start. For the ZIP, choose **Extract All** and open `Start-StaffImaging.cmd`. The launcher requires managed DTO access settings and a DTO work account. If staff startup is blocked, ask the DTO administrator to check the managed settings and publisher trust. For the Standard offline disc, mount the ISO, copy its contents into one local folder, and run the verification block in `START-HERE.txt` in Windows PowerShell. The disc includes reviewed Chrome and VLC installers.
4. **Check the PC and prepare files.** Select the released **Standard standalone** profile and choose **Check this PC**. Use **Check and prepare files** for online downloads. For the offline disc or another approved local installer folder, keep the same profile and catalog, choose **Prepare local files**, and select that folder.
5. **Set up apps and check handoff.** Use **Set up prepared apps** to review each attended Chrome or VLC installation. When available, use **Check handoff from this preparation** to connect the review to the files you prepared. Resolve the required findings and verify the approved apps as the intended Windows user before recording signoff.
6. **Keep the report and verify delivery.** Open the readable report in **Activity** and keep it on the PC. Use **Save status summary** for the limited JSON. If it says **Saved for sync**, check the approved private SharePoint folder. If sync stalls, use the copy-path action in Activity and upload the saved JSON to that folder. Download a separate copy and choose **Verify received summary**.

To resume interrupted file preparation, use the package and profile that started it. If Chrome preparation stops for disk space, free the required space, keep the approved installer in the same folder, and choose **Resume file preparation** in Activity. The private page retains earlier signed downloads and the earlier unsigned owner preview for those runs. The unsigned preview uses **DTO Imaging & Provisioning (Owner Preview)** from Start or `technician\Start-Imaging.cmd` from its ZIP. Before replacing an MSI, let active tasks finish, close the dashboard, and remove the earlier version in **Settings → Apps → Installed apps**.

In 0.9.194 and later, use **Activity → Open report by run ID** to reopen a supported interruption report after it drops out of recent tasks. You can also select **Open report from summary** and choose a verified local JSON copy. The full report stays on the PC.

For installers in a synced SharePoint or OneDrive folder, choose **Always keep on this device** in File Explorer. Once the files are available, choose **Prepare local files** in DTO and select the folder. If Activity says a staged installer lost its Windows security zone, keep the original report and start a new preparation with an approved copy. The private download page and `technician\USER-GUIDE.txt` cover publisher downloads, retries and handoff review.

### Which software can I set up?

**Standard standalone** selects Google Chrome Enterprise and VLC. Use **Set up prepared apps** to check whether an attended installation is available for this PC. The Enterprise plan lists 16 applications and nine capability, dependency and hardware checks. Select a client profile in **Software plan** to see what applies.

| Enterprise selection | How to finish setup |
|---|---|
| Google Chrome Enterprise | Keep an existing installation for review. If Chrome is missing, a new client profile uses Google’s verified Windows x64 publisher download. To adopt this source in an earlier profile, save a new revision. |
| VLC | Prepare verifies the pinned installer. Use the saved readiness check before starting attended setup. |
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

**Periodic check-ins are not implemented or active.** The future permission-licensed-build requirement is DTO-IMG-014, linked to shared DTO-WSA-042–046 in the [repository review TODO](../../Docs/REPOSITORY-REVIEW-TODO.md) and [draft check-in requirements](../../Docs/USAGE-CHECK-IN.md). These repository-level documents are outside the standalone ZIP; the [online requirements](https://github.com/davidtomofficial/Windows-System-Administration/blob/main/Docs/USAGE-CHECK-IN.md) is separate. A check-in outage must never interrupt imaging/recovery.

[Windows administration master](../../Docs/DTO-WINDOWS-ADMIN-TODO.md) · [Migration scope](docs/MIGRATION.md) · [Portfolio](https://davidtomofficial.com/)
