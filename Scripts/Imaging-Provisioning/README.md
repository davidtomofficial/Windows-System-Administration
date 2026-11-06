# DTO Imaging & Provisioning

**David Tom Official · 0.2.0 development preview · Not a deployment image**

[Permission and license notice](LICENSE.md) · [Component TODO](TODO.md) · [Validation](docs/VALIDATION.md)

Covered original software requires explicit written permission unless an applicable existing license or law already permits use. This source preview is not an installer, a bootable Windows image, or a production release.

## Implemented scope

Privacy-conscious workstation observations, bounded service inventory, read-only local WIM metadata/index review, optional SHA-256 hashing and a DTO offline HTML report. The original full desktop workflow has not been migrated.

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

## Checks and packaging

```powershell
.\tests\Run-Checks.ps1
# Disposable Windows lab: creates/removes a synthetic text-file WIM.
.\tests\Run-Checks.ps1 -Native
python .\tests\test_package.py
python .\tools\package.py --output DTO-Imaging-0.2.0.zip
python .\tools\package.py --verify DTO-Imaging-0.2.0.zip
```

Thirteen allowlisted source files, including LICENSE.md, plus MANIFEST.json are packaged. Python 3.9+ is for packaging; it is not required by the Windows observation scripts. A package checksum is not publisher trust or deployment acceptance.

## Identity and future check-ins

DTO colors and public contact remain in the report. Full WPF and official native icon integration remain open. Contact: david.tom@davidtomofficial.com.

**Periodic check-ins are not implemented or active.** The future permission-licensed-build requirement is DTO-IMG-014, linked to shared DTO-WSA-042–046 in the [repository review TODO](../../Docs/REPOSITORY-REVIEW-TODO.md) and [check-in contract](../../Docs/USAGE-CHECK-IN.md). These repository-level documents are outside the standalone ZIP; the [online contract](https://github.com/davidtomofficial/Windows-System-Administration/blob/integration/dto-repository-review-20261105/Docs/USAGE-CHECK-IN.md) is separate. A check-in outage must never interrupt imaging/recovery.

[Windows administration master](../../Docs/DTO-WINDOWS-ADMIN-TODO.md) · [Migration scope](docs/MIGRATION.md) · [Portfolio](https://davidtomofficial.com/)
