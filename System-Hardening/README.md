# System Hardening — Foundation Outline

Use this area for reviewed security policy intent, settings, rationale, compatibility notes, and approved exceptions. The common workstation baseline links to applicable policies rather than copying them into each script or department profile.

The existing GitHub firewall text files require content review before classification as documentation, reference exports, or deployable configuration. See the [migration map](../Docs/Migration-Map.md).

Proposed future folders are `Policies/` and `Exceptions/`. A policy should record its owner, applicable platform/profile, settings, deployment mechanism, validation method, and review date. An exception should record scope, justification, owner, compensating measures where needed, and review/expiration.

Scripts that inspect or apply settings live in `Scripts/`. Test the combined effect of local policies, Group Policy, Intune, and application management before designating a configuration as ready for deployment.
