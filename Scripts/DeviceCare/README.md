# DeviceCare

**David Tom Official · 0.2.0 development preview · Read-only**

[Permission and license notice](LICENSE.md) · [Component TODO](TODO.md) · [Validation evidence](docs/VALIDATION.md)

Obtain explicit written permission before use unless an applicable existing license or law already permits it. The source is a personal portfolio preview, not an unrestricted software-use grant or a production maintenance product.

## What is implemented

Local OS, memory and system-drive observations; threshold-based `Observed`, `Review` and `Unknown` findings; an offline HTML report with the approved original DT mark, finding counts, a table and expandable structured evidence. Decisions use unrounded measurements; the report projects reviewed fields only.

No cleanup, repair, service change, app/Windows update, malware scan, enrollment, reboot or overall device-health certification is implemented. Full native desktop migration and actual Windows 11 acceptance remain open.

## Authorized development use

Use Windows PowerShell 5.1 under normal organizational script policy:

```powershell
Import-Module .\src\DeviceCare.psm1 -Force
$snapshot = Get-DTODeviceCareSnapshot
$assessment = Get-DTODeviceCareFindings -Snapshot $snapshot
$assessment | ConvertTo-Json -Depth 8
$html = ConvertTo-DTODeviceCareHtml -Assessment $assessment
```

The HTML string is not saved, opened, emailed or uploaded automatically. No machine name, user name, serial, domain, file paths or credentials are collected by this preview. Even minimal system observations can be sensitive; review before sharing. A per-call timeout is not a guaranteed whole-process deadline.

## Checks and packaging

```powershell
.\tests\Run-Checks.ps1
# Disposable or expressly authorized Windows host only:
.\tests\Run-Checks.ps1 -Native
python .\tests\test_package.py
python .\tools\package.py --output DTO-DeviceCare-0.2.0.zip
python .\tools\package.py --verify DTO-DeviceCare-0.2.0.zip
```

Sixteen allowlisted source files, including LICENSE.md, plus MANIFEST.json are packaged. The source package is not an installer; hashes are not publisher signatures. Python is needed for packaging checks, not for the observation script.

## Migration, branding and check-ins

DTO navy, off-white, pale blue and decorative gold are applied. The original DT vector is embedded locally; no font files or remote resources are required. [Asset provenance](brand/ASSET-PROVENANCE.md) records its identity. Native icon/WPF and attended accessibility acceptance are still pending.

**Periodic usage check-ins are not implemented or active.** The newly requested future licensed-build requirement is tracked under DTO-DC-021 and DTO-WSA-042–046 in the [shared repository TODO](../../Docs/REPOSITORY-REVIEW-TODO.md); see the [disclosure and implementation contract](../../Docs/USAGE-CHECK-IN.md). Those repository-level documents are outside the standalone component ZIP; the [online contract](https://github.com/davidtomofficial/Windows-System-Administration/blob/integration/dto-repository-review-20261105/Docs/USAGE-CHECK-IN.md) is available separately. No endpoint is invented or enabled.

[Windows administration master](../../Docs/DTO-WINDOWS-ADMIN-TODO.md) · [Launchpad](../../Launchpad/README.md) · [Project](https://davidtomofficial.com/devicecare/) · [Contact](https://davidtomofficial.com/#contact)
