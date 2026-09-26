# Scripts — Developer Foundation

**Status:** Conventions and planned categories. This staging draft does not contain new executable scripts.

## Organization

Use task-oriented folders: `Deployment`, `Validation`, `Maintenance`, `Configuration`, `Management`, `Remote-Actions`, `Troubleshooting`, and `Decommissioning`. Put reusable helpers in `Common`. Optional cloud and identity adapters belong under `Management/Autopilot`, `Management/Intune`, and `Management/Identity`.

Do not create separate `Technician`, `Developer`, `Local`, and `Cloud` copies of the same implementation. The guide and launchpad identify the audience; task parameters and explicit integration entry points identify the context.

## Naming and responsibility

Use descriptive PowerShell verb-noun names. `Get`, `Test`, and `Export` tasks should make their scope clear; `Install`, `Update`, `Repair`, `Rename`, and removal tasks explicitly change state. Export tasks write evidence but should not silently register or enroll devices.

`Common.psm1` should begin with shared logging, prerequisite checks, configuration loading, and result formatting. Add helpers when actual reuse appears. Keep task-specific implementation in the corresponding task script rather than growing one all-purpose module.

## Contract for each maintained script

Document:

1. Purpose, owner, supported Windows and PowerShell versions, and release status.
2. Required privileges, dependencies, network/service access, and inputs.
3. Whether it checks, changes, uploads, restarts, or deletes anything.
4. Expected result, report location, exit behavior, and known limitations.
5. Example use for the technician guide and a reproducible lab validation procedure.
6. Recovery or next steps for failed, partial, or interrupted runs.

Implementation expectations:

- Resolve resources relative to the tool, not the caller's current folder or a fixed mapped drive.
- Parameterize organization-specific names, targets, printers, and paths.
- Check dependencies and the actual identity/enrollment state before acting.
- Preserve managed update ownership, restart windows, and package exclusions.
- Separate discovery/planning from changes for complex tasks; support PowerShell confirmation/WhatIf where meaningful.
- Make repeat runs safe where possible and document non-repeatable actions.
- Produce a human summary and structured results with task ID/version, run ID, target, time, status, errors, skipped steps, and restart state.
- Report remote outcomes per device, and cloud outcomes per system. Do not collapse partial completion into success.
- Preserve underlying exit/error information when wrappers translate results for the GUI.
- Keep credentials and private data out of source and avoid logging sensitive values.

Do not solve dependency or execution-policy failures through a blanket bypass. Choose and document supported deployment, signing, and permission requirements.

## Verification and release

When runnable tools are imported, validate both intended behavior and failure handling. Use mocked service calls or synthetic data for unit tests and controlled lab devices for installation, enrollment, restart, and removal scenarios. State which PowerShell runtime each entry point requires; Windows PowerShell 5.1 and PowerShell 7 are not interchangeable for every module.

Release the script, BAT wrapper, task metadata, guide, and relevant test evidence together. A validation failure must remain visible to the technician. A successful script exit alone does not mean the workstation meets every baseline requirement.
