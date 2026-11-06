# DTO Imaging migration and release gates

## Preservation receipts (2026-11-05)

1. Original DTS 0.23.0 baseline: private `davidtomofficial/davidtom-work-backups` commit `700ed4ace9cd0878c079207dc1737a8c48f09d3b`.
2. Explicit pre-work private backup branch: `backup/imaging-pre-dto-20261105` pointing to that immutable baseline commit.
3. Public Windows System Administration pre-work snapshot branch: `dto/imaging-prework-backup-20261105`, created before this migration branch.
4. Public work branch: `dto/imaging-migration-20261105`. The public branch includes only separately reviewed new material, not the private source tree.

## Phase checklist

- [x] Preserve source and destination baseline before modification.
- [x] Start a new DTO copy in the requested public Windows System Administration repository.
- [x] Establish a minimal read-only, public-safe Windows PowerShell source and DTO metadata.
- [ ] Reconcile newest specific SharePoint DTO migration TODO, including any newer source/ownership decisions.
- [ ] Confirm DTO website palette, logo/icon licensing, email/contact destination and support/feedback policy. Do not carry DTS logo or support mailbox into DTO by assumption.
- [ ] Perform file-by-file rights, secret, customer/environment and package-license review on DTS 0.23.0 source.
- [ ] Selectively port UI, saved software profiles, observations and planner with behavior tests and attribution; no raw enterprise configuration.
- [ ] Implement DTO-specific branding in title, About, reports, icons, help, installer and documentation.
- [ ] Test Windows PowerShell 5.1 syntax, Pester, WPF, keyboard/Narrator, High Contrast, DPI and multi-monitor use.
- [ ] Independently validate imaging, restore, app installation and rollback on approved sacrificial hardware/VMs.
- [ ] Verify SharePoint backup bytes and GitHub commit/branch refs; record SHA-256 and recovery steps.
- [ ] Decide if code signing and Windows installer release are appropriate; obtain explicit release authorization.

## Public-release exclusions

No company/employer device names, domain/OU paths, policies, internal URLs, CJIS data, credentials, personal identifiers, reports, vendor binaries, unverified license claims, DTS brand images or automatic telemetry. No network callbacks in the read-only starter. Public source is not evidence of commercial support or deployment readiness.

## Source-to-destination map

| Source | DTO target | State |
|---|---|---|
| DTS `product.json` | `brand/product.json` | New DTO metadata; no DTS support contact |
| DTS Windows device assessment | `src/Get-DTOWorkstationSnapshot.ps1` | New minimal implementation; not feature parity |
| DTS WPF dashboard and icons | Future `ui/` | Not ported pending asset rights and QA |
| DTS software profiles and catalog | Future `catalog/` | Not ported pending licensing review |
| DTS service observations | Future `diagnostics/` | Not ported pending technical review |
| DTS imaging and installer | Future `installer/` | Not ported pending safety/rights/recovery acceptance |
