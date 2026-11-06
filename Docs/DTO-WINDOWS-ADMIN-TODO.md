# DTO Windows System Administration — active master TODO

## DTO-GH-ORG-006 continuation: flagship proof packages

Two [developer proof packages](PROOF-PACKAGES.md) make the selected Imaging comparison and DeviceCare finding workflows reproducible from fictional inputs. Both passed Windows PowerShell 5.1 and PowerShell 7 in run 42290078369, including expected results, fresh report exports, exact overwrite refusal and normalized JSON parity. Generated output and source artifacts were independently downloaded and verified. [Exact tested source and evidence](PROOF-PACKAGES.md#verification-checkpoint). This completes the two basic proof packages within the existing portfolio evidence task; broader portfolio, component implementation and attended acceptance remain open.

Navigation refreshed November 6, 2026. Use the integrated `main` tree and the component authorities below. The pre-correction main checkpoint `e0ceff7ed5e3b79d1b864ec91f94c2d58d2730cd` passed [integration CI run 42151225226](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42151225226) on the retained integration branch. The [earlier source-preservation receipt](REPOSITORY-REVIEW-STATUS.md) describes its own immutable checkpoint, not every later change. This index preserves existing task IDs. Each follow-up needs its own source/run and backup evidence; live runtime check-ins and A+ acceptance remain open.

| Scope | Authoritative tasks | Current interpretation |
|---|---|---|
| Windows workstreams | [DTO-WSA-001–040](DTO-WINDOWS-ADMIN-WORKSTREAMS.md) | Original workstream record preserved byte-for-byte. Its pre-integration branch observations are superseded only by the migration record below. |
| Repository migration, licenses and check-ins | [DTO-WSA-041–048 and DTO-GH review tasks](REPOSITORY-REVIEW-TODO.md) | Active continuation; distinguishes implemented source from unimplemented services. |
| DeviceCare | [DTO-DC-001–020](../Scripts/DeviceCare/TODO.md) and DTO-DC-021 in the shared review TODO | Read-only 0.2.0 preview; full desktop, maintenance and check-ins remain unaccepted. |
| Imaging | [DTO-IMG-001–013](../Scripts/Imaging-Provisioning/TODO.md) and DTO-IMG-014 in the shared review TODO | Read-only 0.2.0 preview now staged alongside DeviceCare; original branch retained. |
| Technician Launchpad | [DTO-LP-001–022](../Launchpad/TODO.md) and DTO-LP-023 in the shared review TODO | Planning validator and shared result contract; no executable task buttons or live component adapters. |
| A+ acceptance | [Repository quality contract](REPOSITORY-A-PLUS.md) | No grade awarded; manual and operational evidence remain open. |

[Before/after migration map](REPOSITORY-MIGRATION.md) · [Reviewer guide](REVIEWER-GUIDE.md) · [Work-agent continuation](WORK-AGENT-HANDOFF.md).

The shared check-in requirement is now recorded for all three programs. It is not a deployed collector or an implemented runtime requirement. Do not close it from a policy file or a source archive alone.

## DTO-WSA-015 continuation: profile inventory, November 6

**In progress: inventory stage implemented and CI-verified; broader acceptance open.** The additional [profile inventory command](../Scripts/Imaging-Provisioning/docs/PROFILE-INVENTORY.md) reads bounded local profile metadata with identifiers omitted by default, explicit uncertainty and no removal eligibility. [Windows run 42285198826](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42285198826) passed the initial implementation's 183 Windows PowerShell 5.1/native and 152 PowerShell 7 profile checks. Existing workstation, service and WIM commands retain their source bytes.

This is progress on the existing DTO-WSA-015 task in the preserved workstream record. Complete session evidence, protected/shared-account policy, ownership review and attended Windows 11 acceptance remain open. DTO-WSA-016 profile removal and DTO-WSA-004 protected changes are not enabled. Current execution evidence is recorded in [Imaging validation](../Scripts/Imaging-Provisioning/docs/VALIDATION.md).

## DTO-LP-003 continuation: shared result contract, November 6

November 6 continuation: [DTO-LP-003 result contract](TASK-RESULT-CONTRACT.md) adds
independent observation/action/verification records and a bounded local producer
and consumer. The component TODO records its actual validation status. This advances
the result-format portion of DTO-WSA-003; input/privilege contracts, dispatch and
live integration remain open under WSA-003, LP-004/010/011 and DC-018. The original
workstream record remains preserved.

## Current implementation continuation: November 6, 2026

**DTO-WSA-010 / DTO-IMG-004 and DTO-IMG-007: selected workstation observation comparison implemented and verified within its bounded scope.** A separate module compares seven known fields from two selected schema 2 snapshots, preserves original observation times and distinguishes Changed, Unchanged and Unknown with per-side coverage. Its 73 synthetic checks passed in each of Windows PowerShell 5.1 and PowerShell 7 in run 42285281367. The existing collector source remains unchanged. [Contract and reproducible fictional example](WORKSTATION-COMPARISON.md) | [Exact source and component test evidence](../Scripts/Imaging-Provisioning/docs/VALIDATION.md#selected-observation-comparison).

The full DTO-WSA-010 handoff remains open for required/optional policy checks, peripherals, user workflows and human signoff. The comparison does not prove same-device identity, action success, deployment readiness or Windows 11 acceptance. This dated continuation adds implementation evidence to the preserved workstream record; it does not rewrite that record's historical branch observations or close unrelated tasks.

**Native comparison integration follow-up complete:** [PR 23](https://github.com/davidtomofficial/Windows-System-Administration/pull/23) adds six assertions against the real Windows collector and existing HTML renderer, preserving the canonical comparator and its 73 synthetic checks. [Run 42287053182](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42287053182) passed 98 Imaging Windows PowerShell 5.1/native checks and 82 PowerShell 7 checks, plus the 73 comparison checks in each version. [Exact tested source and limits](../Scripts/Imaging-Provisioning/docs/VALIDATION.md#native-comparison-integration---november-6-2026). The broader DTO-WSA-010, DTO-IMG-010 and DTO-IMG-011 acceptance remains open.
