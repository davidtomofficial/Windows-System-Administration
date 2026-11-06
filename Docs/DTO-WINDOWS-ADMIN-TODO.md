# DTO Windows System Administration — active master TODO

Navigation refreshed November 6, 2026. Use the integrated `main` tree and the component authorities below. The pre-correction main checkpoint `e0ceff7ed5e3b79d1b864ec91f94c2d58d2730cd` passed [integration CI run 42151225226](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42151225226) on the retained integration branch. The [earlier source-preservation receipt](REPOSITORY-REVIEW-STATUS.md) describes its own immutable checkpoint, not every later change. This index preserves existing task IDs. Each follow-up needs its own source/run and backup evidence; live runtime check-ins and A+ acceptance remain open.

| Scope | Authoritative tasks | Current interpretation |
|---|---|---|
| Windows workstreams | [DTO-WSA-001–040](DTO-WINDOWS-ADMIN-WORKSTREAMS.md) | Original workstream record preserved byte-for-byte. Read the migration record and current task updates below for later implementation evidence. |
| Repository migration, licenses and check-ins | [DTO-WSA-041–048 and DTO-GH review tasks](REPOSITORY-REVIEW-TODO.md) | Active continuation; distinguishes implemented source from unimplemented services. |
| DeviceCare | [DTO-DC-001–020](../Scripts/DeviceCare/TODO.md) and DTO-DC-021 in the shared review TODO | Read-only 0.2.0 preview; full desktop, maintenance and check-ins remain unaccepted. |
| Imaging | [DTO-IMG-001–013](../Scripts/Imaging-Provisioning/TODO.md) and DTO-IMG-014 in the shared review TODO | Read-only 0.2.0 preview now staged alongside DeviceCare; original branch retained. |
| Technician Launchpad | [DTO-LP-001–022](../Launchpad/TODO.md) and DTO-LP-023 in the shared review TODO | Planning validator only; no executable task buttons. |
| A+ acceptance | [Repository quality contract](REPOSITORY-A-PLUS.md) | No grade awarded; manual and operational evidence remain open. |

[Before/after migration map](REPOSITORY-MIGRATION.md) · [Reviewer guide](REVIEWER-GUIDE.md) · [Work-agent continuation](WORK-AGENT-HANDOFF.md).

The shared check-in requirement is now recorded for all three programs. It is not a deployed collector or an implemented runtime requirement. Do not close it from a policy file or a source archive alone.

## DTO-WSA-010: workstation comparison continuation

**November 6, 2026: implemented comparison subset.** The new Imaging comparison module compares two caller-selected workstation snapshots using seven known OS/hardware fields, recorded timestamps and collection coverage. Missing or incomplete evidence remains Unknown. Processor names are compared as a multiset, preserving repeated identical processors without depending on enumeration order. Device identity, device health, deployment acceptance and human handoff are not inferred.

[Comparison guide and supported scope](../Scripts/Imaging-Provisioning/docs/SNAPSHOT-COMPARISON.md) | [Component validation](../Scripts/Imaging-Provisioning/docs/VALIDATION.md). The existing observation and image-inspection runtime remains unchanged. The broader DTO-WSA-010 work still needs required/optional criteria, peripheral and user-workflow evidence, operator signoff and attended acceptance. This continuation does not close that parent task or the native Imaging dashboard/profile migration.
