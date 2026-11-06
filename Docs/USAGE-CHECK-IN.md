# Required periodic usage check-in — implementation contract

**Owner requirement recorded November 5, 2026. Current runtime status: NOT IMPLEMENTED.**

The owner requests periodic check-ins so usage frequency of DeviceCare, Imaging and the eventual technician launchpad can be tracked. This is a new future-licensed-build requirement. Earlier local-only/no-telemetry descriptions accurately describe the existing previews; they are not evidence of a deployed check-in service. No endpoint, credentials, background service, scheduled task or network call is activated by this document.

## Release requirement

Future permission-licensed distributed builds must support a disclosed check-in to an owner-controlled, authenticated collector and clearly display its status, last successful receipt and next due time. This requirement must not be imposed retroactively on GPL-covered or separately licensed versions. Required license validation and optional detailed diagnostics are distinct: the former never implies authorization to upload device reports.

The draft policy is in [Config/check-in.policy.example.json](../Config/check-in.policy.example.json). It is deliberately disabled and has no endpoint; the current programs do not load it. The collector location, terms, cadence and retention still require concrete deployment decisions. No guessed WordPress route is a working API.

## Proposed operating defaults, not a deployed schedule

Check once on first authorized enrollment, then at most once per 24 hours while the program is actually used. Aggregate product launches and approved task invocation counts between receipts; an occasional heartbeat alone does not measure usage frequency. A seven-day entitlement renewal with a fourteen-day offline grace period is a proposal for review, not an approved contract term. Do not install a wake-up service solely to record inactive machines.

Each approved offline/air-gapped arrangement needs a separately issued, scoped offline entitlement and a truthful reporting limitation. After expiry, future protected actions may be refused before they start; already-running servicing, recovery, user data access, export and uninstall must not be interrupted or sabotaged by a check-in failure. No remote command execution, remote wipe, stealth persistence or emergency kill behavior.

## Minimal data and transparency

Allow only product ID, version, random installation/enrollment ID, coarse UTC usage window, bounded aggregate counters, schema/terms version and receipt/deduplication identifiers. Do not use serials, MACs, hardware fingerprints, usernames, emails, domain/tenant names, paths, file contents, installed-app inventories, recovery keys or raw diagnostic logs. Counts may still be identifying when tied to enrollment. The receiving host sees transport metadata such as IP addresses; configure access-log minimization, access control and retention rather than claiming complete anonymity.

Show the exact destination, purposes, required fields, frequency and applicable agreement before enrollment; authorized operators must be able to inspect the pending payload. Refusing required enrollment means no permission-licensed operational use, not silent collection. Any optional diagnostic submission needs its own explicit selection. Employer/customer systems require their own authorization; the owner's development request is not end-user or organizational consent.

## Collector/client requirements

HTTPS with normal certificate validation; exact allowlisted destination; no secrets embedded in public code; per-install credentials stored with suitable local protection; signed bounded receipts; replay protection and idempotent counters; bounded queue/timeouts/retries with backoff and jitter; clock-change handling; credential rotation/revocation; protected read-only dashboard; deletion and retention process; audit trail and tested restore. Use neither public GitHub issues nor SharePoint direct-upload credentials as a client telemetry channel.

Hosting must comply with the owner's existing WordPress delivery direction. If the verified WordPress service cannot host the receiver, record the precise missing capability and obtain approval for any architecture/provider change. Do not buy infrastructure, publish an endpoint or create a new tracking account implicitly.

## Required tests and evidence

Enrollment disclosure/assent; accepted and refused entitlement; fresh/stale receipt; offline grace and expiry; clock rollback; no mid-task interruption; no collection before enrollment; duplicate retries counted once; network/permission/proxy failures; credential scope/rotation; unauthorized dashboard denial; minimization/retention; uninstall/opt-out behavior for optional data; receiver restore; real authorized end-to-end receipt and dashboard aggregation. Tests with a mock receiver do not establish deployed tracking.

## Task cross-reference

DTO-GH-001: repository license/discovery. DTO-WSA-041..048: implementation backlog in [repository review TODO](REPOSITORY-REVIEW-TODO.md). DTO-DC-021, DTO-IMG-014 and DTO-LP-023 link each product to the common check-in contract. No runtime gate is claimed by adding these rows.
