# DeviceCare — DTO active development TODO

**2026-11-05 · Personal portfolio scope · 0.2.0 DTO candidate · Not an operational release**

| ID | Status | Acceptance and next action |
|---|---|---|
| DTO-DC-001 | Completed | Source and TODO baseline identified by exact private archive commit; preserve historical application and source bytes. Prework SharePoint snapshot recorded separately. |
| DTO-DC-002 | Prior checkpoint verified | 0.1.0 source commit 3f62035b67293e937eb1b693433e1cec16b8f710 and archive parity verified. Current changes require their own readback. |
| DTO-DC-003 | Implemented | Standalone read-only Windows OS, memory and system-drive observations; missing/failed evidence stays Unknown; no computer name by default. |
| DTO-DC-004 | Implemented | Deterministic Review/Observed/Unknown threshold interpretation, with no false health verdict, authorization or repair claim. |
| DTO-DC-005 | Implemented candidate | Approved original DT vector, readable findings/counts, responsive layout and field-projected evidence. Native UI and attended accessibility remain pending. |
| DTO-DC-006 | Current component checks passed | 0.2.0 at deadfd6add0fb391dd3113e6fd9cfd501e8a7603: 65 WinPS 5.1 checks including native observations, 60 PowerShell 7 contracts and 12 Python tests. Run 42145612233 succeeded on Windows Server 2022. Actual Windows 11 acceptance remains open. |
| DTO-DC-007 | Per-checkpoint | Prior 0.1.0 archive readback/parity verified. Preserve it and verify a new immutable 0.2.0 archive, GitHub blobs and evidence after publication. |
| DTO-DC-008 | Pending | File-by-file review of the full historical Windows PowerShell/WPF application, settings, logos, vendor artifacts, entitlement model and source ownership. Do not copy private runtime unreviewed. |
| DTO-DC-009 | Pending | Port authenticated, least-privilege diagnostic admission and selected maintenance tasks only after review, with a real rollback, journaling and recovery contract. No automatic repairs. |
| DTO-DC-010 | Pending | Rebuild native UI with official DTO DT logo assets; user journeys, font/focus/contrast, zoom, DPI, Narrator and high-contrast acceptance on Windows 11. |
| DTO-DC-011 | Pending | Reconcile existing enterprise GPO/OU, AD, Entra, Intune, SCCM and service checks as read-only evidence with unknown-coverage states. Do not claim an applied/effective policy from registry or service presence. |
| DTO-DC-012 | Pending | Explicit source/owner and supported-servicing policy for Windows Update, Winget, Office and vendor updates; protected recovery, safe refusal and handoff tests. |
| DTO-DC-013 | Pending | Native installer/upgrade/uninstall, signing/distribution, clean and managed Windows 11 devices, startup/recovery, full baseline execution and independent native test/restore evidence. |
| DTO-DC-014 | Pending | Full historical test reconciliation including residual native child failures; do not inherit prior product test counts as new DTO validation. |
| DTO-DC-015 | Pending | Publish release/case study only once rights/privacy, authentic source, backup restore, trusted packaging and real operator acceptance pass. Personal project only. |

**No private runtime, employer/client data, tokens, vendor installers or third-party branding are part of the DTO public preview.** Historical source and evidence remain preserved in the restricted archive.

## Continuation — branding, report reliability and toolkit integration

