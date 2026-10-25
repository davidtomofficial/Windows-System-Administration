# Windows System Administration

A planned Windows workstation toolkit for preparing, assigning, maintaining, troubleshooting, and retiring devices. The foundation supports a workstation that can be deployed without Intune or Autopilot, with optional Active Directory, Microsoft Entra ID, Intune, and Autopilot integrations.

**Status: foundation draft — source inventory reviewed October 24, 2026.** This repository contains documentation, a proposed structure, and firewall reference exports. The launchpad, launchers, application catalog, and PowerShell tools described here are planned, not implemented or validated on the current branch. The previous `OTS` and `Intune Scripts` folders are available in Git history; see the [source status and provenance](Docs/Source-Status.md) before importing them.

## Start here

| Audience | Start with | Purpose |
| --- | --- | --- |
| Field technician | [Task guides](Guides/README.md) | Find the procedure for an assigned job. |
| Field technician | [Launchpad design](Launchpad/README.md) | Understand the proposed simple interface and task buttons. |
| Deployment technician | [Current workstation baseline](Apps-Programs/workstation-environment.md) | Review the proposed Windows 11 25H2 environment. |
| Assignment or asset-management staff | [Checklist outlines](Checklists/README.md) | See where existing assignment and return checklists will fit. |
| Developer or maintainer | [Repository blueprint](Docs/Repository-Blueprint.md) | Review the complete proposed hierarchy and responsibilities. |
| Developer or maintainer | [Script conventions](Scripts/README.md) | Keep scripts, wrappers, outputs, and validation consistent. |
| Maintainer importing existing tools | [Migration map](Docs/Migration-Map.md) | Review the known repository content and screenshot inventory. |
| Maintainer locating existing code | [Source status and provenance](Docs/Source-Status.md) | Distinguish current files, historical scripts, and source still to be reconciled. |

## Two ways into the same tools

```text
Field technician: assigned job → guide/checklist → launchpad button or BAT launcher → result
Developer:       task definition → PowerShell implementation → verification → release
```

The Python launchpad will provide a simple interface. BAT files will provide direct access to the same tasks. PowerShell will hold the actual device-management logic.

The workstation baseline defines the desired environment; validation reports whether a device meets the selected requirements. A baseline or successful tool run does not guarantee that a device is completely secure.

## Source and implementation status

The foundation documents were originally prepared in a local staging area and are now committed here. The repository does not currently include an executable DeviceCare implementation. Historical scripts must be compared with the maintained source before choosing a canonical version or restoring files.

New script names in the blueprint are proposed names; they must not be presented as working commands until implemented and tested. Private configuration, runtime reports, and package payloads are covered by [.gitignore](.gitignore); sanitized examples and documentation remain trackable. Ignore rules do not remove files already committed.

See [CHANGELOG.md](CHANGELOG.md) for documentation changes and [the blueprint](Docs/Repository-Blueprint.md) for implementation phases.
