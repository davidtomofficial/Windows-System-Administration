# Repository review guide

## A five-minute route through the work

1. Read the root scope and [permission notice](../LICENSE.md).
2. Select [Imaging & Provisioning](../Scripts/Imaging-Provisioning/README.md) or [DeviceCare](../Scripts/DeviceCare/README.md). The [Launchpad](../Launchpad/README.md) remains a separate planning catalog.
3. Run or inspect the [fictional workflow proof packages](PROOF-PACKAGES.md), then compare the selected implementation with its TODO and test source. A named future capability is not evidence of implementation.
4. Check the source/run identity below and the current Actions results. Read failures and limitations, not just a badge.
5. Use [repository review tasks](REPOSITORY-REVIEW-TODO.md) and the [handoff](WORK-AGENT-HANDOFF.md) for remaining work.

## Current source and validation

The active source is the integrated `main` tree. [Scripts](../Scripts/README.md) links to both executable previews and their current task authorities. Start with the [flagship proof verification checkpoint](PROOF-PACKAGES.md#verification-checkpoint) for both example workflows, their expected outputs, exact executed source and runtime records. Later documentation changes do not change which revision that evidence covers.

**Earlier integration record:** Before the November 6 navigation correction, exact main checkpoint `e0ceff7ed5e3b79d1b864ec91f94c2d58d2730cd` passed [integration run 42151225226](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42151225226) on the retained integration branch. Check the [current integration runs](https://github.com/davidtomofficial/Windows-System-Administration/actions/workflows/dto-integration-review.yml) for later revisions and their actual event, source SHA and conclusion.

## Preserved component evidence

The November 6 [selected-observation comparison](WORKSTATION-COMPARISON.md) adds a bounded DTO-WSA-010 / DTO-IMG-004 and DTO-IMG-007 workflow. Its [dated component evidence](../Scripts/Imaging-Provisioning/docs/VALIDATION.md#selected-observation-comparison) is separate from the historical runs below. The original collector modules are preserved; full handoff and same-device verification remain open.

| Scope | Source identity | Recorded evidence |
|---|---|---|
| DeviceCare + Launchpad | tested `deadfd6add0fb391dd3113e6fd9cfd501e8a7603`; documentation follow-up `3ce2a915c20a2d6bb504280b2171cf7a3d5ce9b9` | [Run 42145612233](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42145612233): 65 Windows PowerShell 5.1 checks; 60 PowerShell 7; 12 DeviceCare Python; 12 Launchpad Python; 26 planned entries listed |
| Imaging | source `7ae130b4b33827574da4a9c591885d16ed7d8d68`; receipt follow-up `173cda83ef639f16a7a5acf641f350bca79c7cca` | [Run 42138003752](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42138003752): successful source check; earlier exact scope recorded 87 Windows PowerShell 5.1, 77 PowerShell 7 and eight Python tests |

These tests ran on Windows Server 2022. Native WIM testing used a synthetic text-file image, not an operating-system deployment. Do not combine counts across revisions or claim Windows 11 hardware validation. **Earlier integration checkpoint:** [run 42149193243](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42149193243) passed on commit `bc80d476327bcb072e57c38a4cb97c18220865b9`, including all component suites, 13 repository-contract tests and three CI archives. The 53-member source archive and prework bundle were uploaded to restricted SharePoint and the raw file was read back with matching bytes. This remains a source-review result, not a Windows 11 client or production release.

## Questions a reviewer should be able to answer

What does the component actually do? What can it change? What permissions are required? Which exact code was tested, on which host? Where are the limitations, unresolved defects, privacy model, license and next tasks? Can another authorized maintainer reproduce the package and recover the previous source?

## Known limitations

Full native desktop migration, attended keyboard/Narrator/high-contrast/DPI checks, production installers, actual maintenance, protected recovery and management-policy authority remain incomplete. Historical full-application results are separate and do not become passes for these smaller previews. Existing draft PRs #1, #2, #3, #12 and #16 are not merged by this integration. The historical website scaffolds are not a hosting authorization.

Observation workflows read local evidence without changing device settings; explicitly requested report/proof exports write local output files. Periodic usage check-ins are a new requirement, not a live service. See [status and implementation gates](USAGE-CHECK-IN.md).
