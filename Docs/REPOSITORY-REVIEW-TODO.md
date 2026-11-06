# Repository review and migration — active continuation

November 5, 2026. Parent: DTO-GH-001. Existing DTO-WSA-001–040, DTO-DC, DTO-IMG and DTO-LP work remain open or completed exactly within their recorded scope.

| ID | Priority | Status | Deliverable / acceptance |
|---|---|---|---|
| DTO-GH-001-A | P1 | Reviewed, bounded | Six public repositories classified by metadata/README; existing GPL notices and third-party attributions identified. Full historical/file/dependency audit is not complete. |
| DTO-GH-001-B | P1 | Published and source-verified | DeviceCare, Imaging and planner share the reviewed main tree. Original branches, parent commits and prework preserve source history; full Windows Server integration checks passed in run 42149193243 and the source archive matched SharePoint readback. Actual deployed-device acceptance remains open. |
| DTO-GH-001-C | P1 | Published; manual review open | Root reviewer routes, capability table, licensing links, task index and clear development labels are on main. Automated core-link checks passed; attended public/keyboard/narrow-screen review remains open before an A+ score. |
| DTO-GH-001-D | P2 | Open | Curate academic archive after per-file ownership/course/media/license review. Do not rename, transfer, relicense or delete current repositories in bulk. |
| DTO-GH-001-E | P1 | Open | Reconcile existing draft PRs #1/#2/#3/#12/#16 and current issue references; preserve draft holds and WordPress-only publishing. No auto-merge or Pages activation. |
| DTO-WSA-041 | P0 | Notice/package inclusion verified; legal acceptance open | Permission-required notice is on main and included in both source packages; repository contracts checked bytes and preserved existing-license/platform/statutory exceptions. Existing GPL grants remain. Ownership, written agreements and legal review are not completed. |
| DTO-WSA-042 | P1 | Requirement documented; NOT implemented | Required periodic check-in for future permission-licensed DeviceCare, Imaging and launchpad builds. Fix actual endpoint/cadence/retention/terms and disclose data use before enrollment. No runtime tracking now. |
| DTO-WSA-043 | P1 | Open | Owner-controlled receiver: approved hosting, HTTPS, authenticated enrollment, bounded schema, idempotent counts, protected dashboard, retention/deletion and tested recovery. No made-up live URL or public telemetry store. |
| DTO-WSA-044 | P1 | Open | Client lifecycle: pseudonymous ID, protected credential, aggregate-use queue, receipts, retry/backoff, offline grace and safe expiration. No reporting before disclosed enrollment; no hardware fingerprints, silent service or task interruption. |
| DTO-WSA-045 | P1 | Open | Per-program integration: direct CLI and future UI/wrappers share the same applicable entitlement boundary. Current source can be modified by recipients; do not promise unbypassable public-source tracking. |
| DTO-WSA-046 | P1 | Open | End-to-end usage proof on explicitly authorized test installations; duplicate counting, downtime, clock changes, retention and safe expiry. A mock/server unit test is not deployed usage telemetry. |
| DTO-WSA-047 | P1 | Passed for exact source; ongoing for later commits | Windows Server 2022 run 42149193243 at bc80d476327bcb072e57c38a4cb97c18220865b9 passed 65/60 DeviceCare PowerShell, 87/77 Imaging PowerShell, 12 DeviceCare Python, 8 Imaging Python, 12 Launchpad and 13 repository-contract checks. Review archive: 53 source files, 95,922-byte inner ZIP; no operational/A+ acceptance. |
| DTO-WSA-048 | P1 | Main published and backup readback verified; A+ incomplete | Both `main` and integration ref contain tested source bc80d476327bcb072e57c38a4cb97c18220865b9; previous main and source parents are preserved. 144,730-byte CI/source/prework ZIP matches SharePoint by SHA-256 f0432a7fbf44280911241b73a3b196470a4a94af583377e2534124d9f0b0ee1d. Manual/accessibility, ownership and future check-in service remain open. |
| DTO-DC-021 | P1 | Open, shared dependency | DeviceCare must implement WSA-042–046 for future permission-licensed builds. Existing read-only preview remains local-only. |
| DTO-IMG-014 | P1 | Open, shared dependency | Imaging must implement WSA-042–046 without interrupting imaging/recovery or uploading device evidence. Existing preview remains local-only. |
| DTO-LP-023 | P1 | Open, shared dependency | Launchpad must integrate the shared licensed-build check-in contract when actual dispatch exists. Planner listing is not counted as a performed maintenance task. |

## Completion evidence required

Exact source hashes, actual native/client results, validated archive membership, fresh remote readbacks, scope-limited public navigation review and retained rollback. Keep unresolved items visible. Changes to reference material are not evidence of a running application.

## Immediate next work

The current read-only integration passed CI and source/archive readback. Use [WORK-AGENT-HANDOFF.md](WORK-AGENT-HANDOFF.md) to finish manual repository/A+ acceptance, provenance review and actual licensed-build check-in design before release. Then prioritize shared action/result contracts, read-only profile inventory and native DTO dashboard. Upgrade, cleanup and profile removal remain disabled until separately qualified.
