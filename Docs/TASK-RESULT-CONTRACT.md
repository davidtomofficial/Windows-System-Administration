# Shared task result contract v1

Authority: **DTO-LP-003**. This is a small local data contract for future DeviceCare,
Imaging and Launchpad adapters. It contains no task dispatcher, maintenance action,
saved device report, authorization check, telemetry or automatic file write.

## Why this exists

Collecting evidence, attempting an action and verifying its outcome are different
events. The contract requires an `observation`, `action` and `verification` record.
Each keeps its own state and evidence references. There is deliberately no overall
success flag, health verdict or generic severity ranking.

| Status | Meaning within the named phase |
|---|---|
| `Succeeded` | The phase's defined work completed. Observation and verification need complete referenced evidence. This never certifies the whole device. |
| `Failed` | The phase failed; retained evidence and possible effects are still recorded. |
| `Partial` | Some useful work or evidence exists but the phase is incomplete. |
| `Skipped` | The phase was intentionally not attempted, with an explicit reason code. |
| `Unknown` | The outcome is missing, unavailable or inconclusive. It is not a pass. |
| `Cancelled` | Cancellation is the recorded outcome. It does not imply rollback, safe process termination or absence of effects. |
| `RestartRequired` | Action only: its defined pre-restart boundary was reached and verification remains skipped or unknown. It does not authorize a restart. |

`restartRequired` is independently `true`, `false` or `null` (unknown). A failed or
partial action can still require a restart. The field describes this operation;
an existing pending-restart observation belongs in the original component evidence.
`changesAttempted` and `effects` (`None`, `Observed`, `Unknown`) are explicit claims
about this attempt, never permission to perform it. Unknown effects survive a
failed or cancelled change. A known no-op can have attempted changes and no effects.

## Exact envelope

All listed fields are required. Extra fields, unsupported versions and silent defaults
are refused. Field names, status values and IDs are case-sensitive.

| Field | Type and bound |
|---|---|
| `schemaVersion` | Integer `1`; Boolean and floating-point impostors refused |
| `operationId` | ASCII token, 1 to 128 characters; catalog identity, never a command |
| `runId` | Canonical lowercase UUID string identifying this attempt; validation does not prove uniqueness |
| `operationKind` | `Observation`, `Plan` or `Change` |
| `source` | Exact object: `component` (text up to 128), `version` (text up to 64), `revision` (40 lowercase hex characters) |
| `startedAtUtc`, `completedAtUtc` | Original timestamp strings or `null`; known completion cannot precede known start |
| `changesAttempted` | Actual Boolean |
| `effects` | `None`, `Observed` or `Unknown` |
| `restartRequired` | Actual Boolean or `null` |
| `observation`, `action`, `verification` | Each has exactly `status`, `reasonCode`, `evidenceIds` |
| `evidence` | Array of at most 128 evidence descriptors |

A phase's `reasonCode` is a required ASCII token up to 64 characters. Its
`evidenceIds` is an array of at most 128 unique tokens up to 64 characters; every
reference must resolve to an evidence descriptor. Tokens start with an ASCII letter
and continue with ASCII letters, digits, periods, underscores or hyphens. They are
data, never executable paths or code.

An evidence descriptor has exactly these fields:

| Field | Meaning |
|---|---|
| `id` | Unique token, up to 64 characters |
| `type` | Nonblank text up to 128 characters identifying the original evidence format |
| `schemaVersion` | Original component schema version, integer 1 through 2147483647 |
| `collectedAtUtc` | Unaltered original collection timestamp, or `null` if genuinely unknown |
| `coverage` | `Complete`, `Partial` or `Unknown`; schema validity is not evidence completeness |
| `sha256` | Lowercase 64-character digest of exact retained evidence bytes, or `null` if no digest was established |

Timestamp syntax is `YYYY-MM-DDTHH:MM:SS[.fraction]Z` or the equivalent `+00:00`
suffix, with 1 to 7 fractional digits when present. Calendar validity and 100 ns
ordering are checked. Strings are not reformatted. Unknown source time stays null;
it must not be replaced with the current time. Evidence may predate this attempt;
its age is preserved without inventing a universal freshness rule. Non-UTC source
formats need an explicitly reviewed adapter and retained original evidence, not a
silent conversion in this contract.

