# DTO 0.2.0 validation scope

## DTO-WSA-015 profile inventory continuation

The additive profile inventory module has its own `tests/Run-ProfileChecks.ps1` suite. It exercises field projection, identifiers omitted by default, explicit identifier inclusion, strict Boolean evidence, missing/invalid/future/timezone-unknown dates, elapsed-time thresholds, current-process and special/loaded/roaming observations, uncertain status bits, duplicate identities, record/UTF-8 byte limits and partial provider failures. Every row remains unselected and ineligible for removal.

Native mode reads actual local `Win32_UserProfile` metadata through the standalone entry point on the authorized test host without printing identifiers or changing profiles. The existing workstation/service/WIM runtime source is byte-identical to the prework checkpoint.

[Windows integration run 42285198826](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42285198826), job 128124099112, passed initial implementation head `b43c506ec29716f3c1719525924b5ad6ef5534b9`, checked out as synthetic merge `fa9b33bbf84813aa2f228959bb2d32acee4a40e7` against base `c265ae028f790678479ff4de035711a75625dba7`. Host: Windows Server 2022, runner image 20261101.353.1.

| Suite | Observed result |
|---|---|
| Profile inventory, Windows PowerShell 5.1.20348.5773 | 183 checks passed, including native mode and entry-point forwarding |
| Profile inventory, PowerShell 7.6.9 | 152 contract checks passed; native mode false |
| Existing Imaging checks | 90 Windows PowerShell 5.1/native and 80 PowerShell 7 checks passed; counts include parsing the three new PowerShell files |
| DeviceCare checks | 98 Windows PowerShell 5.1/native and 93 PowerShell 7 checks passed |
| Python suites | 8 Imaging packaging, 12 DeviceCare packaging, 12 Launchpad planning and 13 repository contract tests passed separately |

These are separate, overlapping suite counts, not unique acceptance cases. The 57-file source archive was retrieved from the Windows artifact and rebuilt byte-for-byte on Linux: 113396 bytes, SHA-256 `2fba31026d7c0688d8186968ffaff0c51cda9da14b44270034a40ac13f4c455e`. Later commits require their own current run/readback; this record identifies the initial implementation exactly.

This is the inventory stage of DTO-WSA-015. Session coverage is explicitly NotCollected. Protected/shared-account policy, ownership review and attended Windows 11 remain open. See [profile inventory behavior and limitations](PROFILE-INVENTORY.md).

## Existing workstation, service and image checks

The current scripts have dedicated dependency-free PowerShell checks for parsing, default privacy, opt-in identifiers, malformed/empty/partial evidence, row/byte limits, safe HTML, image path restrictions, image metadata and hash behavior. A Windows-only native test creates a tiny synthetic-data WIM on a disposable runner, inspects index 1, and checks that its hash did not change. This is not an operating-system image test.

Fresh execution results are recorded in a separate dated checkpoint receipt; tests existing in source alone do not establish a pass. A green CI run applies only to its exact commit. A later documentation-only checkpoint must record which source hashes remain identical to that tested commit.

The current source package uses the explicit file allowlist in `tools/package.py` plus MANIFEST.json. Python tests cover reproducibility, content tampering, identity/promotion refusal, extra archive members, excluded local reports, missing sources and DTO branding consistency. Verification is content checking, not publisher trust or deployment acceptance.

Still open: actual Windows 11 workstation runs, real licensed OS WIM coverage, administrative privilege/error-path behavior across supported systems, PowerShell 7 DISM compatibility on workstations, target-image compatibility, installer/image/recovery execution, full WPF migration and attended accessibility. Provider timeout is not a process deadline. DISM may write diagnostic logs. These limits remain visible even after automated passes.

## Executed results - November 5 local / November 6 UTC

GitHub Actions run [42137376120](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42137376120), job 127628836912, completed successfully on exact commit `e71a47e356d1a070d57aa64e8978a0077f3dd323`. Runner: Windows Server 2022, build 20348, image 20261101.353.1.

