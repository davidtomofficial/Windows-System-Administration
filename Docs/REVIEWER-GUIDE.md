# Repository review guide

## A five-minute route through the work

1. Read the root scope and [permission notice](../LICENSE.md).
2. Select [DeviceCare](../Scripts/DeviceCare/README.md), [Imaging](../Scripts/Imaging-Provisioning/README.md), or [Launchpad](../Launchpad/README.md).
3. Compare the selected implementation with its TODO and test source; do not treat a named future capability as implemented.
4. Check the source/run identity below and the new integration run. Read failures and limitations, not just a badge.
5. Use [repository review tasks](REPOSITORY-REVIEW-TODO.md) and the [handoff](WORK-AGENT-HANDOFF.md) for remaining work.

## Preserved component evidence

| Scope | Source identity | Recorded evidence |
|---|---|---|
| DeviceCare + Launchpad | tested `deadfd6add0fb391dd3113e6fd9cfd501e8a7603`; documentation follow-up `3ce2a915c20a2d6bb504280b2171cf7a3d5ce9b9` | [Run 42145612233](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42145612233): 65 Windows PowerShell 5.1 checks; 60 PowerShell 7; 12 DeviceCare Python; 12 Launchpad Python; 26 planned entries listed |
| Imaging | source `7ae130b4b33827574da4a9c591885d16ed7d8d68`; receipt follow-up `173cda83ef639f16a7a5acf641f350bca79c7cca` | [Run 42138003752](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42138003752): successful source check; earlier exact scope recorded 87 Windows PowerShell 5.1, 77 PowerShell 7 and eight Python tests |

These tests ran on Windows Server 2022. Native WIM testing used a synthetic text-file image, not an operating-system deployment. Do not combine counts across revisions or claim Windows 11 hardware validation. The integration pipeline reruns both components separately and produces a source-only review archive; its actual result must be inspected before accepting the integration.

## Questions a reviewer should be able to answer

What does the component actually do? What can it change? What permissions are required? Which exact code was tested, on which host? Where are the limitations, unresolved defects, privacy model, license and next tasks? Can another authorized maintainer reproduce the package and recover the previous source?

## Known limitations

Full native desktop migration, attended keyboard/Narrator/high-contrast/DPI checks, production installers, actual maintenance, protected recovery and management-policy authority remain incomplete. Historical full-application results are separate and do not become passes for these smaller previews. Existing draft PRs #1, #2, #3, #12 and #16 are not merged by this integration. The historical website scaffolds are not a hosting authorization.

Current code remains local/read-only. Periodic usage check-ins are a new requirement, not a live service. See [status and implementation gates](USAGE-CHECK-IN.md).
