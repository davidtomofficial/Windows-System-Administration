# DeviceCare — personal Windows maintenance project

**David Tom Official · 0.1.0 DTO development preview**

A separately developed, read-only Windows workstation assessment prototype. It supports two transparent threshold-based observations: system-drive free space and memory use. It does **not** repair or clean devices, update Windows, install applications, modify services, scan for malware or assert that a computer is healthy.

The pre-existing full application is not included in this source package. This preview is not full feature parity, a production release or a signed installer.

## Getting started

On an authorized local Windows computer, using Windows PowerShell 5.1:

```powershell
Import-Module .\src\DeviceCare.psm1 -Force
$snapshot = Get-DTODeviceCareSnapshot
$assessment = Get-DTODeviceCareFindings -Snapshot $snapshot
$assessment | ConvertTo-Json -Depth 8
# Optional offline HTML *string*. This does not save, open or transmit anything.
$html = ConvertTo-DTODeviceCareHtml -Assessment $assessment
```

Or `powershell.exe -NoProfile -File .\src\Invoke-DTODeviceCare.ps1`. Follow your local script-execution policy; neither entry point bypasses policy or requests elevation. It uses local CIM calls only. No network requests, account/device enrollment, external fonts, startup tasks, scheduled maintenance, report upload or email delivery.

## Interpreting results

Each section reports **Observed** or **Unknown**. Thresholds apply only when a valid local measurement exists. Results can be `Observed`, `Review`, or `Unknown`; *Observed* means only the selected numeric threshold was not crossed, **not** that the whole device is healthy. Missing, ambiguous, invalid or failed collection yields Unknown, never a clean verdict. Provider timeouts are per-call hints, not a guaranteed wall-clock deadline.

No username, machine name, serial number, domain, service account, installed application names or file paths are collected in the report. Even OS and hardware details can still be sensitive. Review before sharing. No report is saved automatically.

## Branding

Personal identity: **David Tom Official**. Project page: https://davidtomofficial.com/devicecare/. Contact: david.tom@davidtomofficial.com. Navy `#0F2747`, off-white `#F8F9FB`, pale blue `#E6ECF2`, decorative gold `#D4A574`. The offline report uses system fonts. Approved original DT logos are not copied or reconstructed here and require a separate asset/rights review before inclusion.

## Development checks

```powershell
.\tests\Run-Checks.ps1
# Only on a disposable or authorized Windows machine:
.\tests\Run-Checks.ps1 -Native
python .\tests\test_package.py
python .\tools\package.py --output DTO-DeviceCare-0.1.0.zip
python .\tools\package.py --verify DTO-DeviceCare-0.1.0.zip
```

The package builder accepts only eleven explicitly enumerated source files, plus MANIFEST.json. It refuses overwriting an existing ZIP. Archive checksum matching is not a publisher signature.

See [active TODO](TODO.md), [migration boundaries](docs/MIGRATION.md), and [validation](docs/VALIDATION.md).
