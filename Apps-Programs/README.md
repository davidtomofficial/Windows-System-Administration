# Applications and Programs

This area will describe approved software, acquisition sources, deployment templates, licensing assumptions, update ownership, and detection rules.

The [current workstation baseline](workstation-environment.md) remains here during planning. The [repository blueprint](../Docs/Repository-Blueprint.md) proposes a later move of its full text into `Baselines/`, leaving a navigation link here.

## Planned contents

| Item | Responsibility |
| --- | --- |
| `baseline-apps.json` | Application definitions with stable IDs, approved sources, supported architecture, installation/detection methods, and update policy. Schema and data are not implemented yet. |
| `Config/` | Sanitized app-specific configuration, such as Office deployment templates. |
| `Acquisition/` | Reviewed helpers for obtaining packages from approved sources. |
| `Packages/README.md` | [Package storage policy](Packages/README.md); installer payloads are not committed by default. |

Baseline profiles select application IDs from the catalog. Scripts use those IDs to resolve the approved deployment method. Environment-specific values belong in root `Config/`, and credentials are supplied through the approved runtime mechanism.

Do not assume every application is installed or updated through WinGet. Record a single approved update owner for each application and coordinate that with Intune or other management policies where applicable.
