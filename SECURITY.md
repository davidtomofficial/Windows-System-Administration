# Security policy

This repository is a development-preview portfolio, not a supported production management product. No stable release or response-time commitment is established. Report defects against the exact commit and runtime tested; do not infer a supported release line from a module's preview version.

## Private reporting

Never put credentials, access tokens, private keys, recovery information, raw inventory, or sensitive organizational details in public issues, PRs, or test logs. Use GitHub private vulnerability reporting **when available for this repository**. Its enablement has not been verified. If it is unavailable, request a private reporting channel from the repository owner without disclosing the vulnerability details publicly.

## Scope and handling

The new module performs local inspection and offline name planning only. It does not remediate, upload, enroll, or restart. Identifier omission is a privacy default, not complete anonymization. Treat even identifier-omitted inventory as potentially sensitive. Keep generated records in approved private storage and review the permissions and retention of any explicit export.

Existing firewall reference exports and historical commits may contain machine, user, and environment identifiers. They have not been certified as sanitized. The new ignore rules cannot remove already committed data. No claim is made that secret scanning or push protection is enabled, or that a full history scan has passed.

For a verified credential disclosure, revoke/rotate the affected credential through the responsible owner, investigate exposure, and coordinate remediation of affected history and copies. Do not rewrite repository history or delete historical evidence solely because an automated scanner produced an unverified finding.

See [provenance](Docs/Provenance.md) and [network reference cautions](System-Hardening/Policies/Network/README.md). Do not import the historical firewall exports as policy.
