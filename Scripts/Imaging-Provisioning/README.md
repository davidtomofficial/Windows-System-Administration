# DTO Imaging & Provisioning — Windows System Administration

**Owner/portfolio:** David Tom Official (DTO) · https://davidtomofficial.com/  
**Status:** migration preview / not a production imaging release · **Started:** 2026-11-05

This folder is the public-safe starting point for a **new DTO copy** of the Windows workstation imaging/provisioning project. The original **DTS Technician 0.23.0** source remains preserved privately and is not renamed, overwritten or published wholesale. The DTO project will be migrated selectively after rights, licensing, secrets and privacy review.

## Available in this checkpoint

- A standalone, read-only Windows PowerShell 5.1 assessment script at `src/Get-DTOWorkstationSnapshot.ps1`. It collects local OS, computer system and basic hardware information and returns a structured object; it does not modify services, registry, domain, device enrollment, apps or disks.
- DTO branding metadata in `brand/product.json`, with public portfolio contact links and no assumed support mailbox.
- Migration acceptance checklist, source lineage and public-release exclusions in `docs/MIGRATION.md`.

Run locally from Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\Get-DTOWorkstationSnapshot.ps1
```

Review output before sharing; even basic device identifiers can be sensitive. Do not publish reports by default. No vendor installers, licensed packages, enterprise policies, employer-derived source, private device reports or company artwork are included.

**Not yet included:** full DTS 0.23.0 UI, saved profiles, software catalog, imaging engine, installer, application observations or automated migration. Those remain in private source pending review. This is not an equivalent replacement for the tested private preview.
