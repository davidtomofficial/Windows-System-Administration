# System Hardening — Foundation Outline

Use this area for reviewed security policy intent, settings, rationale, compatibility notes, and approved exceptions. The common workstation baseline links to applicable policies rather than copying them into each script or department profile.

The existing [inbound](inbound-firewall-settings.txt) and [outbound](outbound-firewall-settings.txt) text files are tab-separated reference exports with rule names, profiles, actions, programs, addresses, and ports. They are not importable firewall policy packages or an approved deployment baseline. Their originating device, export date, and approval status are not established by the files. Review their settings and environment-specific entries before using them as design input. See the [migration map](../Docs/Migration-Map.md).

Proposed future folders are `Policies/` and `Exceptions/`. A policy should record its owner, applicable platform/profile, settings, deployment mechanism, validation method, and review date. An exception should record scope, justification, owner, compensating measures where needed, and review/expiration.

Scripts that inspect or apply settings live in `Scripts/`. Test the combined effect of local policies, Group Policy, Intune, and application management before designating a configuration as ready for deployment.
