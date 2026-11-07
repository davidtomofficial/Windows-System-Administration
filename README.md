<a href="https://davidtomofficial.com/"><img align="right" src="Scripts/DeviceCare/brand/dto-header-monogram.svg" width="72" height="72" alt="David Tom Official DT monogram" /></a>

# Windows System Administration

**David Tom Official · Systems, Automation & Software**

[Portfolio](https://davidtomofficial.com/) · [GitHub profile](https://github.com/davidtomofficial) · [Current validation runs](https://github.com/davidtomofficial/Windows-System-Administration/actions/workflows/dto-integration-review.yml)

PowerShell development previews for reviewing Windows workstation evidence and producing offline reports. **Imaging & Provisioning** helps examine selected observations and local WIM metadata; **DeviceCare** turns basic device observations into readable findings.

> **Permission required:** review the [rights and permission notice](LICENSE.md) before running, deploying, modifying or redistributing covered original work. Existing licenses, third-party rights and lawful exceptions remain intact. [Request permission](https://davidtomofficial.com/#contact).

## Review the repository

| Your goal | Start here |
| --- | --- |
| Understand the scope and evidence | [Five-minute review guide](Docs/REVIEWER-GUIDE.md) |
| Inspect a complete example | [Imaging and DeviceCare example workflows](Docs/PROOF-PACKAGES.md), using fictional inputs |
| Explore Imaging & Provisioning | [Source and usage](Scripts/Imaging-Provisioning/README.md) · [Case study](https://davidtomofficial.com/windows-imaging-provisioning/#personal-development) · [Remaining work](Scripts/Imaging-Provisioning/TODO.md) |
| Explore DeviceCare | [Source and usage](Scripts/DeviceCare/README.md) · [Case study](https://davidtomofficial.com/devicecare/) · [Remaining work](Scripts/DeviceCare/TODO.md) |

## Implemented versus planned

Both components are **0.2.0 development previews**. Their current scope is local inspection and reporting.

| Project | Implemented today | Remaining product work |
| --- | --- | --- |
| Imaging & Provisioning | Selected workstation, service and profile observations; before/after comparison; local WIM metadata/index review and optional SHA-256 hash; offline HTML report | Same-device verification, full handoff, bootable images, OS deployment and installer/recovery qualification |
| DeviceCare | Local OS, memory and system-drive observations; memory and free-space threshold findings; offline DTO HTML report | Full desktop application, maintenance/repair and installed-device acceptance |

Incomplete evidence remains explicit. Profile age is a review signal; session coverage and removal eligibility are not established. Threshold findings do not certify overall device health.

The [example-workflow record](Docs/PROOF-PACKAGES.md#verification-checkpoint) identifies the tested source, runtimes and results. Automated tests on Windows Server 2022 are separate from attended Windows 11 acceptance. The [quality contract](Docs/REPOSITORY-A-PLUS.md) keeps unverified criteria open; no A+ grade has been awarded.

## For authorized developers

Read the selected component README for its Windows PowerShell 5.1 entry points, prerequisites and output behavior. Use normal organizational execution policy. Python supports package and planning checks; the observation scripts do not require it.

Observation workflows read local evidence. Explicit report/proof exports create local output files. Deployment, repairs, profile removal, automatic installation, reboot and remote management are outside the implemented preview scope.

[Contribution rules](CONTRIBUTING.md) · [License scope](Docs/LICENSING.md) · [Source migration map](Docs/REPOSITORY-MIGRATION.md)

<details>
<summary><strong>Planning and maintainer references</strong></summary>

The [Technician Launchpad](Launchpad/README.md) contains an offline planning catalog, shared result contract and tests. Its [26 candidates](Launchpad/catalog.plan.json) remain non-executable; component adapters, GUI, BAT wrappers and task dispatch remain planned.

[Periodic usage check-ins](Docs/USAGE-CHECK-IN.md) are a future licensed-build requirement. No collector endpoint, client integration, live usage count or enforcement is established.

- [Windows administration master](Docs/DTO-WINDOWS-ADMIN-TODO.md)
- [Repository review TODO](Docs/REPOSITORY-REVIEW-TODO.md)
- [Bounded continuation prompt](Docs/WORK-AGENT-HANDOFF.md)
- [Architecture blueprint](Docs/Repository-Blueprint.md)
- [Task guides](Guides/README.md), [workstation baseline](Apps-Programs/workstation-environment.md) and [checklists](Checklists/README.md)

These planning/reference materials retain their original context. A component's current README and evidence determine what is implemented.

</details>
