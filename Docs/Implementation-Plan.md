# Research-driven implementation plan

The Windows System Administrator GitHub Audit and Upgrade Plan identifies executable PowerShell, tests, and CI as the immediate gap. This plan implements that first bounded slice rather than adding a GUI or copying historical employer code. The older [blueprint](Repository-Blueprint.md) remains the long-term design; the actual [README inventory](../README.md) is authoritative for implemented features.

## First reviewable slice

The preview adds a manifest-backed module with two commands: local read-only inventory and offline bounded name selection. It adds synthetic tests, optional hosted-Windows smoke tests, pinned quality tools, two-runtime CI, contribution/security guidance, and an operator guide. It is stacked on the existing reconciliation work so that its ignore/provenance changes are retained without merging automatically.

This is implementation evidence for PowerShell object handling, parameter validation, error propagation, privacy defaults, mocking, static analysis, and CI. It is not evidence of deploying AD, configuring Group Policy, administering a production server fleet, or delivering an enterprise maintenance product.

## Prioritized remaining work

| Priority | Bounded next change | Acceptance evidence / dependency |
| --- | --- | --- |
| P0 | Review the existing foundation PR and this preview; validate both CI runtimes | Exact commit/run results; no assumed pass and no automatic merge |
| P0 | Confirm source/licensing rights and review legacy firewall/history privacy | Maintainer decision; no destructive history rewrite or blanket relicensing |
| P0 after CI | Protect main with PRs and the actual PowerShell quality check | Verify the check exists and succeeds first; prevent force-push/deletion without locking out a solo maintainer |
| P1 | Read-only AD inventory for an explicitly selected server/search base | RSAT prerequisites; bounded query; mocked failures; authorized isolated AD lab; no credentials or real directory data committed |
| P1 | GPO backup/reporting with explicit destination and overwrite rules | Stable GUID-based filenames; no policy application; mocked tests; real backup and documented lab restore verification |
| P1 | WEF/event collection health | Distinguish empty log, disabled subscription, access failure, stale data, and healthy flow; do not call one recent event a complete health check |
| P1 | Windows Server backup and DHCP export examples | No scheduled/forced backup or lease export by default; explicit data handling; actual restore/recovery exercise before claiming recoverability |
| P1 | Selected workstation checks and handoff evidence | Defined baseline requirements and unknown/error states; no repairs inside a validator; existing organizational checklist approval remains required |
| P2 | Small DSC/Ansible lab | Pin the chosen tool generation; synthetic inventory; external secrets; plan/check mode and lab evidence |
| P3 | Technician GUI / catalog | Only after task implementations, wrappers, guides, and failure handling are mature |

No DTS/DTP software, packages, integrations, or private configuration are included in any current milestone. No remote actions, enrollment, updates, hardening changes, removal, or production deployment are authorized by this plan.

## Resume evidence

For completed implementation work, an accurate project description is: "Developed a PowerShell preview for local Windows inventory and bounded target selection, with synthetic Pester tests, static analysis, and a two-runtime GitHub Actions workflow." Add "passing CI" only after the actual reviewed commit passes. Add Windows 11 lab validation only after those cases are recorded.

Do not claim "automated enterprise endpoint management," "deployed Active Directory/Intune," fleet scale, time saved, uptime improvements, or production security outcomes from this preview. Add each capability to the resume only when its code, test results, and lab or authorized work evidence exist. The [validation guide](Lab-Validation.md) separates those evidence levels.
