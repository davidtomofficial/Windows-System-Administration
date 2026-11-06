# Windows System Administration

**David Tom Official · Systems, Automation & Software**

A reviewable collection of Windows technician tools, development previews and operational designs. Start with the implemented scope below, then follow its source, tests and limitations. This is a personal portfolio and development repository—not a production deployment kit.

> **Permission required:** public source is not an unrestricted use license. Read the [rights and permission notice](LICENSE.md) before running, deploying, modifying or redistributing covered original work. Existing licenses, third-party rights and lawful exceptions remain intact. [Request permission](https://davidtomofficial.com/#contact).

## Review the repository

| You want to… | Start here |
|---|---|
| Understand what works today | [Current capabilities and evidence](Docs/REVIEWER-GUIDE.md) |
| Review DeviceCare | [DeviceCare source and usage](Scripts/DeviceCare/README.md) · [TODO](Scripts/DeviceCare/TODO.md) |
| Review Imaging & Provisioning | [Imaging source and usage](Scripts/Imaging-Provisioning/README.md) · [TODO](Scripts/Imaging-Provisioning/TODO.md) |
| See the technician launchpad plan | [Launchpad](Launchpad/README.md) · [26 planning entries](Launchpad/catalog.plan.json) |
| Find priorities and continuation work | [Windows administration master](Docs/DTO-WINDOWS-ADMIN-TODO.md) · [Repository review TODO](Docs/REPOSITORY-REVIEW-TODO.md) |
| Review licensing or usage check-ins | [Permission notice](LICENSE.md) · [License scope](Docs/LICENSING.md) · [Check-in requirements](Docs/USAGE-CHECK-IN.md) |
| Finish this migration as a work agent | [Bounded continuation prompt](Docs/WORK-AGENT-HANDOFF.md) |

## Implemented versus planned

| Component | Current implemented scope | Not yet established |
|---|---|---|
| DeviceCare 0.2.0 development preview | Local OS/memory/system-drive observations; two threshold findings; offline DTO report with original DT artwork | Full desktop application, maintenance/repair, installed-device acceptance |
| Imaging 0.2.0 development preview | Workstation and bounded service observations; selected before/after snapshot comparison; local WIM metadata/index review and optional hash; offline report | Same-device verification, full handoff, bootable image, OS deployment, installer/recovery qualification |
| Technician Launchpad | Offline planning catalog, validator and tests | GUI, BAT wrappers, task dispatch; all 26 candidates remain non-executable |
| Periodic check-ins | Required future licensed-build design and acceptance backlog | Collector endpoint, client integration, real usage counts or enforcement |

Automated component tests are not a full-product or physical Windows 11 acceptance. See the [review guide](Docs/REVIEWER-GUIDE.md) for exact source/run references. No A+ grade has been awarded; the [quality contract](Docs/REPOSITORY-A-PLUS.md) keeps unverified criteria open.

## For authorized developers

Read the selected component README before running anything. Use its documented Windows PowerShell 5.1 entry points and normal organizational execution policy. Python is used for package and planning checks; it is not required for the observation scripts. No policy bypass, automatic installation, cleanup, reboot or remote management is enabled by this repository review.

The existing [architecture blueprint](Docs/Repository-Blueprint.md), [task guides](Guides/README.md), [baseline](Apps-Programs/workstation-environment.md) and [checklists](Checklists/README.md) remain design/reference material unless a component explicitly establishes implementation. Historical drafts are preserved rather than silently relabeled as current software.

[Portfolio](https://davidtomofficial.com/) · [Migration map](Docs/REPOSITORY-MIGRATION.md) · [Contribution rules](CONTRIBUTING.md)
