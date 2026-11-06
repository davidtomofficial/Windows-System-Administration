# DTO Technician Launchpad — active TODO

Updated 2026-11-05. Personal development only. This extends the existing README design; it does not replace its execution architecture.

**Implemented now:** offline planning-catalog validator and 26 named candidates; shared result contract candidate. **Not implemented:** component adapters, GUI, BAT launchers, execution engine, live upgrades or cleanup. All catalog candidates remain Planned with null launchers and execution disabled.

ID abbreviations below refer to stable `DTO-LP-###` and `DTO-WSA-###` tasks. DeviceCare and Imaging keep their existing IDs and acceptance records.

| ID | Priority | Status | Work / acceptance |
|---|---|---|---|
| DTO-LP-001 | P0 | Implemented, component checks passed | **Planning catalog and strict validation.** 26 non-executable candidates; duplicate keys/IDs, unexpected fields, non-null launchers and execution flags refused. Twelve planning checks and the 26-entry listing passed Windows CI run 42145612233 at deadfd6add0fb391dd3113e6fd9cfd501e8a7603. No action executed. |
| DTO-LP-002 | P0 | Open | **Release catalog contract.** Separate planned catalog from actions.json; exact implementation/version/hash, input schema, runtime/architecture, impact, prerequisites and native evidence required. Depends on LP-003/004. |
| DTO-LP-003 | P0 | Implemented candidate; native verification pending | **One result and evidence contract.** Version 1 records observation/action/verification independently, with strict states, source identity, original timestamps and bounded evidence references. Python saved-input validator, PowerShell in-memory producer and shared conformance cases implemented; [contract and completion boundary](../Docs/TASK-RESULT-CONTRACT.md). Native CI/readback required before closing this contract scope. Component adapters, dispatch, recovery and Windows 11 acceptance remain separate. |
| DTO-LP-004 | P0 | Open | **Fixed dispatch and safe parameters.** Known task IDs and owned relative paths only; no arbitrary shell, eval, URL execution or PATH-shadowed tools. Validate every entry point, including direct BAT/PowerShell. |
| DTO-LP-005 | P1 | Open | **Python interface with BAT fallback.** Retain original architecture. Search/category/details/Run/status/report; no blanket elevation; absent dependencies disable actions with guidance. Package runtime only after decision. |
| DTO-LP-006 | P0 | Open | **Privilege and target confirmation.** Show local vs remote and affected user; standard-user GUI, task-only elevation, exact resolved target confirmation for disruptive work. No stored credentials. |
| DTO-LP-007 | P0 | Open | **Management authority and conflicts.** Evidence per workload, not service presence. Unknown authority blocks changes; never reset managed policy just to make a task work. |
| DTO-LP-008 | P0 | Open | **Ownership, journal and recovery.** One conflicting mutation at a time; durable intent before effects, stable source/request identity, outcome uncertainty stops new changes. Recovery is action-specific. |
| DTO-LP-009 | P1 | Open | **Process lifetime and cancellation.** Responsive status, actual child/process identity, bounded observation, no completed status just because a terminal opens. Do not kill Windows servicing to satisfy a timer. |
| DTO-LP-010 | P1 | Open | **DeviceCare adapter.** Use DTO-DC-003/004 observations; retain Unknown and explicit no-change scope. No copied maintenance engine. |
| DTO-LP-011 | P1 | Open | **Imaging adapter.** Pin approved source and profile; distinguish running workstation assessment, local WIM inspection, application provisioning and OS deployment. Preserve DTO-IMG acceptance rows. |
| DTO-LP-012 | P1 | Open | **Windows migration journey.** Expose WSA-011..014 as distinct readiness, compatibility, backup/migration, upgrade and postflight steps. No bypass, automatic restart or universal green light. |
| DTO-LP-013 | P1 | Open | **Profile and storage review journey.** WSA-015..018: read-only candidates first; no preselected deletion or age-only approval; previews enumerate selected targets and exclusions. |
| DTO-LP-014 | P1 | Open | **Network, print, events and services.** WSA-019..022: symptom-driven bounded reads with raw evidence coverage. Explicit selected probe/network contact; no implicit spooler/reset/service changes. |
| DTO-LP-015 | P2 | Open | **Applications and OEM adapters.** WSA-023..025: official sources, entitlement, detection, update owner, signature/hash checks, reboot/firmware recovery. One update route per app. |
| DTO-LP-016 | P2 | Open | **Management and identity adapters.** WSA-026..030: collection/export, cloud registration, sync, join, rename, remote restart and GPO export are separate approvals/outcomes. |
| DTO-LP-017 | P1 | Open | **Privacy and report export.** Project allowlisted fields; real endpoint dumps stay local/private. Preview/redact export; no automatic upload, contact or telemetry. |
| DTO-LP-018 | P2 | Open | **Offline acquisition and catalog freshness.** Explicit opt-in vendor acquisition; no execute-from-internet. Expired or unavailable catalog facts stay unknown; cache identities and entitlement separately. |
| DTO-LP-019 | P1 | Open | **DTO identity and accessible interaction.** Approved DT master and consistent version/contact; keyboard, focus, high contrast, screen reader and 100-200% DPI on actual Windows 11. |
| DTO-LP-020 | P1 | Open | **Acceptance and first released actions.** Start with read-only workstation evidence. Test direct PS/BAT/GUI positive and refusal paths, denied permissions, localization, offline, spaces and paths; release action by action. |
| DTO-LP-021 | P2 | Open | **Knowledge and handoff.** WSA-033: local references, dated official links, selected report location and operator signoff; documentation is not installed functionality. |
| DTO-LP-022 | P0 | Open | **Distribution and restore.** Source allowlist, reproducible archives, independent readback, release signing and rollback. Hash equality is not publisher trust; no unsigned operational release promotion. |

## Delivery order

Planning and result contracts → reviewed read-only adapters → fixed dispatch and wrappers → GUI → separately reviewed mutation adapters. GUI buttons do not grant authority. Existing product evidence stays tied to exact source and test context.

## Developer checks

```text
python Launchpad/plan.py
python Launchpad/test_plan.py
```

The validator lists metadata only; it cannot run a command. See [Windows administration master](../Docs/DTO-WINDOWS-ADMIN-TODO.md) and [migration/cleanup design](../Docs/Technician-Migration-and-Cleanup.md).

## Required check-in continuation — November 5, 2026

- [ ] **DTO-LP-023 / P1 — Required periodic check-in for future permission-licensed builds.** Implement the shared DTO-WSA-042–046 requirements with disclosed authorized enrollment, minimal aggregate usage, a verified owner-controlled receiver, receipt/retention controls and safe offline behavior. Current code has no check-in or usage telemetry. Existing license grants remain unaffected.

[Shared implementation contract](../Docs/USAGE-CHECK-IN.md) · [Repository continuation TODO](../Docs/REPOSITORY-REVIEW-TODO.md)
