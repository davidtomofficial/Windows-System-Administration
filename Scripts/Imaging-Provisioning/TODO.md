# DTO Imaging - active TODO

Revision: 2026-11-05 audit / 0.2.0 development preview. This is the active project tracker, mirrored to the DTO SharePoint folder. Historical source records remain preserved and do not imply DTO completion.

## November 6 continuation: selected observation comparison

**DTO-WSA-010 with DTO-IMG-004 / DTO-IMG-007:** a separate read-only comparison module now projects seven known fields from two selected schema 2 workstation snapshots, preserving observation times and Changed/Unchanged/Unknown states. It retains partial evidence without treating it as absence, compares CPU name multisets without socket claims, and omits identifiers and extra fields. The original collectors are unchanged. See [usage and limits](README.md#compare-selected-workstation-observations) and [dated validation](docs/VALIDATION.md#selected-observation-comparison).

**Comparison implementation and regression scope verified:** 73 comparison checks passed in each of Windows PowerShell 5.1 and PowerShell 7 in [run 42285281367](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42285281367). [Exact tested source and limits](docs/VALIDATION.md#selected-observation-comparison). Preservation readback belongs in the separate dated receipt. The full DTO-WSA-010 handoff remains open for required/optional policy checks, peripherals, user workflows and human signoff. DTO-IMG-010 dashboard/profile migration and DTO-IMG-011 attended Windows 11 acceptance remain open. Comparison does not establish same-device identity, a successful action or deployment readiness.

The original audit rows below remain the historical source record except where a dated continuation supplies newer evidence.

| ID | State | Scope and next acceptance |
|---|---|---|
| DTO-IMG-001 | Complete | Reconcile legacy Imaging TODO, current joint master scope and Phase 1 source/archive. Phase 1 ZIP differs from GitHub in README/script and document membership; retain both, do not call them equivalent. |
| DTO-IMG-002 | Complete | Preserve pre-work GitHub source bytes and both original SharePoint trackers before changing them. Existing original technician checkpoint remains unchanged. |
| DTO-IMG-003 | Implemented | DTO palette and published contact verified; offline report and metadata updated. Official DT artwork, taskbar/installer icon and WPF adoption remain pending. |
| DTO-IMG-004 | Implemented | Snapshot schema 2; identifier opt-in, field projection, per-source coverage and sanitized errors. Native results recorded separately. |
| DTO-IMG-005 | Implemented subset | Bounded service collector with partial evidence retention. Application-name relationships, profile-bound evidence replay, policy/health/dependency analysis and UI not yet ported. No service changes. |
| DTO-IMG-006 | Implemented | Non-deploying local WIM inspection, explicit index, optional SHA-256 and metadata-stability checks. Real OS images and deployment compatibility remain unqualified. |
| DTO-IMG-007 | Implemented | Offline HTML evidence report with encoding, DTO palette and no automatic transmission. Actual keyboard, zoom, screen reader and High Contrast review remain open. |
| DTO-IMG-008 | Passed within stated scope | Windows Server 2022: 87 PowerShell 5.1 checks including native CIM/service/synthetic-WIM and 77 PowerShell 7 contract checks; eight Python packaging tests. Exact tested commit e71a47e356d1a070d57aa64e8978a0077f3dd323. Read docs/VALIDATION.md for limits. |
| DTO-IMG-009 | Per-checkpoint verification | Pre-work source/trackers preserved and pre-work ZIP retrieved with matching SHA-256. Current source ZIP and tracker readbacks must be confirmed in the dated DTO-Imaging-Verification-2026-11-05.json receipt; an upload acknowledgement alone is not completion. Repeat on every change. |
| DTO-IMG-010 | Open | Port original WPF dashboard, saved profile editor, catalog and full application/service evidence contracts after file-level review. Current source is not 0.23 feature parity. |
| DTO-IMG-011 | Open | Attended Windows 11, DPI, keyboard/Narrator/High Contrast and workstation handoff. Original 55 attended acceptance rows are inherited as pending, not silently passed. |
| DTO-IMG-012 | Deferred | Code signing and commercial staff identity are not blockers for owner-approved controlled development. Approved operational distribution/trust remains a later gate. |
| DTO-IMG-013 | Not implemented here | OS apply, partitioning, disk erase, app installer execution, domain/enrollment changes and protected restoration. Do not enable before separate review and acceptance. |

No public release promotion, service changes, paid launch or employer/private source publication is implied by this source branch.

## Required check-in continuation — November 5, 2026

- [ ] **DTO-IMG-014 / P1 — Required periodic check-in for future permission-licensed builds.** Implement the shared DTO-WSA-042–046 requirements with disclosed authorized enrollment, minimal aggregate usage, a verified owner-controlled receiver, receipt/retention controls and safe offline behavior. Current code has no check-in or usage telemetry. Existing license grants remain unaffected.

[Shared implementation contract](../../Docs/USAGE-CHECK-IN.md) · [Repository continuation TODO](../../Docs/REPOSITORY-REVIEW-TODO.md)
