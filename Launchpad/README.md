[README.md](https://github.com/user-attachments/files/32687179/README.md)
# Technician Launchpad — Design Outline

**Status:** Planned. No GUI, BAT launchers, or task catalog has been implemented by this foundation draft.

## Purpose

Provide a small Python window with clearly labeled buttons for reviewed support tasks. The user selects a task, sees its prerequisites and effects, runs it, and receives a readable result. Plain labels and reliable behavior are the priority.

The execution chain will be:

```text
app.py → actions.json → a known BAT launcher → a known PowerShell task → results
```

BAT files also work directly when Python is unavailable. A future packaged GUI can improve distribution, but the underlying tasks remain independent of the interface.

## Proposed first screen

Use categories from the [repository blueprint](../Docs/Repository-Blueprint.md): Prepare a device; Validate and hand off; Update and maintain; Connect to management; Troubleshoot and support; Manage a computer group; Return or remove a device.

Start with only reviewed tasks. A task that is not ready should be absent or clearly disabled with an explanation, not presented as a working button.

Each button's task details should include:

- A plain-language label and one-sentence purpose.
- Whether it inspects or changes the device.
- Local-device or remote-target scope, prerequisites, and management dependencies.
- Administrator or service permissions required.
- Expected restart or interruption behavior.
- A link to the guide and the result/report location.

For a first release, use a simple task selection, Run button, status area, and Open report button. Confirm disruptive operations using the exact device or resolved target list. Display success, failure, partial completion, skipped work, and restart required distinctly.

## Responsibilities

| Component | Responsibility |
| --- | --- |
| Python GUI | Display tasks, validate inputs, start a fixed launcher, show process status and results. |
| `actions.json` | Map a stable task ID to its label, category, relative launcher path, guide, prerequisites, and release status. |
| BAT launcher | Resolve paths from its own location, start the intended PowerShell entry point, and propagate the result/exit code. |
| PowerShell task | Perform its checks and changes, enforce prerequisites, and write consistent results. |

Launch the GUI without blanket elevation. Request additional privilege for the selected task as needed. BAT and direct PowerShell use must preserve task safeguards rather than depending on a GUI-only confirmation.

During execution, disable conflicting operations and show that work is still running. Cancellation must reflect what the underlying installer or operation actually supports. Never display “completed” simply because a terminal window opened.

The GUI should contain neither tenant credentials nor a free-form command executor. Do not duplicate package installation, enrollment, or device-removal logic in Python or BAT files.

## Definition of a released action

A released button has a reviewed PowerShell implementation, a portable wrapper, a technician guide, documented prerequisites and results, and evidence of successful and failed runs on representative systems. Python/runtime packaging and script-signing policy will be selected during implementation.
