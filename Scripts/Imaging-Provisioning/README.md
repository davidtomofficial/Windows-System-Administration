# DTO Imaging & Provisioning

**David Tom Official | Development preview 0.2.0**

This separate personal/portfolio project now provides privacy-conscious workstation observations, bounded service inventory, read-only WIM metadata review, and a local DTO-branded HTML report. It is **not a deployment image or an installer**. The original technician project remains preserved; its complete interface and workflow have not been migrated.

## Use on Windows

Review the source and follow your organization's script-execution policy. No policy bypass or elevation is performed automatically. The DISM image query may require an elevated PowerShell session.

```powershell
Import-Module .\src\DTOImaging.psm1 -Force
$device = Get-DTOWorkstationSnapshot
$services = Get-DTOServiceSnapshot
$image = Get-DTOImageReview -ImagePath 'C:\Images\install.wim' -Index 1
# Optional full-file hashing; large images may take substantial time.
$image = Get-DTOImageReview -ImagePath 'C:\Images\install.wim' -Index 1 -ComputeSha256
# Returned HTML is not saved, opened, uploaded or emailed automatically.
$html = ConvertTo-DTOReviewHtml -Review ([pscustomobject]@{
    Device=$device; Services=$services; Image=$image
})
```

The existing `src/Get-DTOWorkstationSnapshot.ps1` entry point remains available. Use `-IncludeComputerName` only when knowingly collecting that identifier. Schema 2 replaces the original flat snapshot; downstream consumers must use `Sections` and its explicit completeness fields. Machine name is omitted by default; no serial, domain, user, service account, command line or image path is returned. Image names, hardware values and service names can still reveal private information. Review before sharing.

The service collector preserves valid rows after a later failure and caps row count and projected UTF-8 storage. An empty, failed, malformed or truncated result never establishes absence or device readiness. Stopped is a recorded state, not a fault finding. Application relationships and original saved-profile evidence replay are not ported yet.

WIM review accepts only existing nonempty `.wim` files on fixed/removable local drives without reparse traversal. It queries DISM metadata, optionally hashes the source, and detects size/timestamp changes during inspection. These checks do not provide a file lock, signature trust, edition/license approval, compatibility proof or deployment authorization. No mount/apply/disk/partition changes are performed. DISM can write its normal diagnostic logs; the operation is not claimed to be globally side-effect-free or hard-deadline-bounded. ESD, split WIM, VHD and network paths are not supported in this increment.

## Branding and contact

DTO navy, off-white, pale blue and restrained decorative gold are applied to the offline report. Contact: **david.tom@davidtomofficial.com** at the [portfolio contact section](https://davidtomofficial.com/#contact). This is project feedback, not a commercial support commitment. No DTS shield, logo, phone or support address is carried into this build. The desktop logo/icon and full WPF migration are still open; no new logo or bundled fonts were invented.

## Checks and packaging

The optional packaging tool requires Python 3.9 or newer. The Windows observation scripts do not require Python.

```powershell
.\tests\Run-Checks.ps1
# Disposable Windows lab only: creates and removes a tiny synthetic test WIM.
.\tests\Run-Checks.ps1 -Native
python .\tests\test_package.py
python .\tools\package.py --output DTO-Imaging-0.2.0.zip
python .\tools\package.py --verify DTO-Imaging-0.2.0.zip
```

The package builder uses an explicit 12-file source allowlist and adds a SHA-256 manifest. It refuses to overwrite an existing output. Manifest matching detects accidental drift, not trusted authorship. Native tests do not apply an OS image or prove Windows 11/workstation acceptance.

See [TODO](TODO.md), [migration](docs/MIGRATION.md) and [validation](docs/VALIDATION.md). Code signing remains deferred for controlled development; operational release and deployment qualification remain separate.
