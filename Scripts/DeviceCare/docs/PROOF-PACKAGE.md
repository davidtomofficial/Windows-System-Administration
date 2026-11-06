# DeviceCare developer proof package

**DTO-GH-ORG-006 · Fictional inputs · Read-only development preview**

This package gives a reviewer a reproducible way to inspect DeviceCare's memory
and system-drive findings without collecting information from a computer. It
passes hand-authored fictional snapshots to the existing findings function,
checks the exact result, and exercises the existing offline HTML renderer.

The baseline runtime source is commit
[`ae4117acbd5b013560fcf30ddedec2ce56381151`](https://github.com/davidtomofficial/Windows-System-Administration/tree/ae4117acbd5b013560fcf30ddedec2ce56381151/Scripts/DeviceCare).
This proof package does not modify that runtime. **PowerShell execution of this
new package is pending verification.** Existing component validation is recorded
separately in [VALIDATION.md](VALIDATION.md).

## Reproduce from the repository root

Use a checkout of the repository with Windows PowerShell 5.1 or PowerShell 7,
under the normal script policy for the environment:

```powershell
.\Scripts\DeviceCare\examples\Invoke-SyntheticProof.ps1
```

The script reads its bundled fixtures and expected output. A successful run
emits **one compact JSON string** to the success pipeline and writes no files.
An expectation mismatch or an unexpected error terminates the script. There are
no calls to the snapshot collector, CIM, network services, or maintenance actions.

For an easier-to-read view of the same result:

```powershell
$proof = .\Scripts\DeviceCare\examples\Invoke-SyntheticProof.ps1 | ConvertFrom-Json
$proof | ConvertTo-Json -Depth 8
```

To save fresh local evidence, choose a directory that does not exist:

```powershell
.\Scripts\DeviceCare\examples\Invoke-SyntheticProof.ps1 -OutputDirectory .\DeviceCare-proof
```

Its parent directory must already exist. After all expectations match, the script
creates that directory and writes exactly `summary.json` and `report.html` using
UTF-8 without a byte-order mark. The JSON is the same deterministic summary as
stdout, followed by a newline. The HTML renders the **review** fixture: 90 percent
memory use and 6 GiB free. Other fixture reports are checked in memory. Reports
are not opened or transmitted automatically.

An existing output directory or file is refused with `DTO.ProofOutputExists`.
Each file is also opened with `CreateNew`, preventing replacement if another
writer wins a race. A write failure terminates the run; a partially created
directory may remain for inspection. Rerunning against it refuses rather than
overwriting it. A missing parent yields `DTO.ProofOutputParentMissing`.

In a standalone component source ZIP, run
`.\examples\Invoke-SyntheticProof.ps1` from the extracted component root.

## Exact expected result

[expected-summary.json](../examples/expected-summary.json) contains the complete,
independently authored expected object. The script compares its normalized
summary with that file, including field names, order, values and case order.
The expected file is not generated from the implementation's output. Whitespace
in the checked-in JSON is normalized before comparison.

| Fictional case | Effective thresholds: disk minimum / memory review | Memory result | System-drive result |
|---|---|---|---|
| `observed` | 15 GiB / 85 percent | Observed, 40 percent | Observed, 40 GiB |
| `review` | 15 GiB / 85 percent | Review, 90 percent | Review, 6 GiB |
| `unknown` | 15 GiB / 85 percent | Unknown, null | Unknown, null |
| `threshold-equality` | 15 GiB / 85 percent | Review, 85 percent | Observed, 15 GiB |
| `rounding-edge` | 15 GiB / 85 percent | Observed, displayed 85 percent | Review, displayed 15 GiB |
| `configured-thresholds` | 50 GiB / 40 percent | Review, 40 percent | Review, 40 GiB |

Every result retains `DeviceReady: null` and `MaintenanceAuthorized: false`.
`FictionalData` and `InputsUnchanged` are true. Display values and thresholds are
invariant-culture strings in the normalized summary; unknown values are JSON
null. This avoids incidental numeric formatting differences between PowerShell
versions. No current time, runtime version, local path, or device identifier is
part of the summary.

Successful output includes these exact verified refusal IDs:

```json
["wrong-product","numeric-changes-flag","invalid-threshold","duplicate-finding","unsupported-state"]
```

It also includes these exact verified report checks:

```json
["original-time","offline-policy","html-encoding","unknown-value-suppressed","extra-properties-omitted"]
```

The five refusal cases must raise the expected validation error. An arbitrary
exception does not satisfy the refusal assertion. The report checks verify the
original fictional timestamp, the offline content policy, text encoding,
suppression of a misleading number on an Unknown finding, and omission of an
unselected fictional marker. These are source/data checks, not a visual or
assistive-technology review.

## Why these cases matter

The unavailable OS record in `unknown` makes memory Unknown. Its disk record has
free space greater than total size, so the numeric evidence is invalid and also
becomes Unknown. Missing or invalid evidence cannot count as passing.

Equality has deliberately different meanings for the two rules: memory at the
review threshold requires review, while disk space at its minimum is observed.
The rounding case uses 84.96 percent memory and one byte less than 15 GiB of disk
space. They display as 85 and 15 respectively, while their states follow the
unrounded values. The configured case reuses the ordinary measurements with
explicit thresholds, demonstrating a changed policy decision without implying a
change to the fictional computer.

The input and expected files are separate so a reviewer can evaluate the intended
outcome before running the code. The proof keeps its output small and projects
only the two findings and effective thresholds. The original fixed observation
time, `2026-01-01T12:00:00.0000000Z`, is preserved in each assessment and report;
it is a fictional observation time, not the date on which verification ran.

## Source and language mapping

| File | Role and demonstrated language |
|---|---|
| [DeviceCare.psm1](../src/DeviceCare.psm1) | PowerShell implementation of `Get-DTODeviceCareFindings`: validates the snapshot boundary and derives the two findings. The collector in the same module is not invoked by this proof. |
| [Presentation.ps1](../src/Presentation.ps1) | PowerShell implementation of `ConvertTo-DTODeviceCareHtml`: validates finding identity/state, projects evidence and encodes text. |
| [Invoke-SyntheticProof.ps1](../examples/Invoke-SyntheticProof.ps1) | PowerShell demonstration, independent expectations, refusal checks and optional new-file export. Designed for Windows PowerShell 5.1 and PowerShell 7; actual run status is tracked below. |
| [synthetic-snapshots.json](../examples/synthetic-snapshots.json) | Hand-authored fictional input data; memory sizes use KiB and disk sizes use bytes. |
| [expected-summary.json](../examples/expected-summary.json) | Hand-authored expected output, independent of a captured application run. |
| [report.html](../brand/report.html) and [original DT vector](../brand/dto-header-monogram.svg) | Existing HTML/CSS report template and embedded local SVG artwork. |
| [package.py](../tools/package.py) | Python source-package tooling. Python is not required to run this PowerShell demonstration. |

## Contribution, rights and limits

David Tom directs this personal DTO project. This proof package, fixtures and
review notes were prepared with AI assistance in response to his request to
advance the existing task. The design choices above describe this proof package;
historical individual coding contributions are not established by these tests.
All inputs and demonstrated outcomes here are fictional.

The [component permission and license notice](../LICENSE.md) and
[asset provenance](../brand/ASSET-PROVENANCE.md) remain applicable. The package
does not change ownership, license grants, or attribution.

This demonstrates a bounded developer workflow for an existing read-only preview.
It does not establish real-device collection, full OS compatibility, cleanup,
repair, update behavior, a native desktop experience, visual/accessibility
acceptance, installation/recovery, usage check-ins, or device health. `Observed`
means the selected evidence was available and did not meet the selected review
rule; it is not certification. The wider release/case-study gate DTO-DC-015,
attended Windows 11 acceptance, and repository A+ acceptance remain open.

## Verification status

| Verification | Status for this new package |
|---|---|
| Source review and independently specified expected outcomes | Prepared against the baseline revision above. |
| JSON fixture and expected-output validity; Python component packaging | Passed local checks on November 6, 2026: both JSON files parsed, six fixture identities and the independently calculated rounding/equality inputs checked, and all 12 existing component packaging tests passed. PowerShell was not executed locally. |
| Windows PowerShell 5.1 demonstration and output-path refusal | Pending Windows CI. |
| PowerShell 7 demonstration and output-path refusal | Pending Windows CI. |
| Cross-runtime normalized JSON parity | Pending both runtime results. |
| Rendered HTML, assistive technology and attended Windows 11 | Not performed by this proof package. |

Record the exact source revision, run link, environment and actual outcome before
changing a pending entry. A prepared fixture, expected file or green unrelated
suite is not evidence that this new script executed.
