# Windows System Administration

A generic Windows administration portfolio, starting with **read-only local inventory, safe computer-name selection, automated tests, and reviewable operating procedures**. Workstation preparation, maintenance, Windows Server, Active Directory, Group Policy, monitoring, and recovery remain the longer-term direction.

**Status: development preview, not a production release.** The WindowsSysAdmin module is the first executable implementation. Its version is 0.1.0-preview1; that version does not imply a published release. Check the pull request's actual CI results and the [validation guide](Docs/Lab-Validation.md) before making compatibility claims. A successful inventory is not a security or operational-readiness verdict.

## What exists now

| Component | Implemented behavior | Boundary |
| --- | --- | --- |
| [WindowsSysAdmin module](Modules/WindowsSysAdmin/WindowsSysAdmin.psd1) | Get-WsaComputerInventory collects local OS, hardware, boot, and domain-membership information. | Windows-only CIM queries; no updates, enrollment, repairs, or automatic report files. Direct identifiers are omitted unless requested. |
| Same module | Resolve-WsaComputerGroup validates explicit short names or expands a bounded range. | Offline name selection only; no DNS/AD discovery, remote sessions, RDP, restarts, or fleet changes. |
| [Pester tests](Tests/PowerShell/WindowsSysAdmin.Tests.ps1) | Synthetic-data tests for privacy defaults, error handling, target limits, and invalid inputs. | Mocked CIM calls do not establish real-device compatibility. |
| [PowerShell CI](.github/workflows/powershell-ci.yml) | Syntax checks, PSScriptAnalyzer, Pester, and opt-in local CIM smoke tests on Windows runner jobs for powershell and pwsh. | Hosted Windows Server runner evidence is not Windows 11 hardware or enterprise lab validation. |
| [Existing workstation baseline](Apps-Programs/workstation-environment.md) | Office-worker target configuration and handoff requirements. | Design reference, not an installable image or implemented compliance engine. |

There is no GUI, application installer, AD/GPO integration, Intune/Autopilot runtime, backup tool, or maintenance engine in this preview. The detailed [repository blueprint](Docs/Repository-Blueprint.md) describes planned work, not available commands. The [implementation plan](Docs/Implementation-Plan.md) tracks the next bounded milestones.

## Try the read-only module

Use a reviewed checkout on an authorized Windows lab machine with Windows PowerShell 5.1 or PowerShell 7.4+. No administrator elevation is requested by the module; local CIM permissions still apply. Follow the host's existing script-signing and execution policy. Do not bypass policy to run this preview.

~~~powershell
Import-Module .\Modules\WindowsSysAdmin\WindowsSysAdmin.psd1 -Force
Get-WsaComputerInventory
Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 3
Resolve-WsaComputerGroup -ComputerName @('LAB-01', 'lab-01', 'LAB-02')
~~~

Computer name, serial number, and domain/workgroup name are null by default. -IncludeIdentifiers explicitly requests them. Other fields can still identify a system in combination; **review all output before sharing**. See the [operator guide](Guides/Read-Only-Inventory.md) for output handling, prerequisites, errors, and limitations.

## Validate a change

Install the pinned development dependencies listed in [TestDependencies.psd1](Tools/TestDependencies.psd1), then run:

~~~powershell
.\Tools\Test-Repository.ps1
# Explicitly allow the extra read-only CIM test on this Windows lab host:
.\Tools\Test-Repository.ps1 -IncludeRunnerSmoke
~~~

The validation command does not download software or change execution policy. It writes generated quality reports under ignored TestResults/. [CONTRIBUTING.md](CONTRIBUTING.md) contains dependency-installation instructions. CI uses disposable runners, a commit-pinned checkout action, read-only repository permissions, and a stable aggregate check named **PowerShell quality**. Branch protection remains a separate maintainer decision after that check has run successfully.

## Existing foundation and roadmap

| Audience | Reference |
| --- | --- |
| Technician | [Task-guide outline](Guides/README.md), [checklist outlines](Checklists/README.md), and [read-only inventory guide](Guides/Read-Only-Inventory.md) |
| Developer | [Script conventions](Scripts/README.md), [contribution guide](CONTRIBUTING.md), and [implementation plan](Docs/Implementation-Plan.md) |
| Maintainer reviewing legacy material | [Migration map](Docs/Migration-Map.md), [historical source inventory](Docs/Source-Status.md), and [provenance boundary](Docs/Provenance.md) |
| Reviewer assessing evidence | [Lab-validation requirements](Docs/Lab-Validation.md) and the PR's actual test logs |

The historical source inventory describes the pre-implementation snapshot. The removed OTS and Intune Scripts collections have not been restored or copied into this module. **DTS/DTP software, packages, integrations, and private deployment configuration are excluded.** This module is independent portfolio work, not a replacement for or import of those products.

The two existing firewall exports remain historical, environment-specific references, not approved policies. They may contain identifying data; see [network reference cautions](System-Hardening/Policies/Network/README.md). Do not infer that the repository's entire Git history has been sanitized or that secret scanning is enabled.

See [SECURITY.md](SECURITY.md), [provenance and licensing status](Docs/Provenance.md), and [CHANGELOG.md](CHANGELOG.md). No license, release, automatic merge, or production deployment is introduced by this preview.
