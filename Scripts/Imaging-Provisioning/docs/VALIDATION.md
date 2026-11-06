# DTO 0.2.0 validation scope

The current scripts have dedicated dependency-free PowerShell checks for parsing, default privacy, opt-in identifiers, malformed/empty/partial evidence, row/byte limits, safe HTML, image path restrictions, image metadata and hash behavior. A Windows-only native test creates a tiny synthetic-data WIM on a disposable runner, inspects index 1, and checks that its hash did not change. This is not an operating-system image test.

Fresh execution results are recorded in a separate dated checkpoint receipt; tests existing in source alone do not establish a pass. A green CI run applies only to its exact commit. A later documentation-only checkpoint must record which source hashes remain identical to that tested commit.

The source package has 12 allowlisted files plus MANIFEST.json. Python tests cover reproducibility, content tampering, identity/promotion refusal, extra archive members, excluded local reports, missing sources and DTO branding consistency. Verification is content checking, not publisher trust or deployment acceptance.

Still open: actual Windows 11 workstation runs, real licensed OS WIM coverage, administrative privilege/error-path behavior across supported systems, PowerShell 7 DISM compatibility on workstations, target-image compatibility, installer/image/recovery execution, full WPF migration and attended accessibility. Provider timeout is not a process deadline. DISM may write diagnostic logs. These limits remain visible even after automated passes.
