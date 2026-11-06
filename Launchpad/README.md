# Technician Launchpad

**David Tom Official · Planning implementation, not an executable toolbox**

The launchpad is intended to make reviewed technician jobs easy to find: preparation, validation, maintenance, management, troubleshooting, computer groups and device return. The current implementation validates and lists a 26-entry planning catalog and provides a shared result contract for future adapters. It cannot launch a script, upgrade Windows, remove profiles or delete data.

[Permission and licensing](../LICENSE.md) · [Active TODO](TODO.md) · [Windows administration master](../Docs/DTO-WINDOWS-ADMIN-TODO.md)

## Review now

For an authorized development review:

```text
python Launchpad/plan.py
python Launchpad/test_plan.py
python Launchpad/test_result_contract.py
```

Every catalog entry must remain `Planned`, with `launcher: null` and `executionEnabled: false`. The validator refuses executable mappings and malformed catalog fields.

## Shared result contract

[Task result contract v1](../Docs/TASK-RESULT-CONTRACT.md) records observation,
action and verification separately. Its Python saved-input validator and
PowerShell in-memory producer preserve source identity, original evidence time,
partial or unknown coverage, cancellation, effects and restart state. Shared
synthetic cases check accepted results and contradictory inputs. This does not
connect the planner to DeviceCare or Imaging; those adapters remain open.

The result validator reads only a caller-selected local file:

```text
python Launchpad/result_contract.py --help
```

## Intended architecture

```text
Technician chooses a reviewed job
  -> Python interface or known BAT wrapper
  -> one canonical PowerShell operation
  -> scoped result, evidence and human handoff
```

No free-form command executor. Direct PowerShell/BAT use must preserve the same prerequisites, target selection, authorization and recovery boundaries as the eventual GUI. Diagnostics, plan generation and state-changing operations remain separate.

Read [migration and cleanup requirements](../Docs/Technician-Migration-and-Cleanup.md) for Windows 10-to-11 and profile/data handling. Read [future check-in requirements](../Docs/USAGE-CHECK-IN.md) for the newly requested licensing/usage work. Neither document enables those features.

The earlier [design outline](DESIGN.md) is retained for provenance. It is not evidence that its proposed buttons exist.