Generic text is preserved without trimming, but must be nonblank and contain no
C0 controls, DEL or unpaired Unicode surrogates. Character limits count Unicode
scalar values. All envelopes remain local and should be reviewed before sharing.

## Rules that prevent contradictory claims

- Observation and Plan require an explicitly skipped action, no attempted changes,
  no observed effects and no required restart from this operation.
- No attempted changes requires `effects: None` and forbids action Succeeded,
  Partial or RestartRequired, or `restartRequired: true`.
- Attempted changes cannot have an action marked Skipped.
- RestartRequired belongs only to a Change action with attempted changes and a
  true restart flag. Verification must remain Skipped or Unknown.
- Succeeded observation or verification requires at least one evidence reference,
  and every referenced descriptor must have Complete coverage.

An action can succeed while verification fails. Both states remain visible.
The validators do not authenticate the claims, check whether referenced evidence
exists, recompute its digest, prove a source revision's authenticity, or establish
management authority. Future adapters must retain the original component payloads
and verify their bindings. Digests are not signatures.

## Implemented interfaces and trust boundaries

| Interface | Accepted input | Behavior |
|---|---|---|
| `Launchpad/result_contract.py` | Bounded UTF-8 JSON bytes, a selected local file or a Python dictionary | Strict saved-JSON reader plus explicit structural and semantic validation; returns the original values without normalization |
| `Shared/ResultContract.psm1` | Known in-memory hashtables, ordered dictionaries or PSCustomObject note properties | `New-DTOTaskResult` validates and returns the supplied object; `Assert-DTOTaskResult` refuses invalid input; `ConvertTo-DTOTaskResultJson` revalidates and returns JSON text |

Python's saved-input reader rejects duplicate keys, nonfinite numbers, malformed
UTF-8, unsupported or extra fields, invalid scalar types, unresolved references and
input larger than 1 MiB. PowerShell does not expose a saved-JSON parser: its own
ConvertFrom-Json behavior is not a substitute for those raw-input guarantees.
The constructor does not freeze its object; serialization validates it again.
Neither API collects data, dereferences an evidence reference, starts a process,
contacts a service or writes a report automatically.

The PowerShell test harness uses its bundled Json.NET solely to load trusted
synthetic fixtures without date coercion. That fixture helper is not a runtime
parser. The test harness also writes temporary synthetic output and invokes Python
to compare actual serialized bytes with the original fixture values.

## Reproduce the contract checks

```text
python Launchpad/test_result_contract.py
powershell -NoProfile -File Tests/Run-ResultContractChecks.ps1
pwsh -NoProfile -File Tests/Run-ResultContractChecks.ps1
```

On an authorized development host, a known in-memory producer uses:

```powershell
Import-Module ./Shared/ResultContract.psm1
$result = New-DTOTaskResult -InputObject $explicitResultFields
$json = ConvertTo-DTOTaskResultJson -InputObject $result
```

`$explicitResultFields` must supply every field above from the real producer's
known evidence. Do not invent source times, revision hashes, permission or success.
The [shared synthetic fixtures](../Contracts/fixtures/task-result-cases.json) show
complete examples, including partial evidence, failed verification, cancellation,
restart state, null time and contradictory inputs that must be refused.

## Completion boundary

LP003 concerns the schema, semantics, producer/consumer and conformance fixtures.
Live DeviceCare and Imaging adapters remain **DTO-LP-010/011 / DTO-DC-018**.
Fixed dispatch, privilege, journaling/recovery, wrappers, GUI and installed Windows
11 acceptance remain their existing open tasks. Existing component schema versions,
runtime files and the 26 non-executable planning entries are preserved. The broader
**DTO-WSA-003** contract/integration task remains open for its other requirements.

This is a source development increment, not an operational release or A+ acceptance.
CI and preservation evidence must identify their actual tested revisions.
