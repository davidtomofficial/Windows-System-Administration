# Validation — DTO DeviceCare 0.2.0 continuation

## Verified prior baseline

Commit `3f62035b67293e937eb1b693433e1cec16b8f710`, Actions run `42141845609`: 49 Windows PowerShell 5.1 checks including native read-only observations, 44 PowerShell 7 checks, nine Python packaging tests. Those results belong to 0.1.0 only.

## Earlier 0.2.0 component checks

Twelve local Python checks pass: deterministic packaging, manifests and tamper refusal, extra-file exclusions, identity boundaries, asset byte identity, version alignment and offline report structure. Added PowerShell cases cover pre-rounding thresholds, exact Boolean flags, projected extra-field exclusion, known states, approved artwork and useful report structure. Windows run 42145612233 at commit deadfd6add0fb391dd3113e6fd9cfd501e8a7603 passed 65 Windows PowerShell 5.1 checks including native observations, 60 PowerShell 7 contract checks, 12 DeviceCare Python checks and 12 separate Launchpad planning checks. Do not add earlier or overlapping runs to these totals.

The report is a string returned to the caller. This increment neither writes reports nor opens browsers, starts installers, deletes profiles, changes services or calls a network. Asset checks detect changed bytes; they are not a signature or an authorization mechanism. Rendered sample evidence uses synthetic observations.

Windows Server CI is not attended Windows 11 acceptance. Native desktop WPF, keyboard/Narrator/High Contrast, actual maintenance, installer lifecycle, upgrade/cleanup, recovery and full historical application integration remain open. Per-call CIM timeouts still do not guarantee a total wall-clock deadline.

Local browser inspection was blocked by the browser file-URL policy. A synthetic template fixture was prepared, but no desktop/mobile/High Contrast visual or attended accessibility pass is claimed.

## DTO-DC-016 boundary regression verification

**November 6, 2026: complete within the boundary regression scope.** [PR 18](https://github.com/davidtomofficial/Windows-System-Administration/pull/18) adds the missing equality and just-over checks and extends the just-under checks to configured thresholds. The implementation already compared raw measurements correctly; application runtime files are unchanged.

Test-source commit `175ec34405ba768d819e660425154e8e79217707` passed [Windows integration run 42281513012](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42281513012). This pull-request run checked out synthetic merge `ea6e9aeae1af3027386535b6496d0bbdb91d66ea` against base `17e384a0cd03c37ec2725590fd4d54b0c0155590`. The host was Windows Server 2022. Results are separate suite totals, not a combined count of unique acceptance cases:

| Suite | Passed | Runtime / scope |
|---|---:|---|
| DeviceCare Windows PowerShell | 98 | 5.1.20348.5773; synthetic contracts and native read-only observations |
| DeviceCare PowerShell 7 | 93 | 7.6.9; synthetic contracts |
| DeviceCare packaging | 12 | Python; deterministic packaging, manifest, asset, privacy and tamper checks |
| Repository contracts | 13 | Python; source preservation, package/license inclusion and repository contracts |

The same run also passed the unchanged Imaging suites (87 Windows PowerShell 5.1/native, 77 PowerShell 7 and eight Python checks) and 12 Launchpad planning checks. Imaging native tests used a synthetic text-file WIM, not an operating-system deployment.

### Boundary contract and fixtures

Disk space is `Review` strictly below the selected minimum; equality and above are `Observed`. Memory usage is `Observed` below the selected maximum and `Review` at equality or above. The default minimum is 15 GiB and maximum is 85%; configured fixtures use 20.25 GiB and 72.5%.

| Metric / setting | Below, equal, above raw fixtures | Expected states in order | Rounded display for all three |
|---|---|---|---|
| Disk / default | 15 GiB minus one byte; 15 GiB; 15 GiB plus one byte | Review, Observed, Observed | 15 GiB |
| Memory / default | 84.96%; 85%; 85.04% used | Observed, Review, Review | 85% |
| Disk / configured | 20.25 GiB minus one byte; 20.25 GiB; 20.25 GiB plus one byte | Review, Observed, Observed | 20.25 GiB |
| Memory / configured | 72.46%; 72.5%; 72.54% used | Observed, Review, Review | 72.5% |

Each of the 12 cases gets a fresh synthetic snapshot and checks its literal expected state, rounded display and both effective threshold fields. Default cases omit threshold arguments. Memory fixtures use a total of 100000 and free values 15040/15000/14960 or 27540/27500/27460. The 36 assertions replace three earlier boundary assertions, a net increase of 33 per runtime. Existing unknown-evidence, strict Boolean, privacy, report and no-change checks remain.

### Reproduce from the repository root on an authorized Windows host

```powershell
powershell -NoProfile -File .\Scripts\DeviceCare\tests\Run-Checks.ps1 -Native
pwsh -NoProfile -File .\Scripts\DeviceCare\tests\Run-Checks.ps1
python .\Scripts\DeviceCare\tests\test_package.py
```

The recorded totals are for the CI host above. The harness conditionally checks omission of a default hostname when that environment value exists, so a different host can produce a different total. Follow [the integration workflow](../../../.github/workflows/dto-integration-review.yml) for the full repository gate and its required preserved source parents. Later commits need their own Actions results; the source/run identities above remain this increment's initial execution evidence.

This closes DTO-DC-016 only. It does not establish attended Windows 11, native UI/accessibility, actual maintenance, installation, recovery, a deployed check-in service or A+ acceptance.
