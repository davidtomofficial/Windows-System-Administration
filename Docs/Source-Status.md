# Source Status and Provenance

**Reviewed:** October 24, 2026  
**Repository:** `davidtomofficial/Windows-System-Administration`  
**Inventory baseline:** [`42bc7f7953a2acfe7d7f18ebc6728a20dfcf2610`](https://github.com/davidtomofficial/Windows-System-Administration/tree/42bc7f7953a2acfe7d7f18ebc6728a20dfcf2610)

This record distinguishes available source from planned tooling. It does not certify a historical script for production use.

## What the checked revision contains

The recursive Git tree at the inventory baseline contains 17 files: 15 Markdown documents and two firewall text exports. There are no PowerShell scripts, BAT launchers, Python launchpad, application catalog, or automated tests at that revision. The `Scripts/` and `Launchpad/` directories contain design READMEs only. The network-policy README is an empty placeholder.

The maintained baseline draft is [Apps-Programs/workstation-environment.md](../Apps-Programs/workstation-environment.md). The full hierarchy in [Repository-Blueprint.md](Repository-Blueprint.md) remains a proposed destination tree, not a list of available commands.

## Historical source that remains accessible

Two commits on September 26, 2026 removed the earlier script collections:

| Change | Commit | Immediately preceding revision |
| --- | --- | --- |
| Delete `Intune Scripts/` | [`5b635591c3394ce3894275373e8dd87d3af796b2`](https://github.com/davidtomofficial/Windows-System-Administration/commit/5b635591c3394ce3894275373e8dd87d3af796b2) | `3ffbc99920dda550317ab33dc357615a96734586` |
| Delete `OTS/` | [`42bc7f7953a2acfe7d7f18ebc6728a20dfcf2610`](https://github.com/davidtomofficial/Windows-System-Administration/commit/42bc7f7953a2acfe7d7f18ebc6728a20dfcf2610) | `5b635591c3394ce3894275373e8dd87d3af796b2` |

[`3ffbc99920dda550317ab33dc357615a96734586`](https://github.com/davidtomofficial/Windows-System-Administration/tree/3ffbc99920dda550317ab33dc357615a96734586) is a common reference immediately before either collection was removed. The following links are pinned to that revision rather than to the moving `main` branch.

| Historical source | Git blob identity |
| --- | --- |
| [Post Checks implementation](https://github.com/davidtomofficial/Windows-System-Administration/blob/3ffbc99920dda550317ab33dc357615a96734586/OTS/Post%20Checks/postChecks.ps1) | `ff2232303c86d804eed31c77c6a0d9880e6f88bd` |
| [Bulk login implementation](https://github.com/davidtomofficial/Windows-System-Administration/blob/3ffbc99920dda550317ab33dc357615a96734586/OTS/QOS/bulkLogin.ps1) | `6ae42994edb5d2808aff5557fa12952bb2138920` |
| [Autopilot enrollment implementation](https://github.com/davidtomofficial/Windows-System-Administration/blob/3ffbc99920dda550317ab33dc357615a96734586/Intune%20Scripts/AutoPilot%20Enrollment/Intune%20-%20AutoPilot%20Enrollment.ps1) | `f52cbd9373431ed22b8013c8ee1c31437ddf0270` |
| [Work/school account sync implementation](https://github.com/davidtomofficial/Windows-System-Administration/blob/3ffbc99920dda550317ab33dc357615a96734586/Intune%20Scripts/Sync%20Work%20or%20School%20Account/Intune%20-%20Sync%20Work%20or%20School.ps1) | `56b2bbffc43a6f07086e00ba79fee2323216d974` |

These are Git object identifiers used to compare exact source versions, not package-signature or SHA-256 validation records. The removal history establishes availability and provenance; it does not establish that these versions are the latest local implementations or explain why they were removed.

## Source reconciliation before implementation

The current branch does not provide an executable DeviceCare implementation. Its relationship to any maintained local DeviceCare candidate remains unverified. Before importing or refactoring a runtime:

1. Identify the maintained source location, version, and owner; compare it with the historical files above.
2. Record the selected source identity and preserve existing functionality and attribution. Review the scope of licensing and any environment-specific material before importing it.
3. Separate assessment behavior from updates, repairs, enrollment, restarts, and deletion according to the actual implementation.
4. Record the required Windows/PowerShell versions, dependencies, existing tests, and results on representative lab devices.
5. Import a bounded implementation with its guide and validation evidence, then update the [migration map](Migration-Map.md).

The October review did not restore or execute the historical scripts. The current working changes reconcile the documentation and add the source-control exclusions already described by the foundation. Neither the application catalog schema nor the proposed launchpad has been implemented.

## Reference exports

The two firewall text files have tab-separated rule-summary columns. They do not identify an authoritative originating device, export date, or deployment approval. Keep them as historical design references until their applicability is reviewed; see [System-Hardening](../System-Hardening/README.md).
