# Validation evidence and lab acceptance

## What each layer establishes

| Layer | Implemented mechanism | What it does not establish |
| --- | --- | --- |
| Syntax/static analysis | Tools/Test-Repository.ps1, parser plus pinned PSScriptAnalyzer | Runtime behavior or system compatibility |
| Unit tests | Synthetic CIM mocks and target-name edge cases | Successful real-system queries, AD/GPO/Graph operations, or production safety |
| Windows runner smoke | Explicit -IncludeRunnerSmoke on windows-2022, using Windows PowerShell and PowerShell 7 jobs | Windows 11 physical hardware, standard-user permissions in every environment, or business workflow acceptance |
| Representative Windows lab | Manual cases below, with per-commit evidence | A guarantee for all hardware, policies, or later commits |

Use the actual workflow result for the exact reviewed commit. This document deliberately does not carry a permanent "CI passed" badge or convert planned cases into results. The development environment used to prepare the first patch has no local PowerShell runtime; a source inspection is not a substitute for the Windows CI jobs.

## Reproduce quality checks

Install the pinned tools through the [contribution instructions](../CONTRIBUTING.md), then run each command in both supported Windows runtimes:

~~~powershell
.\Tools\Test-Repository.ps1
.\Tools\Test-Repository.ps1 -IncludeRunnerSmoke
~~~

The first command is synthetic/unit validation. The second also queries the current Windows host. Both write generated test/coverage XML under ignored TestResults/. Do not publish real inventory as test evidence. Test failures, skipped/not-run cases, and coverage shortfalls must remain visible.

## Manual acceptance matrix - not yet completed

Use authorized Windows 11 Pro/Enterprise x64 lab devices. Record edition/build, hardware/VM model, PowerShell version, privilege level, relevant CIM restrictions, commit, date, operator, and outcome in private evidence. Publish only a reviewed, sanitized summary.

| Case | Expected result | Status |
| --- | --- | --- |
| Import on Windows PowerShell 5.1 and PowerShell 7.4+ | Exactly two public commands; no prompts/downloads/policy changes | Lab pending |
| Standard-user local inventory | Data returned if permitted; otherwise a clear terminating error without automatic elevation | Lab pending |
| Inventory without identifiers | Name, serial, and domain null; no file, upload, restart, or setting changes | Lab pending |
| Explicit identifier request | Selected identifiers returned; operator handles output privately | Lab pending |
| Query denied/unavailable | No partial-success inventory; original failure remains visible | Lab pending; synthetic negative tests exist |
| Missing optional data | Null fields, not invented false/zero values | Lab pending; synthetic tests exist |
| Range/list planning | Bounded, deterministic names; no network sessions; no partial list on invalid input | Lab pending; unit tests exist |
| Repeat execution | Same requested scope, new timestamp, no state-changing side effects | Lab pending |
| Non-Windows inventory | Explicit unsupported-platform error; name planning remains pure | Real-host test pending; platform guard mocked in unit tests |

The hosted CI runner has elevated/service-context permissions and virtual hardware. Its successful smoke test must not be reported as a standard-user or Windows 11 lab pass.

## Evidence record template

~~~text
Commit:
Workflow run and conclusion (when applicable):
OS edition/build and architecture:
PowerShell and test dependency versions:
Privilege context:
Case and expected behavior:
Observed behavior:
Passed / Failed / Not run:
Sanitized evidence location:
Known limitations and follow-up:
Reviewer:
~~~

## Promotion gate

Do not label the preview released until both Windows CI jobs pass for the reviewed commit, representative lab cases are recorded, operator documentation agrees with behavior, provenance/licensing decisions are made, and the maintainer explicitly approves release. AD, GPO, WEF, DHCP, backup/recovery, and cloud operations have no implementation or lab evidence in this first module.
