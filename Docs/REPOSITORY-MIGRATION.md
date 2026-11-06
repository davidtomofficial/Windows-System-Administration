# Repository migration map — November 5, 2026

## Current publication and preservation check

The source integration was published to `main` at `bc80d476327bcb072e57c38a4cb97c18220865b9` after successful Windows Server CI run [42149193243](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/42149193243). The 144,730-byte source/prework ZIP was uploaded to the restricted SharePoint Windows-System-Administration folder and downloaded with matching SHA-256 `f0432a7fbf44280911241b73a3b196470a4a94af583377e2534124d9f0b0ee1d`. Source archive has 53 reviewed members. Later documentation-only changes do not retroactively change the tested code's identity; inspect HEAD for newest documentation.

The 2026-11-05 SharePoint DeviceCare, Imaging, Launchpad, Windows administration and joint-master TODO files were synchronized with current task IDs and latest status; 15 text-file readbacks matched exact intended bytes. Separate private GitHub source preservation should still be reviewed against the existing dual-backup policy; public main plus SharePoint source ZIP are the completed source copies here.

## Scope and preservation

User-directed review under DTO-GH-001 and DTO-WSA-001/037/040. Integration begins from DeviceCare commit `3ce2a915c20a2d6bb504280b2171cf7a3d5ce9b9`; the main preimage is `ffa5e134dedee3ee3e56f7d9aab202cff3b5cfe0`, retained by `backup/repository-review-main-20261105`. Original feature and Imaging branches remain intact. No force push, repository rename, visibility change, transfer, deletion or history rewrite is part of this pass.

| Before | Integration destination | Change boundary |
|---|---|---|
| DeviceCare + Launchpad feature branch | Same maintained paths in the integration tree | Existing source retained; documentation, permission notice and package inclusion refined |
| Separate Imaging branch at `173cda83ef639f16a7a5acf641f350bca79c7cca` | `Scripts/Imaging-Provisioning/` | Public preview subtree copied from tree `4f9b0cc91aaf046b002bed6d748a5e4751192e4a`; runtime preserved, source branch retained |
| Root foundation README | `Docs/archive/README-foundation-2026-09-26.md` | Original bytes preserved; new root becomes a truthful review entry point |
| Original Launchpad outline | `Launchpad/DESIGN.md` | Original bytes retained; new README reflects the implemented planner only |
| Scattered TODO/evidence | Linked root review routes and `Docs/REPOSITORY-REVIEW-TODO.md` | Existing task IDs remain authoritative; no unsupported completion claims |

The integration branch uses both source commits as parents so the Imaging history remains reachable. Existing unrelated drafts remain separate. Old archived documents retain their original relative-link context and are not current navigation authorities.

## Account-level inventory and disposition

The connected account exposes six public personal repositories and a separate private preservation repository. The private repository is not part of the public migration.

| Public repository | Source-derived classification | Decision |
|---|---|---|
| `davidtomofficial/davidtomofficial` | Personal profile, existing GPLv3 LICENSE | Retain identity and current license; improve a curated project index separately |
| `Windows-System-Administration` | Current toolkit development plus historical foundation/reference files | Consolidate the two current previews and planner in one reviewable tree; do not imply release readiness |
| `Python` | README labels historical educational projects; GPLv3 statement and a v3-or-later file notice | Academic archive candidate; preserve existing grants and file attribution |
| `SQL` | README labels historical coursework with GPLv3 statement | Academic archive candidate; preserve database examples and existing terms |
| `cpp-Examples` | README labels historical coursework/practice with GPLv3 and third-party attribution | File-by-file provenance review before copying into any archive; no relicensing |
| `Web-App-Development` | Historical coursework and an early prototype, with third-party media/context | Separate academic/prototype inventory; do not publish or deploy old applications |

This is a metadata/README-level classification, not a full audit of every file, branch, dependency, release or historical commit. A proposed future academic archive is not represented as created. No school files are moved until contributor/course/media rights and link/history impacts are reviewed. Existing security-lab exclusions and deferred historical cleanup remain in force.

## Open draft work

PR #1 has source-history/exclusion housekeeping; #2 and #3 contain a separate module and inventory refinement; #12 and #16 contain old portfolio-site planning/scaffolding. Preserve their review state. Reconcile useful generic code only after rights, current source and tests are reviewed. All future website delivery follows the owner's WordPress-only direction, not old Pages plans.

## Restore

Revert only this integration's scoped changes, or return to the preserved prior source branches. Do not erase later work, change repository visibility, rewrite history or delete the original drafts to simulate rollback. Fresh-read branch heads before every update.
