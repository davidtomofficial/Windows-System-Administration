# Existing Material: Review and Migration Map

**Status:** Inventory draft, September 26, 2026. Locations below are proposals. No existing scripts have been moved, refactored, executed, or validated by this planning pass.

The inventory uses the [current repository tree](https://github.com/davidtomofficial/Windows-System-Administration) and the user's screenshot. Screenshot filenames suggest review categories but do not establish what the scripts actually do. Review source content before choosing a final name or destination.

## Current GitHub material

| Current location | Proposed destination or handling | Review needed |
| --- | --- | --- |
| Root `README.md` | Rewrite around the lifecycle and technician/developer entry points. | Update Windows 10 references and old account links. Check license and contribution links against actual repository files before replacing them. |
| `Apps-Programs/workstation-environment` | Adopt the existing local Markdown rewrite; later move the full baseline to `Baselines/Workstation/Windows11-25H2.md`. | Replace the extensionless source deliberately and update links. Keep one authoritative baseline. |
| `Intune Scripts/AutoPilot Enrollment/` | Split collection and registration behavior into `Scripts/Management/Autopilot/`; put usage in `Guides/`. | Determine whether current code exports locally, uploads to a tenant, or performs other changes. Separate outcome reporting. |
| `Intune Scripts/Sync Work or School Account/` | Reviewed implementation under `Scripts/Management/Intune/` or the appropriate identity integration. | Identify the actual sync mechanism and enrollment prerequisites; do not assume that every work/school account is Intune-managed. |
| `OTS/Post Checks/postChecks.ps1` | Source for `Scripts/Validation/` and `Scripts/Maintenance/` after content review. | Split read-only checks from updates, repairs, and other changes according to actual behavior. Preserve useful functionality. |
| `OTS/Post Checks/postChecks.xlsx` | Evaluate as source material for `Checklists/` or a maintained reference attachment. | Inspect formulas, data, external connections, and suitability for public storage; wait for the user's current checklists before standardizing. |
| `OTS/Post Checks/Demo Images/` | Keep useful, sanitized screenshots with the related guide. | Confirm screenshots match the final tool and contain no private device/user information. |
| `OTS/QOS/bulkLogin.ps1` | Provisional `Scripts/Remote-Actions/`. | Compare with the similarly named screenshot file; check actual purpose, credential handling, scope, and dependencies. |
| `System-Hardening/inbound-firewall-settings.txt` and `outbound-firewall-settings.txt` | Retain under `System-Hardening/` pending classification. | Decide whether each is policy documentation, a reference export, or consumable configuration. Do not treat it as an approved policy solely because it exists. |

## Screenshot inventory

| Filename or group | Provisional review category | Migration decision to make |
| --- | --- | --- |
| `blowOutProfiles.bat`, `blowOutProfiles.ps1` | `Scripts/Maintenance/` plus a BAT launcher | Establish profile/data deletion scope, exclusions, operator guidance, and recovery implications before naming the maintained task. |
| `fullDiskCleanup.ps1` | `Scripts/Maintenance/` | Identify paths and data affected; distinguish reporting from cleanup. |
| `restartComputers.bat`, `restartComputers.ps1`, `shutdownComputers.ps1` | `Scripts/Remote-Actions/` plus launchers | Standardize explicit target preview, credentials/permissions, timing, cancellation where supported, and per-target results. |
| `bulkLogin.ps1`, `bulkPS-Session.ps1`, `Remote-Invoke.ps1`, `openDrives.ps1` | `Scripts/Remote-Actions/` pending review | Determine purpose, supported connection methods, session cleanup, and whether a field-facing button is appropriate. |
| `copyblowOutFromJ.ps1`, `copyrestartComputersFromJ.ps1`, `copyWifiFromJ.ps1` | Related maintenance, remote-action, or troubleshooting tasks | Compare shared copy/deployment behavior and replace fixed drive assumptions with configuration where appropriate. Do not assume these are duplicates. |
| `Wifi Script Fix 2.bat`, `Wifi Script Fix 2.ps1` | `Scripts/Troubleshooting/` plus a launcher | Compare variants, establish the network changes, and adopt one descriptive canonical name. |
| `wingetInstaller.ps1` | `Scripts/Deployment/` or `Apps-Programs/Acquisition/` | Determine whether it installs WinGet itself, applications through WinGet, or both. Separate the functions if useful. |
| `runPostChecks.bat` | `Launchpad/Launchers/` | Confirm which script it calls and preserve it as a thin wrapper if still needed. |
| `ManualWin11_Upgrade` shortcut | `Guides/06-Windows-Upgrade-and-Migration.md` and an eventual supported launcher | Inspect its target and arguments; replace machine-specific paths with a portable procedure. |
| `executeAndSign.ps1` | Developer tooling; final location undecided | Review execution and signing responsibilities, certificate access, and artifact handling. Do not publish private signing material. |
| `Win11BypassReqs2.cmd` | Separate exception review | Determine its actual behavior and support implications. Exclude requirement bypass from the standard supported upgrade workflow. |
| `tmp.bat`, `tmp.ps1` | Unclassified | Inspect contents and references before retaining, renaming, or retiring them. |

## Review record for each imported tool

Record its source path, intended owner, actual behavior, inputs, dependencies, required privilege, network/service access, outputs, restart behavior, data affected, proposed location, and current validation status. Compare variants by content before selecting a canonical implementation.

Import sequence:

1. Inventory original files and preserve their provenance.
2. Review source and private environment assumptions.
3. Select the canonical implementation and separate interface wrappers where useful.
4. Apply the [script conventions](../Scripts/README.md), add its guide, and update references.
5. Validate on appropriate lab devices, including failures and interrupted runs.
6. Add a task to the launchpad only when its script and operator procedure are ready together.

Use Git history for previous versions. Unreviewed files should stay out of the released task catalog; do not automatically delete or publish them during cleanup.
