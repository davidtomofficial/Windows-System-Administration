# Workstation snapshot comparison

**DTO-WSA-010: read-only comparison increment for the Imaging development preview.**

Use this increment to review the difference between two selected workstation observations. It reports Changed, Unchanged or Unknown for each supported field, together with the snapshots' timestamps and collection coverage. It does not decide whether a workstation is healthy or ready to deploy.

## Supported observations

| Source | Compared fields |
| --- | --- |
| Win32_OperatingSystem | Caption, Version, OSArchitecture |
| Win32_ComputerSystem | Manufacturer, Model |
| Win32_BIOS | SMBIOSBIOSVersion |
| Win32_Processor | Name, as an order-independent multiset |

Processor multiplicity is retained: two equal processor names are different from one occurrence. No per-socket identity is inferred from the names. Service, application, driver, disk, peripheral and user-workflow comparisons are outside this increment.

## Usage

Run from the Imaging component directory in an authorized Windows session:

```powershell
Import-Module .\src\DTOImaging.psm1 -Force
Import-Module .\src\DTOSnapshotComparison.psm1 -Force

$before = Get-DTOWorkstationSnapshot
# Retain this object while the separately authorized work is performed.
# The comparison module does not perform that work.
$after = Get-DTOWorkstationSnapshot
$comparison = Compare-DTOWorkstationSnapshot -Before $before -After $after
$comparison.Fields | Format-Table Source, Field, Status, Before, After -Wrap

# Existing DTO HTML renderer returns a string for local review.
$html = ConvertTo-DTOReviewHtml -Review $comparison
```

The function consumes existing schema-2 snapshot objects in memory. It does not collect fresh observations, read snapshot files, save reports, launch a browser, upload data or contact a service. Existing execution-policy and Windows observation requirements still apply to the collector. The pure comparison can be checked with synthetic objects on PowerShell 5.1 or 7 without calling Windows providers.

Select the intended before and after observations yourself. Timestamps must be UTC, and the after observation must not precede the before observation; equal instants are allowed. UTC ISO strings and UTC DateTime/DateTimeOffset values are supported. Timestamps are supplied evidence, not authenticated clocks. Equal OS/hardware values do not establish that both observations came from the same machine. Computer names, serial numbers and unexpected input fields are omitted from the comparison output; the retained OS/hardware text can still be sensitive.

## Interpreting the result

Changed means that two sufficiently covered observations differ. Unchanged means that the compared observations match within the supported fields and coverage. Unknown means that the evidence is missing, partial, unavailable or otherwise insufficient for that comparison. Unknown must not be treated as absence, a pass or a failed repair.

The result includes `BeforeCollectedAtUtc`, `AfterCollectedAtUtc`, `Coverage`, a seven-field `Fields` array and summary counts. `Coverage.Sources` retains each of the four sources' before/after status, reason and completeness, so Partial and Unavailable remain distinguishable. The overall `Status` is Unknown whenever any field or either snapshot's overall collection is incomplete, even if some covered fields changed. Inspect individual rows for those known differences. `IdentityEstablished` and `DeploymentAccepted` remain false.

The input must retain the collector's four known source sections and schema-2 metadata. Missing observations inside a valid NoData, Unavailable or Partial section remain Unknown. An omitted source section, ambiguous duplicate source or invalid control field is a malformed envelope and is refused rather than coerced. The comparison does not authenticate saved reports or deserialize arbitrary files. Saved-file import, verified machine identity and a native comparison screen remain future work.

## Reproduce the checks

```powershell
.\tests\Run-ComparisonChecks.ps1
.\tests\Run-Checks.ps1
```

The component harness also runs the comparison checks. Its existing native mode tests Windows observations and a disposable synthetic text-file WIM; it does not install an operating system. Run records and limitations are documented in [validation](VALIDATION.md). A test pass belongs to its exact source revision and environment.

## Design and remaining acceptance

The new sibling module preserves the existing observation and WIM-inspection runtime. It projects a fixed set of fields and does not reuse computer names as an implicit identity key. Keeping incomplete evidence visible avoids labeling an incomplete capture as an unchanged workstation. Processor multiset comparison removes a provider-order dependency while retaining the number of observed entries.

This increment was developed with AI assistance within David Tom's existing Imaging and handoff requirements. Its source, independent review, synthetic cases and environment-specific validation remain inspectable; those records do not substitute for operator acceptance.

This increment supports the existing [DTO-WSA-010 handoff work](../../../Docs/DTO-WINDOWS-ADMIN-TODO.md#dto-wsa-010-workstation-comparison-continuation). Required/optional criteria, device/peripheral/user-workflow validation, human signoff, full native UI and attended Windows 11 acceptance remain open. The original Imaging dashboard/profile migration and deployment/recovery tasks keep their separate acceptance criteria. This is a development preview, not an operational release.
