# Imaging developer proof package

**DTO-GH-ORG-006 - fictional before/after evidence, with an executable expected result.** This package demonstrates the existing DTO-WSA-010 comparison and HTML renderer. It is a development proof for repository reviewers. Full workstation handoff, operational release and attended acceptance retain their existing gates.

## User and problem

A reviewer needs to see how the comparison handles a changed OS value, unchanged hardware observations and unavailable evidence without collecting information from their own workstation. This example supplies two hand-authored schema 2 observations and an independently authored expected summary. One command runs the comparison, checks its result and demonstrates two specific input refusals.

The fictional after observation changes the OS version, makes BIOS evidence unavailable and reverses the order of the same two CPU names. The expected classification is **1 changed, 5 unchanged, 1 unknown**. Unavailable BIOS evidence remains unknown. CPU ordering does not create a change.

## Run from the repository root

Use an authorized PowerShell 5.1 or PowerShell 7 host under its normal execution policy. Review the [rights and permission notice](../LICENSE.md) before running covered software outside an existing authorization.

```powershell
.\Scripts\Imaging-Provisioning\examples\Invoke-SyntheticProof.ps1
```

The default reads the included fixtures and modules, performs the assertions in memory, and emits exactly one compact JSON string on the success stream. It writes no files. It calls neither a workstation/service/profile collector nor CIM, DISM or a WIM operation. The report exists as an in-memory string unless an output directory is explicitly requested. An assertion mismatch throws instead of reporting a successful proof.

To retain the checked summary and offline report, choose a directory that does not already exist:

```powershell
.\Scripts\Imaging-Provisioning\examples\Invoke-SyntheticProof.ps1 -OutputDirectory .\dist\proofs\Imaging-Demo
```

This writes `summary.json` and `report.html` to the selected directory, then emits the same summary JSON. Existing directories and files are refused; report files use exclusive creation and are never overwritten. The expected result must match before the directory is created. Repeating the command with the same directory fails with `DTO.ProofOutputExists`. Choose a fresh destination for another run. Generated reports are development artifacts and are not additional source fixtures.

## Exact expected output

The following is the single success-stream JSON string. The independently authored, readable expectation is [examples/expected/workstation-summary.json](../examples/expected/workstation-summary.json). It is not regenerated from actual comparison output.

```json
{"ProofId":"DTO-GH-ORG-006-Imaging","DataOrigin":"HandAuthoredSynthetic","ComparedFieldCount":7,"ChangedCount":1,"UnchangedCount":5,"UnknownCount":1,"ChangedFields":["Win32_OperatingSystem.Version"],"UnchangedFields":["Win32_OperatingSystem.Caption","Win32_OperatingSystem.OSArchitecture","Win32_ComputerSystem.Manufacturer","Win32_ComputerSystem.Model","Win32_Processor.Name"],"UnknownFields":["Win32_BIOS.SMBIOSBIOSVersion"],"VersionBefore":"Fixture version A","VersionAfter":"Fixture version B","CpuNamesBefore":["Fixture CPU A","Fixture CPU B"],"CpuNamesAfter":["Fixture CPU A","Fixture CPU B"],"BiosAfterCoverage":{"Status":"Unavailable","Complete":false,"Reason":"IncompleteSource"},"Chronology":"Forward","ComparisonComplete":false,"SameDeviceVerified":false,"DeploymentAccepted":false,"ChangesAllowed":false,"MalformedEnvelopeRefusal":"DTO.InvalidWorkstationSnapshot","ReversedOrderRefusal":"DTO.InvalidObservationOrder","ObservationTimesPreserved":true,"InputsUnchanged":true,"HtmlEvidencePreserved":true}
```

The script compares its normalized summary with that expected JSON. Assertions cover all seven classifications, exact before/after version values, sorted CPU name lists, unavailable BIOS coverage, chronology, the false identity/deployment/change flags, retained observation timestamps, unchanged input objects, and HTML evidence preservation.

Two additional calls test meaningful refusals. A copy of the after fixture with the string `"2"` in `SchemaVersion` must throw `DTO.InvalidWorkstationSnapshot`; it cannot pass as a valid numeric schema. Swapping the original observations must throw `DTO.InvalidObservationOrder`. The script requires these exact codes, so an unrelated exception cannot satisfy the assertion.

