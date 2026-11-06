# Validation — DTO DeviceCare 0.2.0 continuation

## Verified prior baseline

Commit `3f62035b67293e937eb1b693433e1cec16b8f710`, Actions run `42141845609`: 49 Windows PowerShell 5.1 checks including native read-only observations, 44 PowerShell 7 checks, nine Python packaging tests. Those results belong to 0.1.0 only.

## Current candidate

Twelve local Python checks pass: deterministic packaging, manifests and tamper refusal, extra-file exclusions, identity boundaries, asset byte identity, version alignment and offline report structure. Added PowerShell cases cover pre-rounding thresholds, exact Boolean flags, projected extra-field exclusion, known states, approved artwork and useful report structure. Native execution must be recorded against the current commit, not inferred from source or old passes.

The report is a string returned to the caller. This increment neither writes reports nor opens browsers, starts installers, deletes profiles, changes services or calls a network. Asset checks detect changed bytes; they are not a signature or an authorization mechanism. Rendered sample evidence uses synthetic observations.

Windows Server CI is not attended Windows 11 acceptance. Native desktop WPF, keyboard/Narrator/High Contrast, actual maintenance, installer lifecycle, upgrade/cleanup, recovery and full historical application integration remain open. Per-call CIM timeouts still do not guarantee a total wall-clock deadline.
