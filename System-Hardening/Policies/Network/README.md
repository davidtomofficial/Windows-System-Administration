# Network policy references - not a deployable baseline

The [inbound](../../inbound-firewall-settings.txt) and [outbound](../../outbound-firewall-settings.txt) files are historical, tab-separated rule exports. They are not importable firewall policy packages, current Windows defaults, an approved security baseline, or proof of the effective configuration on any present device.

The exports include machine/user-specific values and application paths. The inbound text also contains an incomplete row rather than a complete rule record. Do not treat these files as validated structured input, publish their contents in additional examples, or reconstruct a missing rule by guessing. Their origin, export date, policy source, and approval are not established.

The current implementation leaves these exports unchanged to preserve the reviewed source boundary. A separate follow-up should inventory identifying values, establish publication rights, and decide whether to replace the working-tree references with synthetic examples. Any current-tree cleanup would still leave historical copies; history rewriting requires a deliberate, separately approved remediation plan.

Before any real policy work, document the network profiles, update/control owner, required application traffic, remote-support dependencies, rollback path, test cases, and approval. Validate interactions with local policy, Group Policy, Intune, and vendor applications in an isolated lab. Do not apply the old block/allow entries to a production workstation as a default.

No firewall rules are read, imported, applied, or changed by the new inventory module. See [SECURITY.md](../../../SECURITY.md) and [Provenance.md](../../../Docs/Provenance.md).