| Check | Result |
|---|---|
| Windows PowerShell 5.1.20348.5773 | 87 checks passed, including native mode |
| PowerShell 7.6.9 | 77 contract checks passed; native mode false |
| Python packaging | 8 tests passed on Windows; also 8 locally |

The first two attempts were retained as failures: the HTML literal assertion did not account for PowerShell 5.1 JSON escaping, then a test result variable collided case-insensitively with the Native switch. Both fixes were in the test harness; the product module was unchanged. The successful attempt checked real local CIM/service results and a disposable synthetic text-file WIM, including matching SHA-256 before/after inspection. No OS was installed, mounted or applied.

This documentation/TODO reconciliation does not change the tested scripts, product metadata, tests or packaging tool. Independently compare their blob hashes with the tested commit before relying on the result. Current source/archive and tracker readbacks are recorded outside the source package in the dated checkpoint verification receipt. PowerShell 7's result does not establish native DISM interoperability.

## Selected observation comparison

**November 6, 2026; DTO-WSA-010 / DTO-IMG-004 and DTO-IMG-007.** The new `src/DTOSnapshotComparison.psm1` is a separate pure comparison module. The original three Imaging runtime files remain byte-identical to the preserved source. `tests/Run-ComparisonChecks.ps1` is invoked by the existing component test entry point in both Windows PowerShell 5.1 and PowerShell 7 jobs. It also runs independently.

The comparison accepts trusted local schema 2 workstation observations. It projects seven known fields, retains the two original UTC observation times and returns Changed/Unchanged/Unknown with per-side coverage. It refuses malformed snapshot envelopes and reversed chronology. Missing, partial, ambiguous and inconsistent source evidence stays unknown. CPU names are compared as a case-sensitive multiset, preserving multiplicity without inventing a socket mapping. Input objects are not edited; computer names and unexpected properties are excluded.

**Verified within the selected-observation comparison scope.** [PR 21](https://github.com/davidtomofficial/Windows-System-Administration/pull/21), source `16d9e30c43f61a819aba618c9493eafeb2fa21d5`, passed [Windows integration run 42285281367](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42285281367), job 128124381338. The pull-request job checked out synthetic merge `7f4a88ffd9b2808d037fe6cfde64a476b19be8f2` against base `c265ae028f790678479ff4de035711a75625dba7`. Host: Windows Server 2022, image 20261101.353.1.

| Suite | Actual result |
|---|---|
| New comparison regressions | 73 passed in Windows PowerShell 5.1.20348.5773; 73 passed in PowerShell 7.6.9 |
| Existing Imaging checks | 89 passed in Windows PowerShell 5.1/native; 79 passed in PowerShell 7 |
| Imaging packaging | 8 passed on Windows; also 8 locally |
| Existing DeviceCare checks | 98 Windows PowerShell 5.1/native; 93 PowerShell 7; 12 packaging |
| Launchpad / repository gates | 12 planning tests; 13 repository-contract tests |

These are separate suite results, not a combined count of unique acceptance cases. The two extra existing-Imaging checks parse the new module and test file. Native WIM testing still uses a disposable synthetic text-file image. The comparison tests exercise fictional values and do not collect workstation information. They verify the 1 changed / 5 unchanged / 1 unknown example, incomplete and contradictory coverage, missing/duplicate sources, CPU ordering/multiplicity/case, malformed envelopes and timestamps, JSON roundtrip, preserved inputs, projected privacy, ignored script getters, and encoded HTML evidence.

The documented evidence follow-up changes only tracker/documentation text. Runtime, test and packaging bytes remain identical to the source above; later source revisions require their own CI evidence. The full handoff task remains open for required/optional policy checks, peripherals, user workflows and human signoff. Same-device identity, a change's cause, deployment readiness, Windows 11 operator acceptance and A+ acceptance are not established by this comparison.
