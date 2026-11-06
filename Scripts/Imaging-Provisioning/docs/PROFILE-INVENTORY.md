# Read-only profile inventory

## Purpose and task status

This development preview provides the inventory stage of **DTO-WSA-015**. It reads local Windows profile metadata so an authorized technician can see which observations need further review before planning a migration or cleanup. It does not establish that a profile is abandoned or safe to remove.

The broader task remains open for complete session evidence, account ownership, protected/shared-profile policy and attended Windows 11 acceptance. Profile removal has its own dependencies under DTO-WSA-016 and DTO-WSA-004.

## Authorized development use

Run from the component directory on a Windows host you are authorized to inspect, using the host's normal execution policy:

```powershell
Import-Module .\src\ProfileInventory.psm1 -Force
$profiles = Get-DTOProfileInventory
$profiles | ConvertTo-Json -Depth 8
```

Choose a different age-review threshold or request exact identifiers explicitly:

```powershell
$profiles = Get-DTOProfileInventory -AgeThresholdDays 120 -MaximumRecords 256
# Private operator review only; includes validated SIDs and local paths:
$privateProfiles = Get-DTOProfileInventory -IncludeIdentifiers
```

The defaults are 90 days, at most 256 inspected records and a five-second CIM operation timeout. `MaximumRecords` accepts 1 through 1024; `OperationTimeoutSec` accepts 1 through 30. `AgeThresholdDays` accepts 1 through 36500. Values at or beyond the threshold receive an age signal based on elapsed ticks, before `AgeDays` is rounded to two decimals.

| Result | Interpretation |
|---|---|
| `Coverage.Status` | Complete, Partial, Unavailable or NoData for this inventory query. |
| `Coverage.Reasons` | Bounded reason codes for missing/uncertain records, query failure, duplicates or limits. |
| `Profiles` | Projected profile observations with per-run numbers and exclusion reasons. |
| `CurrentProcessProfile` | Whether the SID matches the process account; this does not identify the interactive console user. |
| `AgeSignal` | AtOrBeyondThreshold, BelowThreshold or Unknown; never a disposal recommendation. |
| `LastUseStatus` | Observed, Missing, Invalid, Future or TimezoneUnknown. |
| `SessionCoverage` | NotCollected in this increment. |
| `Selected`, `CandidateEligible`, `RemovalAllowed` | False for every record. |

The standalone entry point is `src/Get-DTOProfileInventory.ps1`. The existing offline report can also display the returned object:

```powershell
Import-Module .\src\DTOImaging.psm1 -Force
$html = ConvertTo-DTOReviewHtml -Review $profiles
```

Both examples return data to the caller. They do not save or transmit it. No automatic elevation or execution-policy change is provided. An unavailable provider must remain visible as incomplete evidence.

## Privacy and behavior

The default result omits account SIDs and profile paths. Row labels are local to one collection and must not be used to match identities across runs. Exact identifiers require an explicit option for a private operator review. Review any output before sharing, including metadata that remains sensitive without direct identifiers.

The collector reads only selected `Win32_UserProfile` properties and the current process identity. SIDs are used privately to compare the process account and detect duplicates; `LocalPath` is requested only with `IncludeIdentifiers`. It does not traverse profile directories, inspect user files, resolve account names against a directory, upload results or write a report automatically. The caller may explicitly save a returned result in a destination they control.

Loaded, current, special, roaming and uncertain records retain their observations and review reasons. An unloaded profile is not proof that there are no sessions. `RoamingConfigured` records configuration; it does not prove that this specific profile currently roams. Status zero is Undefined, and unknown status bits remain uncertainty. A missing or invalid last-use date is not an old date. A future timestamp is an uncertainty signal. A DateTime without timezone information, or an ambiguous/invalid local time, stays TimezoneUnknown rather than receiving an assumed age. Profile age does not establish ownership, retention approval, cloud synchronization, encryption state, backup quality or data disposability.

All records remain ineligible for removal. Complete collection means the selected inventory fields were collected within the declared bounds; it does not mean the broader migration or cleanup review is complete.

## Reliability limits

Collection uses a record limit and a 131072-byte budget for the compact JSON of projected records; this budget excludes the small result envelope. A sentinel record detects overflow. The returned coverage state records truncation, malformed data and provider failures; valid observations collected before a later failure remain available. Private provider exception messages are not copied into the result.

The CIM operation timeout is a provider-level bound, not an end-to-end process deadline. Profiles and sessions may change while or after the command runs. The output is a point-in-time observation, not a lock or a deletion plan.

## Validation and continuation

Dedicated profile checks cover privacy defaults, explicit identifiers, malformed values, age boundaries, current/loaded/special/roaming observations, uncertainty, duplicates, collection limits and partial provider failures. Native mode reads the disposable Windows runner's actual profile provider; fixtures exercise cases the runner may not naturally contain. Neither mode removes or changes a profile.

Actual run identities, runtime versions and results belong in [VALIDATION.md](VALIDATION.md). A test file in source does not establish that it ran. Windows Server CI does not establish attended Windows 11, multi-session/RDS, roaming-profile/container, backup/restore or operational deployment acceptance.

Next implementation should add independently qualified session coverage and explicit protected/shared-account policy before introducing any candidate-selection decision. Any later removal workflow also requires exact identity binding, owner and retention authorization, verified backup/restore, sync/encryption checks, a fresh session check, protected execution and confirmed outcomes.

## References

- [Microsoft: Win32_UserProfile class](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/userprofileprov/win32-userprofile)
- [Microsoft: Get-CimInstance](https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance)
- [Repository migration and cleanup requirements](../../../Docs/Technician-Migration-and-Cleanup.md)
- [Current Windows administration task index](../../../Docs/DTO-WINDOWS-ADMIN-TODO.md)

The conservative review rules are project design decisions. The Microsoft references define provider behavior; they do not certify this implementation or authorize a cleanup operation.
