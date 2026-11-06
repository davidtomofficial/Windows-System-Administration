# DTO Windows System Administration — master development TODO

Updated 2026-11-05. Scope: personal tools, technician workflows and portfolio evidence. This is the technical coordination index under the existing portfolio program, not a replacement for component TODOs.

**Current delivery:** DeviceCare 0.2.0 source candidate (offline report/branding and threshold corrections); Launchpad planning validator and 26 non-executable catalog candidates; expanded implementation backlog. No main-branch merge, client deployment, OS upgrade or profile/data removal.

## Component authority

- DeviceCare: `Scripts/DeviceCare/TODO.md`, DTO-DC IDs.
- Imaging: `dto/imaging-migration-20261105`, DTO-IMG IDs; latest observed head `173cda83ef639f16a7a5acf641f350bca79c7cca`. Remains separate, not included in this branch.
- Launchpad: `Launchpad/TODO.md`, DTO-LP IDs; planned actions are not executable.

All tasks below owned by the DTO Windows administration workstream; subcomponents retain their task authority. P0 means dependency/safety foundation; P1 is next useful implementation; P2 follows core behavior.

| ID | Priority | Status | Work and acceptance |
|---|---|---|---|
| DTO-WSA-001 | P0 | Implemented coordination | **Source and branch map.** Main remains unchanged. DeviceCare feature branch and Imaging migration branch are separate. Reconcile source/rights/versions before merging; preserve branch-specific tests and history. |
| DTO-WSA-002 | P0 | Ongoing | **Preservation and truthful progress.** Before edits retain exact source/trackers; after publication read back hashes and report actual test scope. No percent-complete from test counts. |
| DTO-WSA-003 | P0 | Open | **Shared task and result contracts.** One maintained PowerShell implementation per operation; use LP-003/004. Define schema, inputs, privilege, scope, privacy, structured outcome and exit behavior. |
| DTO-WSA-004 | P0 | Open | **Protected changes and recovery.** Machine lock, durable journal, source/request binding, timeout uncertainty and action-specific rollback. No silent changes, reboot, forced restart or unsupported repair. |
| DTO-WSA-005 | P1 | Implemented subset | **DTO branding migration.** DeviceCare offline report uses original DT SVG and tokens. Native WPF, executable/shortcut/icon, cross-tool adoption and attended accessibility remain open (DC-010/019). |
| DTO-WSA-006 | P1 | Open | **Portfolio foundation reconciliation.** Review foundation/inventory branches and draft PRs; preserve useful generic helpers, remove private assumptions only after review, no history rewrite or automatic merge. |
| DTO-WSA-007 | P1 | Implemented subset | **DeviceCare development.** Continue DTO-DC-001..020. Current app covers OS/memory/disk evidence and reporting only, not full historical application parity. |
| DTO-WSA-008 | P1 | Open | **Imaging and provisioning.** Continue DTO-IMG-001..013; use latest branch checkpoint, not stale package pointers. WIM metadata is not deployment readiness; profile editor/catalog/WPF/full acceptance remain. |
| DTO-WSA-009 | P1 | Implemented planning | **Technician launchpad.** Track DTO-LP-001..022; 26 non-executable candidates, validator only. Release no action until script/wrapper/guide/native evidence qualifies. |
| DTO-WSA-010 | P1 | Open | **Validate and hand off.** Read-only baseline comparison, required vs optional checks, Unknown/partial coverage, peripheral/user workflow evidence and selected private report. Human signoff distinct. |
| DTO-WSA-011 | P1 | Open | **Windows 11 readiness.** Exact source/target edition, build, architecture, supported CPU/TPM/UEFI/Secure Boot, storage, license, app/driver and management evidence. No hardware/hold bypass. |
| DTO-WSA-012 | P1 | Open | **Setup compatibility and issue review.** Opt-in supported ScanOnly, exact setup/media identity and log location, dynamic-update choice, native exit normalization and current target-specific release-health review. No installation implied. |
| DTO-WSA-013 | P1 | Open | **Controlled Windows upgrade.** Require backup/restore and recovery-key custody, compatible media/language/edition, supported channel, management approval, operator restart choice; handle failure/rollback, postflight and driver/app validation. |
| DTO-WSA-014 | P1 | Open | **User-state migration and restoration.** Separate same-PC upgrade vs replacement migration. Select data/settings and applications; confirm USMT applicability, encrypted files, sync state and account mapping; verify restore and user outcome. |
| DTO-WSA-015 | P1 | Open | **Profile inventory and stale candidate review.** Read Win32_UserProfile observations and session status. Loaded/special/current/protected/service/shared/unknown profiles excluded; last-use is only a signal, not proof of abandonment. |
| DTO-WSA-016 | P1 | Open | **Selected profile removal.** Depends WSA-015 and004. Exact identity/selection, owner and retention approval, verified backup, sync/encryption checks, fresh no-session recheck, supported profile deletion API and verified outcome. No directory-only or age-only bulk delete. |
| DTO-WSA-017 | P1 | Open | **Storage and data review.** User-selected scope, sizes/types and safe exclusions; distinguish disposable cache from business/user data, cloud placeholders and linked paths. No recursive content reading by default. |
| DTO-WSA-018 | P1 | Open | **Selected cleanup.** Depends WSA-017/004. Preview exact categories/paths and conservative space estimate; preserve Downloads, Recycle Bin, restore points, Windows.old and logs unless separately approved. Never promise universal undo. |
| DTO-WSA-019 | P1 | Open | **Network troubleshooting.** Adapters/IP/DNS/routes/proxy/VPN/time and chosen endpoint tests. Passive vs active queries labeled; redact private names. Winsock/network resets and reconfiguration separate. |
| DTO-WSA-020 | P1 | Open | **Printer and USB diagnostics.** Queue/port/driver/device mapping, USB and network evidence, spooler state, errors and test-page selection. No automatic queue purge, driver removal or service reset. |
| DTO-WSA-021 | P1 | Open | **Event and reliability evidence.** Bounded time/window/filter; crashes, restart, update, driver, disk and application evidence, with exclusions and redacted exports. Correlation is not confirmed cause. |
| DTO-WSA-022 | P1 | Open | **Service/application relationships.** Read-only presence/state/start mode/dependencies and declared app relationships. Presence is not health; no vendor-updater or security-service disable by default; controlled pause/restore separate. |
| DTO-WSA-023 | P1 | Open | **Software inventory and ownership.** Non-repair-triggering inventory, per-user vs machine scope, duplicate detection and owner/channel. Version presence is not app health or license entitlement. |
| DTO-WSA-024 | P2 | Open | **Approved application maintenance.** Selected packages only, source/version/hash/publisher, no downgrade, preserve user settings, restart/failure handling and independent installed detection. Official-source acquisition rights separate from public mirroring. |
| DTO-WSA-025 | P2 | Open | **OEM drivers and firmware.** Exact make/model, official package/entitlement, AC/battery/recovery/BitLocker prerequisites, rollback constraints, no generic driver updater or unattended firmware. |
| DTO-WSA-026 | P2 | Open | **Autopilot and provisioning export.** Local hash/export, tenant registration, profile assignment and enrollment each separate. Restricted outputs, source provenance, no tenant secrets or automatic enrollment. |
| DTO-WSA-027 | P2 | Open | **Intune/Entra/ConfigMgr integration.** Local evidence first; scoped delegated cloud access, explicit tenant/device, workload authority and selected sync. Request accepted does not mean compliance or symptom resolved. |
| DTO-WSA-028 | P2 | Open | **Naming, printers and selected configuration.** Validated naming/profile preview; domain effects, restart and managed policy respected; owned rollback only; no blanket environment changes. |
| DTO-WSA-029 | P2 | Open | **Remote and computer-group operations.** Explicit allowlisted targets, preview resolved list, count limits, least privilege and per-target results. Reboots/shutdowns require separate confirmation and no wildcard surprise. |
| DTO-WSA-030 | P2 | Open | **AD/GPO and server administration.** Read-only directory/OU and effective policy evidence; explicit GPO backup/report, DHCP export and WEF checks. RSAT/modules per need with preparation/cleanup ownership. |
| DTO-WSA-031 | P1 | Open | **Backup health and recovery proof.** Backup metadata is not a proven restore. Record tested restoration of selected files/device plus recovery access; no recovery keys in public reports. |
| DTO-WSA-032 | P2 | Open | **Return, reassignment and retirement.** Plan-only disposition; retention, endpoint reset/wipe, cloud-record removal, directory cleanup and asset handoff separate. Never assume record deletion erases a device. |
| DTO-WSA-033 | P2 | Open | **Technician knowledge and runbooks.** Task-specific guides, escalation evidence, dated first-party links, offline reference cache and human checklist. No external scripts executed from URLs. |
| DTO-WSA-034 | P1 | Open | **Source tests and CI coverage.** Retain negative controls; PS5.1/PS7 contracts, applicable Windows client/server separation, exact source hashes; no fixture-count summation across revisions. |
| DTO-WSA-035 | P1 | Open | **Windows 11 operator acceptance.** Physical client workflows, keyboard/Narrator/High Contrast and100-200% DPI, denied policy, offline, ARM64 support decisions; synthetic previews are not attended acceptance. |
| DTO-WSA-036 | P1 | Open | **Packaging, signing and release.** Explicit source allowlist, reproducible package, verified GitHub/SharePoint parity, publisher/trust, installer lifecycle and rollback; development tests do not authorize operational release. |
| DTO-WSA-037 | P1 | Open | **Repository navigation and maintenance.** Root navigation to active components and status; license/provenance decision, contribution policy, branch protection after reviewed CI, releases only after gates. No repo transfer/rename here. |
| DTO-WSA-038 | P2 | Open | **Optional infrastructure-as-code.** Review DSC/Ansible and lab scope only after stable helpers; no autonomous security-lab work or employer deployment. |
| DTO-WSA-039 | P1 | Open | **Privacy and evidence retention.** No identifiers by default; per-field export preview, private storage/retention, no automatic telemetry/upload and no actual device dumps in GitHub. |
| DTO-WSA-040 | P1 | Ongoing | **Cross-project status and scope.** Keep component TODO IDs authoritative; master coordinates dependencies rather than silently closing them. Preserve held work, source-specific failures and unrun device acceptance. |

## Next implementation sequence

Finish current source/CI/readback → read-only profile inventory and migration evidence contracts → DeviceCare native DTO dashboard and common adapter results → fixed task wrappers and launchpad interface → action-by-action controlled change/recovery acceptance. No deletion or upgrade is enabled by this roadmap.

## Boundaries

Standalone tools must not require Intune. Management integrations are optional and scoped. Never collect credentials or bypass enterprise execution policy, hardware requirements, safeguard holds or maintenance authority. Existing security labs stay manual-only and excluded from autonomous work.

See [migration and cleanup design](Technician-Migration-and-Cleanup.md), [Launchpad TODO](../Launchpad/TODO.md), [DeviceCare TODO](../Scripts/DeviceCare/TODO.md).