| ID | Status | Acceptance and next action |
|---|---|---|
| DTO-DC-016 | Complete (boundary regression scope) | Compare raw disk/memory values before display rounding. Twelve isolated below/equal/above cases cover default and configured thresholds, identical rounded displays and recorded effective thresholds. November 6 Windows run 42281513012 passed 98 WinPS 5.1/native and 93 PowerShell 7 checks; [exact source, cases and limits](docs/VALIDATION.md#dto-dc-016-boundary-regression-verification). Runtime bytes are unchanged; Windows 11 and operational acceptance remain separate. |
| DTO-DC-017 | Implemented candidate | Reject non-Boolean mutation flags; project only known report fields; encode text; refuse malformed or duplicate findings and tampered artwork. Treat this as in-process presentation, not an authenticated saved-report parser. |
| DTO-DC-018 | Planned | Shared action/result interface for launchpad and DeviceCare without duplicating maintenance logic; keep diagnostics, planning and authorized changes distinct. |
| DTO-DC-019 | Planned | Native DTO dashboard: original logo/icon variants, assessment worker, cancellation, keyboard/focus, high contrast and 100–200% DPI. Preserve incomplete evidence and test real user actions. |
| DTO-DC-020 | Planned | Reconcile service/software observations and management authority before maintenance; retain missing, stale, unavailable and conflicting evidence separately. |

Original DTO-DC-001–015 IDs remain. Refer to the dated continuation receipt for actual native and remote-publication outcomes; a checklist edit does not accept a release.

Latest verified source/test and limitation summary: [continuation progress](../../Docs/DTO-WINDOWS-ADMIN-PROGRESS.md). Remote archive parity is recorded in the dated delivery receipt, not inferred from this checklist.

## Required check-in continuation — November 5, 2026

- [ ] **DTO-DC-021 / P1 — Required periodic check-in for future permission-licensed builds.** Implement the shared DTO-WSA-042–046 requirements with disclosed authorized enrollment, minimal aggregate usage, a verified owner-controlled receiver, receipt/retention controls and safe offline behavior. Current code has no check-in or usage telemetry. Existing license grants remain unaffected.

[Shared implementation contract](../../Docs/USAGE-CHECK-IN.md) · [Repository continuation TODO](../../Docs/REPOSITORY-REVIEW-TODO.md)

## Assessment explanations — November 21, 2026

| ID | Status | Acceptance and next action |
|---|---|---|
| DTO-DC-022 | Development candidate; working-system continuation authorized after Work renewal | Optional local explanation and offline report section for the two implemented findings; projected, inspectable input; offline Responses request builder; input-bound response validation and local fallback. Owner reports API account setup complete with project **DeviceCare Development**. Complete the phased continuation below after the Work allowance renews. Original collector and report source remain preserved. Live API, hosted operation and attended acceptance are still open. |

[Explanation scope, examples, contract and next steps](docs/EXPLANATIONS.md).
This adds the user-selected API workstream without changing the ownership or status
of the existing maintenance, native UI and check-in tasks.

### Working-system continuation authorized November 21, 2026

The owner reports that API account setup is complete and the **DeviceCare
Development** project exists. The owner explicitly requested development and
implementation of a working explanation system alongside DeviceCare, including
this project's TODO, **once ChatGPT Work usage renews**. This reactivates the
bounded DTO-DC-022 implementation after that condition; it does not restart
unrelated deferred work. API credit renewal and Work allowance renewal are
different conditions.

**Current execution state: waiting for the Work reset time.** No current reset
date/time or account-meter access has been verified. Record the owner's current
reset timestamp, including timezone, before scheduling the implementation run;
do not infer it from an older weekly reset or the API billing cycle. The run must
perform the implementation, not merely remind the owner. Do not use purchased
Work credits or a banked reset to bypass this waiting instruction.

Account/project creation is owner-reported complete. The actual API grant,
available model, effective usage limit, backend credentials and hosting
configuration remain to be verified. The previously suggested $25 pilot limit
is a proposal, not evidence of a configured or approved spending limit.

| Subtask | State / owner | Work and acceptance |
|---|---|---|
| DTO-DC-022.01 | Ready after renewal / agent | Refresh main, PR #27, the explanation branch, current CI and active work claims. Preserve the tested candidate, resolve concurrent changes, and record exact starting revisions. Existing evidence: head `5f69695aff27214990466a66bb4e431a4eb00626` passed [Windows integration run 44969324995](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/44969324995); this is not evidence for later runtime changes. |
| DTO-DC-022.02 | Prerequisites to verify / agent; owner for private settings | Verify DeviceCare Development, usable credits, model access and effective spending controls. Inspect the existing approved WordPress/backend delivery path and prepare protected server secret configuration. Establish owner-only pilot access and a known HTTPS destination. Ask for only an unresolved owner action after the configuration is concrete; never request a key in chat or commit it. |
| DTO-DC-022.03 | Pending / agent | Implement the authenticated backend and Responses API integration. Validate the minimal input, bound request/output size, enforce quotas, preserve the originating input hash in application state, and validate completed responses. Handle timeout, cancellation, refusal, incomplete output and service errors. Unauthorized or malformed requests must fail safely without exposing secrets or raw provider errors. |
| DTO-DC-022.04 | Pending / agent | Integrate an explicit **Explain these results** action with an exact data/destination preview, loading, cancellation, retry and current-assessment binding. Display labeled AI text beside the original evidence. Preserve the complete local explanation when the API is unavailable or its response is rejected; do not upload automatically or perform repairs. Keep the exported report's offline behavior. |
| DTO-DC-022.05 | Pending / agent | Evaluate real model outputs on reviewed fictional Observed, Review, Unknown, equality and rounding cases. Exercise authentication, malformed/stale output and unavailable-service paths. Record model identity, explanation quality, latency and metered usage. Run relevant Windows PowerShell/Python regressions against the exact source; do not accept schema validity as proof that prose is correct. |
| DTO-DC-022.06 | Pending / agent and owner | Prepare a short attended personal Windows 11 test. Verify the assessment-to-explanation flow, readability, keyboard behavior and failure recovery. Record what was actually observed and retain separate broader UI/accessibility and installer acceptance tasks. |
| DTO-DC-022.07 | Pending / agent | Deliver the working private pilot with setup/run instructions, a reproducible review build, exact source/test evidence and the required preservation receipt. Update this TODO, the repository master index and existing project records. List concrete owner-only blockers separately; keep public/production release acceptance open until its own gates pass. |
| DTO-DC-022.08 | Accepted follow-up / agent; after text pilot | Add optional spoken explanations of the same reviewed assessment through a GPT-Live interface. Retain the visible source findings, exact payload preview, assessment binding, allowed next observations and local text fallback. Use DeviceCare Development's own backend/project configuration. Verify microphone consent, captions/text alternative, interruption and stop behavior, session limits, usage accounting and spoken faithfulness. Voice does not authorize repairs, imply screen/camera observation or add diagnostic collectors. |

**API project separation, accepted November 21:** the owner will create a
separate **DTO Chat** project for website assistants, briefing questions/audio,
servicing guidance and learning experiences. The website may explain the
published DeviceCare documentation; actual device-assessment and spoken
explanation requests remain owned here and use **DeviceCare Development**.
Shared components must retain separate credentials, access and usage accounting.
DTO-DC-022.08 follows the working text pilot and the existing Work-renewal gate.

**First working milestone:** one completed memory/system-drive assessment can
be previewed and explicitly submitted to the authenticated backend, return a
validated explanation, and display it in DeviceCare while retaining the local
fallback. Demonstrate both successful and failed requests with evidence.

Additional diagnostics require their reviewed collectors and evidence contracts.
DTO-DC-021 retains usage-check-in ownership; DTO-DC-010/019 retain the broader
native UI scope; DTO-DC-013/015 retain installer, distribution and release
acceptance. Use the existing protected preservation workflow and keep private
account details, credentials and real diagnostic reports out of public records.
