# DeviceCare — public migration boundaries

This is a separate, original personal-portfolio implementation rather than a wholesale repackaging of earlier work. All tested outcomes refer only to this exact DTO source and must not be extrapolated to another application's tests, installation status, or deployment readiness.

## Scope matrix

| Capability | DTO preview state |
| --- | --- |
| Local OS, memory, system-disk snapshot | Read-only subset; not an endpoint-security assessment |
| Threshold-based interpretations | Implemented for memory usage and system-drive free space only |
| Local HTML report | Returned string; not saved or transmitted |
| Native desktop application | Not ported; approved report logo included; native app/icon and installer assets remain pending |
| App updates, cleanup, repairs | Not implemented; no authorization to change the machine |
| Device management and enterprise policy | Not assessed in this release |
| Windows 11 / native installer / restore | Not qualified |

## Public privacy and rights gate

Exclude employer/organization-specific code, source identifiers, client or operator data, internal domains, confidential policies, historical private reports, vendor binaries, credentials and independently unapproved logos. Synthetic tests must not contain live machines or their data. GitHub is a public showcase: only approved new source belongs here. Restricted historical records remain outside the public source. No private-source crosswalk, hash, or business archive pointer is published.

## Rollback

This preview does not alter a device; there is no application rollback operation. Preserve the GitHub baseline branch and immutable source ZIP in an access-controlled archive. Any later changes to endpoints require a separate change journal and independently tested rollback. An unchanged computer snapshot is not proof of successful imaging or maintenance.

## Visual identity

Use David Tom Official branding, the published DTO color tokens and public contact only. The original approved DT header artwork is now verified and bundled unchanged for reports. Remaining icon variants still require their own integration and review. Do not invent a replacement logo or re-export typefaces for redistribution. Keep muted gold decorative, with navy for text/focus against light surfaces.
