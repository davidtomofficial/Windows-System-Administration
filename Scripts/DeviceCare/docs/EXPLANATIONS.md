# DeviceCare explanations

**DTO-DC-022 · Development candidate · November 21, 2026 (Pacific)**

DeviceCare should explain what its completed assessment found, why a finding
deserves attention, and what observation would help next. The first slice covers
the two findings implemented by the current public preview: memory use and
system-drive free space.

## Current implementation boundary

The optional `DeviceCare.Explanations.psm1` module provides a local explanation,
a small inspectable model-input packet, a validator for a supplied model result,
and an offline HTML report containing the explanation. The original observation,
finding and report modules retain their source bytes and public commands.

The local explanation runs without an API account. It is identified as locally
generated. The developer request builder prepares an OpenAI Responses API request
without sending it. No hosted endpoint, API key, live model test, charge,
automatic upload, background task or usage check-in is introduced.

A supplied model result is only used when its envelope matches the current input
and its structure, finding identities, states and next-check IDs pass validation.
An invalid result falls back to the local explanation. Validation does not prove
that arbitrary generated prose is factually correct. The original measurements
and states remain visible, and AI wording is identified as such.

## User experience

The report adds **What these results mean** after the findings table. It contains:

1. A short summary.
2. A plain-language explanation for each original finding.
3. A concrete next observation for each finding.
4. The assessment's coverage and the explanation source.

For a fictional assessment with 90 percent memory use and 6 GiB free space, the
explanation identifies both review findings. It suggests inspecting current
memory use and reviewing storage usage. It does not identify a particular process
or file as the cause, recommend a purchase, or claim that maintenance happened.

The offline report uses a normal readable section. The future application can
provide an **Explain these results** control which previews the selected data and
requests an explanation. The current HTML has no JavaScript or network control.

## Communication style

**Owner direction accepted November 21, 2026 (America/Los_Angeles):** DeviceCare
retains a dry, factual, information-focused personality. DTO Chat's quicker,
wittier website personality is a separate profile.

Lead with the recorded observation, explain its meaning and uncertainty, then
identify the supported next observation or maintenance option. Use concise,
plain technical language. Omit banter, promotional wording, jokes and dramatic
diagnoses. Explain unfamiliar terms when they matter to the next decision.

For example, given a fictional memory Review finding above its threshold:

> Memory use exceeded the configured review threshold at the observation time.
> This result does not identify the cause. Review memory usage in Task Manager
> while the symptoms are occurring.

The same factual style should govern future log discussion, maintenance-option
explanations and spoken follow-ups. Those subjects require their own implemented
collectors, evidence and action permissions. The current explanation input still
contains only memory use and system-drive free space; this profile does not add
log collection, diagnose a cause or authorize maintenance.

This update records the communication requirement. Applying and evaluating it
in the live response flow remains part of DTO-DC-022.03 through DTO-DC-022.06;
spoken delivery follows DTO-DC-022.08. Preserve the existing evidence contract,
finding states, output schema and local fallback when refining the instructions.

## Use locally

From the component directory, under the normal PowerShell execution policy:

```powershell
Import-Module .\src\DeviceCare.psm1 -Force
Import-Module .\src\DeviceCare.Explanations.psm1 -Force

$snapshot = Get-DTODeviceCareSnapshot
$assessment = Get-DTODeviceCareFindings -Snapshot $snapshot
$explanation = Get-DTODeviceCareExplanation -Assessment $assessment
$html = ConvertTo-DTODeviceCareExplainedHtml -Assessment $assessment
```

The last two commands return objects or an HTML string. They do not save files,
open a browser, submit information or execute the suggested next check.

For a reproducible example without collecting any device observations:

```powershell
Import-Module .\src\DeviceCare.psm1 -Force
Import-Module .\src\DeviceCare.Explanations.psm1 -Force
$fixture = Get-Content .\examples\synthetic-snapshots.json -Raw | ConvertFrom-Json
$snapshot = ($fixture.Cases | Where-Object { $_.Id -eq 'review' }).Snapshot
$snapshot.CollectedAtUtc = '2026-01-01T12:00:00.0000000Z'
$assessment = Get-DTODeviceCareFindings -Snapshot $snapshot
Get-DTODeviceCareExplanation -Assessment $assessment
$html = ConvertTo-DTODeviceCareExplainedHtml -Assessment $assessment
```

## Exact input boundary

`New-DTODeviceCareExplanationRequest -Assessment $assessment` returns an envelope
with `SchemaVersion`, `InputJson` and `InputSha256`. The SHA-256 covers the exact
UTF-8 bytes of `InputJson`, not a separately reserialized JSON object.

The input contains only the known product/rules/schema identity, valid original
UTC observation time or null, the Boolean false maintenance flag, and two
findings. Each finding carries its known ID, original state, rounded display
value or null, fixed units, and effective threshold or null.

The projection does not copy the original free-text `Explanation` fields,
caller-added properties, raw snapshot, OS caption, process names, file paths,
device/account identifiers or raw provider error messages. An input packet is
still diagnostic information; an eventual client must show its destination and
purpose before any optional submission.

### Status and rounding

