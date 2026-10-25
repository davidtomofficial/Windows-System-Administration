# Source provenance and licensing boundary

## This implementation

The initial Modules/WindowsSysAdmin/ implementation, its tests, validation script, workflow, and operator guide are newly authored, generic portfolio work following the Windows System Administrator GitHub Audit and Upgrade Plan. They do not restore or copy the deleted OTS or Intune Scripts implementations. Their behavior is limited to local CIM inventory and offline target-name validation. Fixtures use invented LAB-*, example.test, and synthetic hardware data.

DTS/DTP software, source, packages, integrations, and private deployment configuration are excluded. This module is not presented as one of those products or as a refactor of their maintained source.

## Historical material

The [source-status record](Source-Status.md) pins the earlier inventory and the historical script identities. Those sources can contain employer/environment-specific assumptions. Their availability in public Git history does not establish ownership, permission to relicense, current maintenance status, or suitability for production.

The two existing firewall exports remain unchanged in this implementation. They contain environment-specific values and require a separate privacy/provenance review. Neither this document nor an ignore rule sanitizes their contents or previous commits. See the [network reference cautions](../System-Hardening/Policies/Network/README.md).

## License decision still required

No repository-wide software license is selected by this change. The maintainer must identify the material they are authorized to license, preserve third-party notices, and decide how historical material is treated before applying a license. Do not copy a license from another repository or claim that this repository is reusable open-source software merely because it is public.

Pester, PSScriptAnalyzer, and GitHub Actions remain third-party development dependencies with their own terms. Their source/binaries are not vendored into this repository. Version pins are recorded in [TestDependencies.psd1](../Tools/TestDependencies.psd1), and the checkout action is pinned to a verified upstream commit.

## Import acceptance record

For any later import, record the exact source/commit, author or owner, publication permission, license/notices, environment assumptions removed, operation scope, required privilege, data handling, tests, and lab results. Do not revive old active directories simply to make the repository look larger. No production or employer deployment claims should be inferred from a new portfolio example.
