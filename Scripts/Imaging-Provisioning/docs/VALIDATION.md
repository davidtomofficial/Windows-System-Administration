# DTO 0.2.0 validation scope

The current scripts have dedicated dependency-free PowerShell checks for parsing, default privacy, opt-in identifiers, malformed/empty/partial evidence, row/byte limits, safe HTML, image path restrictions, image metadata and hash behavior. A Windows-only native test creates a tiny synthetic-data WIM on a disposable runner, inspects index 1, and checks that its hash did not change. This is not an operating-system image test.

Fresh execution results are recorded in a separate dated checkpoint receipt; tests existing in source alone do not establish a pass. A green CI run applies only to its exact commit. A later documentation-only checkpoint must record which source hashes remain identical to that tested commit.

The current source package has 15 allowlisted files plus MANIFEST.json, including the standalone license and the November 6 comparison module and checks. Python tests cover reproducibility, content tampering, identity/promotion refusal, extra archive members, excluded local reports, missing sources and DTO branding consistency. Verification is content checking, not publisher trust or deployment acceptance.

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

Execution evidence for this candidate is pending. Source inspection and tests existing on disk are not a Windows pass. The next receipt must record the exact source revision, synthetic merge revision if applicable, Actions run and separate suite outcomes. The full handoff task remains open for required/optional policy checks, peripherals, user workflows and human signoff. Same-device identity, a change's cause, deployment readiness, Windows 11 operator acceptance and A+ acceptance are not established by this comparison.