| State | Meaning | Next observation |
| --- | --- | --- |
| Observed | Evidence was available and did not meet the selected review rule. | Observe again if symptoms persist. |
| Review: memory | The unrounded memory-use measurement met or exceeded the selected threshold. | Inspect current memory use and workload. |
| Review: disk | The unrounded system-drive free-space measurement fell below the selected minimum. | Review storage usage. |
| Unknown | Evidence was unavailable or invalid. | Retry the observation in an authorized environment. |

The explanation preserves the supplied finding state. It never recalculates it
from rounded display values. For example, 84.96 percent memory use displays as
85 percent while remaining below an 85 percent review threshold; free space one
byte below 15 GiB displays as 15 GiB while remaining a Review finding.

These thresholds do not establish overall device health or prove a cause.
Unknown is not a passing result. Update, reboot, antivirus, servicing and repair
results require future reviewed collectors before they can enter this feature.

## Prepare an API request without sending it

Inspect the output of `New-DTODeviceCareExplanationRequest`. If explicitly saving
it for development, preserve the `InputJson` string and its hash together. Then:

```text
python ai/prepare_request.py explanation-input.json
```

The command prints a Responses API request to standard output. The default
model is `gpt-6.2-sol`; request storage is disabled, output is bounded, and no
model tools are enabled. The instructions and strict output schema are included
in this component's `ai` directory. This command makes no network request and
does not accept or read an API key.

The output schema contains a summary and two explanations. Each explanation
must reference its existing finding and state and select one allowed next-check
ID. The displayed next-check wording comes from the local catalog, not the
model. Extra properties, duplicate or missing findings, mismatched states,
unsupported actions, and stale input bindings are rejected.

## Future backend connection

The next implementation connects an explicitly chosen owner-controlled backend
to OpenAI. Keep its provider key on that backend. Preserve the originating input
hash in backend application state; do not ask the model to create or authenticate
it. On a completed, non-refusal structured response, return:

```json
{
  "InputSha256": "<original request hash from application state>",
  "ModelResponse": {
    "summary": "<model text>",
    "findings": [
      {
        "id": "memory",
        "state": "Review",
        "explanation": "<model text>",
        "next_check_id": "inspect_memory_workload"
      },
      {
        "id": "system-disk",
        "state": "Review",
        "explanation": "<model text>",
        "next_check_id": "review_storage_usage"
      }
    ]
  }
}
```

Supply that envelope as `-AiResponse` to `Get-DTODeviceCareExplanation` or
`ConvertTo-DTODeviceCareExplainedHtml`. A stale result must not overwrite the
explanation for a newer assessment. The hash binds a result to input bytes; it
is not a signature, proof of provider origin or authenticated saved-report format.

Before enabling live submission, complete authentication, destination and data
preview, input/output size limits, per-user quotas, cost controls, bounded timeout
and cancellation, and explicit behavior for a refused, incomplete or unavailable
response. The original assessment and local explanation remain available.
Keep usage check-ins separate from optional diagnostic submission.

## Validation

```powershell
.\tests\Run-Checks.ps1
.\tests\Run-ExplanationChecks.ps1
python .\tests\test_explanation_request.py
python .\tests\test_package.py
```

The explanation checks use fictional inputs. They cover ordinary, review and
unknown findings; custom thresholds, equality and rounding boundaries; privacy
canaries; malformed response structure and binding; bounded text; allowed
next-check IDs; and the local fallback. The existing report and original-runtime
preservation checks remain applicable. The candidate requires its own recorded
test results. Synthetic checks do not establish model quality, attended Windows
11 acceptance, hosted operation or a production release.

### Local verification checkpoint

On November 21, 2026 (Pacific), the candidate based on main
`f8cb9b579b135f42eba4d2b5f2f53e0165f9de06` passed the following on Linux with
PowerShell 7.7.0 and Python:

| Scope | Result |
| --- | --- |
| Explanation contracts and report integration | 140 checks passed. |
| Existing DeviceCare contracts | 97 checks passed, native collection disabled. Four additional checks parse the new PowerShell files. |
| Existing synthetic proof | All six cases matched the independently specified expected summary. |
| API request preparation | 20 Python tests passed. |
| Component package | 12 Python tests passed. |
| Repository preservation and source package | 13 Python tests passed, including original runtime byte preservation. |
| PowerShell-to-Python integration | Four real projected envelopes (Observed, Review, Unknown and rounding boundary) passed the Python preparer, preserving exact input text. |

The report HTML was generated from fictional inputs and its content/offline
boundary checked. Browser layout, attended accessibility, Windows PowerShell 5.1,
Windows 11 and actual model outputs require their own evidence. The PR's Windows
workflow runs the existing suites and the new explanation checks separately;
inspect its actual source SHA and result before treating that scope as verified.

## Acceptance still open

- Verify the receiving API project, available model and approved usage budget.
- Select and configure the authenticated backend through the existing website
  delivery process; no destination is presumed by this candidate.
- Evaluate actual model outputs on a small fixed set of reviewed fictional cases.
- Add an application control with data preview, loading/cancel/failure states and
  snapshot identity; preserve the offline report boundary.
- Validate an authorized Windows 11 workflow and extend to further diagnostics
  only when their collectors and evidence contracts are implemented.

## References

- [OpenAI developer quickstart](https://developers.openai.com/api/docs/quickstart)
- [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [API key safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)
- [API data controls](https://developers.openai.com/api/docs/guides/your-data)
- [DeviceCare task authority](../TODO.md)
