# Baselines — Desired Workstation State

Baselines define what a supported workstation should contain and how readiness is assessed. They are separate from implementation scripts and completed device checklists.

The current authoritative draft remains [Apps-Programs/workstation-environment.md](../Apps-Programs/workstation-environment.md). This planning pass preserves that file.

When the proposed hierarchy is adopted:

1. Move the full draft to `Workstation/Windows11-25H2.md`.
2. Replace the old file with a short link to the new location.
3. Add department extensions under `Departments/` without copying the full office baseline.
4. Add machine-readable profile selections only after the application catalog and validation requirements have an agreed schema.

An office profile selects required application IDs and configuration expectations; department profiles add approved requirements. The application catalog owns installer/source details. Security policy documentation remains under `System-Hardening/` and is referenced where relevant.

A functional baseline does not guarantee complete security. Required protections and access controls must be in place before access to the affected systems or data is granted.