The OS caption includes a fictional `<script>` marker solely to exercise HTML encoding. The report must contain no executable `<script>` element. Decoding its evidence text must recover the full original report JSON. This verifies evidence encoding and preservation; no visual or attended accessibility acceptance is claimed.

## Source and language map

Paths in this table are relative to `Scripts/Imaging-Provisioning`.

| Source | Language/data | Role in the proof |
|---|---|---|
| [examples/Invoke-SyntheticProof.ps1](../examples/Invoke-SyntheticProof.ps1) | PowerShell 5.1-compatible script | Reads only the selected fixtures, invokes the existing comparison/renderer, asserts expected evidence, and optionally creates fresh output files. |
| [examples/fixtures/workstation-before.json](../examples/fixtures/workstation-before.json) and [workstation-after.json](../examples/fixtures/workstation-after.json) | JSON | Hand-authored fictional schema 2 observations; no endpoint export or customer data. |
| [examples/expected/workstation-summary.json](../examples/expected/workstation-summary.json) | JSON | Independently authored expected output for the described scenario; retained separately from generated artifacts. |
| [src/DTOSnapshotComparison.psm1](../src/DTOSnapshotComparison.psm1) | PowerShell | Existing `Compare-DTOWorkstationSnapshot` implementation; unchanged by this proof package. |
| [src/DTOImaging.psm1](../src/DTOImaging.psm1) | PowerShell producing HTML/CSS | Existing `ConvertTo-DTOReviewHtml`; imported without invoking its collectors. |
| [tools/package.py](../tools/package.py) and [tests/test_package.py](../tests/test_package.py) | Python | Allowlist packaging and integrity checks. Python is not needed to run the PowerShell proof. |

## Design decisions and boundaries

The proof reuses the public comparison API. It does not duplicate the production comparison logic or replace the existing 73-check comparison regression suite. Its expected values were written from the fictional scenario rather than captured from the implementation. A changed result, missing field or unexpected refusal must be investigated before changing the expectation.

The summary uses a fixed property order, array shapes, ASCII labels and no runtime metadata or current time. Its normalized JSON is the cross-runtime comparison target. `summary.json` uses UTF-8 without a byte-order mark and a final LF. The full HTML retains the original UTC observation timestamps and per-side coverage; JSON escaping or presentation whitespace may differ across PowerShell versions without changing the summary.

Known field projection, conservative unknown states and CPU multiset comparison come from the existing module. `SameDeviceVerified`, `DeploymentAccepted` and `ChangesAllowed` remain false. The fixture pair is an authored scenario, not authenticated evidence of an action performed on a device. Services, applications, policies, peripherals, user workflows and protected recovery are outside this example. Required/optional policies, device-pairing evidence and human signoff remain open under DTO-WSA-010. The dashboard/profile migration and attended Windows 11 work retain their existing TODO entries.

## Provenance and execution evidence

Prepared against immutable repository baseline **`ae4117acbd5b013560fcf30ddedec2ce56381151`**. The comparison module, original renderer and existing tests are preserved. This baseline identifies the reviewed starting source; it is not an execution receipt for the new proof.

| Verification | Status for this new proof package |
|---|---|
| Windows PowerShell 5.1 proof execution | Pending exact source/run evidence. |
| PowerShell 7 proof execution | Pending exact source/run evidence. |
| Cross-runtime normalized summary parity | Pending execution of both runtimes. |
| Fresh output-directory and overwrite refusal checks | Implemented; execution evidence pending. |
| Python component packaging checks | 8 existing tests passed locally on November 6, 2026; this is not a PowerShell execution result. |
| HTML visual / attended Windows 11 acceptance | Not performed by this package. |

Existing component execution evidence remains in [VALIDATION.md](VALIDATION.md) and applies to its stated sources and scope. The presence of this script, its expected JSON or a generated-looking report is not by itself a successful execution result. Record the exact tested commit, run, runtime and outcome before marking the new proof executed.

This is David Tom's personal DTO portfolio project. The proof package is an owner-directed, AI-assisted implementation. Its source, fictional fixtures and assertions provide inspectable evidence of the work. It supplies no employer/customer deployment claim or measured workplace outcome. The [rights notice](../LICENSE.md) and [repository contribution rules](https://github.com/davidtomofficial/Windows-System-Administration/blob/main/CONTRIBUTING.md) continue to apply.

[Component usage](../README.md) | [Component TODO](../TODO.md) | [Existing validation evidence](VALIDATION.md)
