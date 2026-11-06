# Technician migration and cleanup — implementation requirements

Reference check: 2026-11-05. This is design/research, not an enabled action or a verified device workflow. Track WSA-011..018 and LP-012/013.

## Windows 10 to Windows 11

1. Identify exact source edition, release/build, architecture, language, activation/entitlement, management owner and intended target. Do not map unknown editions to Home/Pro. Windows 10 general support ended October 14, 2025; LTSC/LTSB and ESU must be assessed by exact edition/enrollment, not one blanket date.
2. Record hardware, firmware, TPM, Secure Boot capability, supported processor, storage and app/driver prerequisites from current Microsoft guidance. A local minimum check is not a complete compatibility verdict. No unsupported bypass path.
3. Confirm recoverable data/device backup, encryption and recovery-key custody without exporting keys into reports. Identify local-only and cloud-pending data. An in-place upgrade is not a backup, and USMT is not an image or an application installer.
4. Review target release health and safeguards. Windows Update safeguards do not automatically protect media/WSUS deployment; separately assess known issues before alternate channels. Never use an alternate channel just to evade a hold.
5. Offer an explicitly selected compatibility scan using the exact Windows Setup media and supported `/Compat ScanOnly` route. Explain diagnostic file writes and any dynamic-update/network choice. Normalize native unsigned exit codes: 0xC1900210 means that scan found no compatibility concern; 0xC1900208 concerns an actionable compatibility block; 0xC1900204 migration choice; 0xC1900200 requirements; 0xC190020E free space. Preserve unknown/unexpected outcomes and sanitized log references. No code grants overall upgrade authorization by itself.
6. Only after separate native qualification implement reviewed upgrade execution, interruption handling, restart choice and recovery. Retain rollback material until retention approval; do not delete Windows.old to make room without a separate decision.
7. Postflight independently checks OS/edition, activation, user sign-in/data, drivers/peripherals, applications, update ownership and management processing; record remaining issues and human handoff.

## Profiles and stale data

Start with a read-only plan. Observe Win32_UserProfile SID, LocalPath, Loaded, Special and LastUseTime; label unavailable/invalid information. Do not equate profile age, folder timestamps or missing account resolution with disposable data.

Never preselect current, loaded, special, service, shared, protected or uncertain profiles. Identify all relevant sessions and profile-container/roaming arrangements. Show why every candidate is included/excluded, with reviewable private paths and pseudonymized public examples. Do not recursively read user contents merely to list profiles.

A future removal action requires exact target identity, retention/owner approval, verified backup/restore, cloud-sync and encryption review, fresh session/loaded-state recheck and explicit final confirmation. Use the documented Windows profile lifecycle rather than deleting just a folder or registry key. Record failures and remaining state without claiming transactional undo. Stop on identity drift or new sessions.

Data cleanup is separate: user-selected scope, symlink/junction/cloud-placeholder exclusions, conservative space estimates and exact previews. Preserve Downloads, Recycle Bin, rollback files, restore points and diagnostic records by default. No silent bulk delete, no recursive traversal into another volume, no disk wipe from routine cleanup.

## Acceptance cases

Migration: supported/unsupported/unknown edition; managed/unmanaged; held/unknown compatibility; insufficient space; incompatible apps; denied scan; diagnostic-only scan; localized logs; unsigned native error normalization; offline and interrupted runs; recovery and actual postflight.

Profiles: old-but-active, loaded/special/current/shared, unresolved SID, missing/invalid last-use, roaming/container, pending cloud upload, encrypted files, inaccessible backup, junctions, identity changes and new sessions during review. Until the execution journal and independent restoration evidence exist, all removal actions remain disabled.

## Official references

- Microsoft Windows 10 lifecycle announcement: https://learn.microsoft.com/en-us/lifecycle/announcements/windows-10-end-of-support
- Supported Windows upgrade paths: https://learn.microsoft.com/en-us/windows/deployment/upgrade/windows-upgrade-paths
- Windows safeguard holds: https://learn.microsoft.com/en-us/windows/deployment/update/safeguard-holds
- Windows Setup command-line options: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11
- Setup compatibility logs: https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/use-windows-setup-compatibility-scan-logs-to-identify-blocking-issues
- Win32_UserProfile contract: https://learn.microsoft.com/en-us/previous-versions/windows/desktop/userprofileprov/win32-userprofile
- User State Migration Tool overview: https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-overview

Refresh these sources when implementing an action. The conservative approval/exclusion rules above are project design decisions, not claims that Microsoft requires this exact workflow.
