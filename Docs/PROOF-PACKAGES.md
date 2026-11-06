# Reproduce the two flagship workflows

**DTO-GH-ORG-006 · Developer evidence · November 6, 2026**

These small proof packages let an authorized reviewer inspect a complete, implemented workflow without collecting information from their computer. Every input is fictional. Each script calls the existing public component functions, checks an independently authored expected result, and optionally exports a local HTML report and JSON summary to a new directory.

| Project | Problem demonstrated | Start here |
|---|---|---|
| Imaging & Provisioning | Compare two selected workstation observations while keeping incomplete evidence visible | [Imaging proof package](../Scripts/Imaging-Provisioning/docs/PROOF-PACKAGE.md) |
| DeviceCare | Turn selected disk and memory observations into bounded findings without claiming overall device health | [DeviceCare proof package](../Scripts/DeviceCare/docs/PROOF-PACKAGE.md) |

Read the [rights and permission notice](../LICENSE.md). Public inspection does not grant general software-use permission. Existing license grants and third-party attribution remain intact.

## Run from the repository root

Use an authorized Windows development environment and its normal script policy. Python is needed only for packaging and the optional cross-runtime comparison, not for either demonstration.

```powershell
# Console JSON only; no device collection or report export.
& .\Scripts\Imaging-Provisioning\examples\Invoke-SyntheticProof.ps1
& .\Scripts\DeviceCare\examples\Invoke-SyntheticProof.ps1

# Explicit local exports. Each destination must be new.
& .\Scripts\Imaging-Provisioning\examples\Invoke-SyntheticProof.ps1 -OutputDirectory .\proof-imaging
& .\Scripts\DeviceCare\examples\Invoke-SyntheticProof.ps1 -OutputDirectory .\proof-devicecare
```

Each destination contains `summary.json` and `report.html`. Open the HTML manually in a browser if you want to inspect it; no browser opens automatically. Reusing an existing destination is refused, preserving its files. The component guides explain the exact expected outcomes, meaningful edge cases, source functions and limitations.

The demos do not call a workstation collector, query services or profiles, inspect a WIM, change device settings, or contact a service. Their only requested writes are the new local report files. They exercise selected interpretation and presentation paths; other implemented collector workflows retain their separate evidence.

## What the evidence establishes

The scripts compare actual component results against checked-in expected JSON and throw on a mismatch. They also exercise meaningful refusal and unknown-evidence behavior. The repository runner verifies the console command, fresh export, saved-result readback and refusal to overwrite prior output. Separate executions use Windows PowerShell 5.1 and PowerShell 7; a Python step compares their normalized results.

The [integration workflow](../.github/workflows/dto-integration-review.yml) retains a `dto-portfolio-proofs-<source SHA>` artifact containing both runtimes' fictional output and `environment.json` records. Those records identify the exact checked-out source, runtime and host operating system. Its source archive separately preserves the allowlisted scripts, fixtures, expected outputs and guides. Download retention is finite; the dated verification record below identifies the retained checkpoint.

The repository evidence runner requires the requested source SHA to match Git HEAD and refuses tracked local changes before creating output. Generated, untracked proof directories can remain outside the source record. The component commands above also work from an extracted component ZIP; use its verified package manifest and the dated source receipt when identifying that source.

| Evidence level | Meaning |
|---|---|
| Static review | The source, fixture provenance, links, public suitability and stated limits were inspected. |
| Synthetic execution | The existing functions produced the expected results for authored inputs on the recorded runtime. |
| Native automated checks | Existing component suites separately exercise their declared read-only/native behavior on the CI host. |
| Attended acceptance | Operator workflows, rendered accessibility, Windows 11 hardware, installation and recovery require their own observed results. These proof packages do not supply that acceptance. |

### Verification checkpoint

**Executed and verified November 6, 2026:** [PR 24](https://github.com/davidtomofficial/Windows-System-Administration/pull/24), head `4063b99e9a7c2d8945d646ff8bc4b263bcabffa7`, passed [Windows run 42290078369](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42290078369). That PR run checked out synthetic merge `64c596c3738d9c609a10faa40be7e490b4973120` on Windows Server 2022, with Windows PowerShell **5.1.20348.5773** and PowerShell **7.6.9**. These identities name the executed proof source, not any later documentation revision.

Both components passed their independently authored expected results in both runtimes. The console command, fresh export, saved-result readback, exact existing-directory refusal and unchanged saved-file hashes all passed. The two runtimes' normalized JSON matched, and their environment records identified the same exact source. The existing integration suites also passed, including 12 DeviceCare and eight Imaging Python packaging tests and 13 repository checks. Suite counts overlap and are not a combined product-acceptance total.

The ten-file fictional output artifact `13539006936` was downloaded and verified against SHA-256 `26b055f153dd937eb29a197f3729c74dc69ebe9dbfaf0b5b95ab1217ef1d8abd`. All four saved component summaries independently matched the authored expectations. The 79-file source archive was separately downloaded, manifest-verified and restored with exact equality to the reviewed source. HTML encoding/evidence checks passed; rendered or attended accessibility was not evaluated.

The first run, `42289705342`, stopped because the new DeviceCare proof referenced an exception type that Windows PowerShell 5.1 could not resolve. The assertion now checks the exact error ID and reflected type name; the successful rerun retains the specific refusal requirement. No component application fix or weakened expectation was needed. The initial source baseline remains `ae4117acbd5b013560fcf30ddedec2ce56381151`, with its earlier comparison, profile-inventory and shared-result work preserved.

## Language, contribution and design decisions

PowerShell implements the selected Windows component APIs and both demonstrations. JSON holds fictional inputs and independent expected output. The existing HTML/CSS renderers present the evidence. Python builds and checks source packages and compares saved proof results; this does not establish Python as a device-management runtime. Follow the source links in each component guide instead of using language badges as proof.

David Tom owns the personal project direction and selected the Imaging/DeviceCare priorities, scope and evidence requirements. This proof-package increment was drafted and reviewed with AI assistance under that direction, including scripts, fixtures and documentation. The recorded execution is automated CI. It does not establish that David manually authored every line or performed attended acceptance, and it makes no claim about employer systems, ticket counts or workplace outcomes.

The main design choices are explicit uncertainty, a small declared field scope, independently authored expectations, opt-in report export, and source-linked evidence. They make the demonstration easy to inspect while leaving collection, operational safety and wider product acceptance as separate questions.

## Status and next work

This completes the two-flagship basic-workflow proof increment of [DTO-GH-ORG-006](REPOSITORY-REVIEW-TODO.md). Broader portfolio acceptance stays open. The [Imaging TODO](../Scripts/Imaging-Provisioning/TODO.md) and [DeviceCare TODO](../Scripts/DeviceCare/TODO.md) retain implementation authority. Full workstation handoff, native desktop migration, actual maintenance, installers/recovery, live check-ins and attended Windows 11/accessibility checks remain separately tracked. No A+ grade or operational release is awarded by these proofs.
