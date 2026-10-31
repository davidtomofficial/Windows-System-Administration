# Windows System Administration — Portfolio Site TODO

**Roadmap status:** Planned and tracked; not a live website.  
**Last reviewed:** 2026-10-31.  
**Audience:** Recruiters/hiring managers, Windows/endpoint engineers, and reviewers of technical work.  
**Primary career site:** https://davidtomofficial.com  
**Source repository:** https://github.com/davidtomofficial/Windows-System-Administration

> **Mission:** Turn this repository into an honest, usable, visually polished **Windows systems administration project portfolio**. The site demonstrates *how problems are solved* through implementation, safe interactive examples, documentation and reproducible evidence. It does not administer any visitor's device or represent a production Windows management service.

## 0. Current reality — do not confuse draft with shipped

- `main` currently contains foundation documentation, design outlines and historical firewall reference exports. It has **no deployed portfolio site files** and no operational workstation launchpad.
- [PR #1](https://github.com/davidtomofficial/Windows-System-Administration/pull/1) proposes repository/source-history reconciliation and ignore rules. **Draft, not merged.**
- [PR #2](https://github.com/davidtomofficial/Windows-System-Administration/pull/2) proposes two actual read-only PowerShell module commands, tests and quality CI. **Draft, not merged**, stacked on #1.
- [PR #3](https://github.com/davidtomofficial/Windows-System-Administration/pull/3) improves inventory privacy and hostname validation. **Draft, not merged**, stacked on #2. [Run 41240883962](https://github.com/davidtomofficial/Windows-System-Administration/actions/runs/41240883962) passed 53 tests each in Windows PowerShell 5.1 and PowerShell 7 on GitHub-hosted Windows Server runners. This **does not** prove Windows 11 physical/enterprise lab validation.
- GitHub Pages activation and a publicly reachable project-site URL **have not been verified**. Do not advertise an expected URL as live.
- The site must not link to/download historical firewall exports until privacy, ownership, and publication approval are resolved. Review history as well as working files.

## 1. Release definition: what makes the MVP *functional*?

The first portfolio release is a **static, accessible GitHub Pages site** — not a login system, Windows remote management web portal or executable administration service. For version `site-mvp-1`, **every item below is required**:

- [ ] **Reachable:** Approved site deployed over HTTPS from a reviewed `main` commit; correct GitHub project-path routing and a working home page.
- [ ] **Understandable in 60 seconds:** Hero states focus, scope, status and links to source, demonstrations and contact/profile.
- [ ] **Evidence-backed:** At least **two complete project case studies** (local inventory and offline name planning), with source/tests/CI links and clear limitations.
- [ ] **Interactive:** A client-side *synthetic* computer-name planning demo works offline, with validation feedback, copy/reset and no device/network access.
- [ ] **Navigable:** Responsive Overview, Projects, Interactive Lab, Documentation/Architecture, Verification, About/Contact sections.
- [ ] **Accessible:** Keyboard navigation, skip link, focus styles, labels, readable contrast and reduced-motion support; automated and manual accessibility checks recorded.
- [ ] **Safe:** No secrets, private endpoints, sensitive exports, credentials, analytics by default, production device identifiers, employer-owned code or unreviewed screenshots in the publish artifact.
- [ ] **Honest:** Features visibly marked `implemented`, `CI verified`, `lab pending` or `planned`. No simulated result masquerades as a real scan.
- [ ] **Reproducible:** Pull requests run site checks without publishing; approved `main` pushes can deploy; failures and rollback steps documented.
- [ ] **Reviewed:** Links, privacy, content, Windows claims, Pages security, and mobile/desktop checks have a dated release record.

**MVP exclusions:** No Windows commands in the browser, real inventory collection, RDP/WinRM, AD/Entra/Intune authentication, arbitrary script execution, customer portal, accounts, database, checkout, unsolicited data collection, production fleet access or automatic downloads.

## 2. Central issue tracker

| Priority | Issue | Workstream | State |
| --- | --- | --- | --- |
| P0 | [#4: Publication/evidence gate](https://github.com/davidtomofficial/Windows-System-Administration/issues/4) | Historical privacy, provenance, claims, PR #1–#3 review | Open |
| P0 | [#5: Positioning and content](https://github.com/davidtomofficial/Windows-System-Administration/issues/5) | Audience journeys, sitemap, claim ledger, narratives | Open |
| P1 | [#6: Static site scaffold](https://github.com/davidtomofficial/Windows-System-Administration/issues/6) | Responsive layout, assets, local preview, navigation | Open |
| P1 | [#7: Case studies and evidence](https://github.com/davidtomofficial/Windows-System-Administration/issues/7) | Inventory and name planner with source/test links | Open |
| P1 | [#8: Synthetic interactive demo](https://github.com/davidtomofficial/Windows-System-Administration/issues/8) | Browser-only, bounded name planning, fixtures | Open |
| P1 | [#9: CI and Pages delivery](https://github.com/davidtomofficial/Windows-System-Administration/issues/9) | Preview checks, least-privilege main-only deployment | Open |
| P1 | [#10: QA/release gate](https://github.com/davidtomofficial/Windows-System-Administration/issues/10) | Accessibility, performance, privacy, link review | Open |
| P2 | [#11: Expanded lab showcase](https://github.com/davidtomofficial/Windows-System-Administration/issues/11) | Additional independently validated Windows topics | Open |

The issue descriptions hold detailed acceptance criteria. **Issue creation is not task completion.** Close a ticket only after the linked code/documentation and validation evidence are verified. Keep this file aligned with actual issue state.

## 3. Sequenced implementation checklist

### Phase A — truthful content and safe publication (P0; issues #4, #5)

- [ ] **A01** Decide which materials can be publicly shown, privately summarized, or must be excluded; audit firewall exports and Git history.
- [ ] **A02** Establish ownership/license decisions for current, historical and third-party content. Preserve original legal notices.
- [ ] **A03** Review stacked [#1](https://github.com/davidtomofficial/Windows-System-Administration/pull/1) → [#2](https://github.com/davidtomofficial/Windows-System-Administration/pull/2) → [#3](https://github.com/davidtomofficial/Windows-System-Administration/pull/3) in order; do not claim merged code from `main` while drafts remain open.
- [ ] **A04** Create a **claim/evidence register** per showcased feature: feature, source commit, test type, CI run, real lab state, privacy review, last verification.
- [ ] **A05** Position the site as an *independent portfolio demonstration* of Windows endpoint administration, scripting and engineering — not as an employer system or a David Tom Solutions product.
- [ ] **A06** Define recruiter journey (<60 seconds to understand skills), technical journey (source and tests within two clicks) and operator journey (prerequisites/limitations within two clicks).
- [ ] **A07** Select design tokens and assets consistent with the approved branding on davidtomofficial.com; confirm actual brand treatment before copying it.
- [ ] **A08** Draft safe case-study narratives and synthetic example outputs; avoid unsupported fleet scale, time-savings, uptime or security claims.

**Gate A:** Approved/public-safe content and a traceable set of claims. The site may be developed privately on a draft branch with invented fixtures while approval is pending, but must not publish unapproved material.

### Phase B — site foundation (P1; issue #6)

- [ ] **B01** Put site source in `site/`; preserve the existing case-sensitive `Docs/` directory for technical documentation. Do not try to publish `Docs/` directly as Pages' lowercase `/docs` source folder.
- [ ] **B02** Build semantic single-page MVP with hero, sections, project cards, demo panel, evidence/status links and footer.
- [ ] **B03** Implement responsive CSS for 320px+ screens, desktop, print styles if useful, and a restrained dark/light palette.
- [ ] **B04** Add visible focus styles, keyboard-reachable navigation, accessible labels, skip-to-content, semantic headings and reduced-motion handling.
- [ ] **B05** Add real outbound calls to action: [portfolio](https://davidtomofficial.com), [GitHub](https://github.com/davidtomofficial), [LinkedIn](https://www.linkedin.com/in/davidtomofficial), repository, and a contact method already present on the personal portfolio (do not invent an address).
- [ ] **B06** Ensure local preview plus URL-prefix-safe paths: the expected default Pages project URL *after activation* is `https://davidtomofficial.github.io/Windows-System-Administration/`. No root-only `/assets/...` links.
- [ ] **B07** Keep core copy visible without JavaScript; avoid a framework, external web fonts, tracking scripts or backend unless a concrete need arises.
- [ ] **B08** Create a small, documented content-update path so new validated modules can become new cards without rebuilding the site architecture.

**Gate B:** Locally previewable, complete navigation with truthful placeholders. No public launch assertion.

### Phase C — show working engineering, not just screenshots (P1; issues #7, #8)

- [ ] **C01** Case study **Read-only Inventory**: problem, CIM classes/query scope, opt-in identifiers, data schema, errors, sample synthetic result and source link.
- [ ] **C02** Case study **Offline Computer-Name Planning**: problem, bounded range/list inputs, deterministic output, deduplication, edge cases, tests and source link.
- [ ] **C03** Explain architecture: small reusable PowerShell module, Pester synthetic tests, parser/static analysis, Windows PowerShell 5.1 vs PowerShell 7 CI, and optional host smoke tests.
- [ ] **C04** Display scope badges accurately: `preview`, `CI verified`, `Windows 11 lab pending`, `not production`. Every badge/status needs evidence and a reviewed date.
- [ ] **C05** Create a **browser-only naming demo** reproducing the module's conservative naming contract: 1–15 ASCII characters, at least one letter, internal hyphens, case-insensitive deduplication, prefix/range/padding, and hard 256 target cap.
- [ ] **C06** Validate the *whole selection before any output*, with no partial results on errors. Include final-newline and wildcard test fixtures.
- [ ] **C07** Add clear errors, reset/copy controls and optional synthetic-only CSV/text download. Do not retain input beyond the current page/session.
- [ ] **C08** Optionally add a *fictional* inventory viewer with an identifier privacy toggle. Label it an example, not a visitor scan.
- [ ] **C09** Review cross-language fixture results against the PowerShell contract; note that browser JavaScript and the Windows module are separate implementations.

**Gate C:** Two evidence-backed stories and one visibly functioning, local-only interactive demo, with zero network management calls.

### Phase D — build, quality and controlled publishing (P1; issues #9, #10)

- [ ] **D01** Add a separate GitHub Actions website workflow, independent from `.github/workflows/powershell-ci.yml`.
- [ ] **D02** On pull requests: validate static assets, tests/fixtures, HTML semantics and internal links; produce a **preview build only**, no production deployment.
- [ ] **D03** On approved pushes to `main`: upload the reviewed static artifact and deploy with the official GitHub Pages Actions flow and least-privilege token permissions. Pin actions to reviewed SHAs or use approved dependency governance.
- [ ] **D04** Configure **Settings → Pages → Source: GitHub Actions** when ready. Verify the actual site URL and HTTPS before sharing it. No custom DNS/CNAME by default.
- [ ] **D05** Add automated JavaScript test cases for demo validation, and link/static-site checks. Keep PowerShell CI as its own quality gate.
- [ ] **D06** Run automated accessibility checks plus manual keyboard/screen-reader checks; target WCAG 2.2 AA-relevant practices and record findings.
- [ ] **D07** Test small phone/desktop layouts, Chromium/Firefox, main flows, page links, no-JS content, reduced motion and 404 handling.
- [ ] **D08** Validate metadata: page title, description, proper headings, social preview, canonical URL only after live URL verification, and a small sitemap only if appropriate.
- [ ] **D09** Audit emitted Pages artifact for secrets, historical exports, production identifiers, accidental outbound requests, unsupported claims and unnecessary asset bloat.
- [ ] **D10** Measure performance with real tests; optimize images/CSS/JS before adding animation or other cosmetic effects.
- [ ] **D11** Document safe rollback to the last approved deploy and test failure handling.
- [ ] **D12** Record shipped commit, CI/deployment run URLs, observed site URL, test date, exceptions and reviewer in a site release record.

**Gate D:** An accessible, secure, verified public MVP with reproducible deployment and rollback. **Only after Gate D** should the project be linked as a live showcase on davidtomofficial.com or LinkedIn.

### Phase E — deepen the portfolio after MVP (P2/P3; issue #11)

- [ ] **E01** Add architecture diagrams, troubleshooting runbooks, and an explainable design-tradeoffs section.
- [ ] **E02** Add additional **authorized, independently authored and tested** modules such as bounded AD inventory, GPO reporting, WEF health, backup/restore verification, DHCP export or workstation readiness — each with lab results.
- [ ] **E03** Showcase role-based engineering concepts (least privilege, failure handling, safe retries, idempotency, validation evidence) through implemented examples, not broad capability claims.
- [ ] **E04** Add an evidence-led skill matrix (PowerShell, Windows, endpoint management, automation, security fundamentals, CI), with citations to work or credentials where appropriate.
- [ ] **E05** Add search/filtering for projects **only after** multiple substantive case studies exist; avoid empty category pages.
- [ ] **E06** Consider theme switch, short walkthrough clips, downloadable sanitized PDF case study and versioned release notes, if they measurably improve reviewer use.
- [ ] **E07** Link related approved personal projects and portfolio content without copying David Tom Solutions / Publishing source into this repository.

**Gate E:** Expansion pages have the same evidence, privacy and accessibility standards as the MVP.

## 4. Proposed repository layout (planned, not yet created)

```text
Windows-System-Administration/
├── README.md                      # repository developer entry
├── PORTFOLIO-TODO.md              # this tracked backlog
├── Docs/                          # existing technical documents
├── Modules/                       # proposed by draft PR #2
├── Tests/                         # proposed by draft PR #2
├── .github/workflows/
│   ├── powershell-ci.yml          # proposed by draft PR #2
│   └── portfolio-pages.yml        # future site checks + deployment
└── site/                           # future static Pages artifact root
    ├── index.html
    ├── 404.html                    # if necessary
    ├── assets/
    │   ├── styles.css
    │   └── app.js
    ├── demos/
    │   └── name-planner.js
    └── fixtures/
        └── synthetic-inventory.json
```

**Architecture decision:** Prefer static HTML/CSS and minimal JavaScript for the first version. This site is a presentation and educational demo; privileged Windows actions remain in explicitly reviewed PowerShell, outside the browser. A future framework/build system should be justified by tested requirements rather than introduced automatically.

## 5. Site content requirements: each project card

Every implemented project should show:

1. **Problem and context:** What issue is being addressed, without private employer information.
2. **Your implementation:** Main design decisions, language/tools and a short reviewed snippet.
3. **What actually works:** Scope, commands and operational effect, with implementation link.
4. **Evidence:** Source SHA, tests, workflow/run, relevant lab matrix and last verified date.
5. **Safety and limitations:** Permissions, errors, identifier handling, what it does *not* do.
6. **Try it:** Synthetic demo or safe local reproduction steps where appropriate.
7. **Next milestone:** One scoped planned enhancement, separately labeled.

Never use a default “100% secure,” “enterprise ready,” “production proven,” “deployed at scale,” or “Windows 11 validated” label without supporting evidence. Screenshots and invented demo data must be clearly distinguished from observed results.

## 6. Explicit dependencies and blockers

| Dependency / risk | Affects | Handling |
| --- | --- | --- |
| Draft #1 → #2 → #3 unmerged | Code on `main`, trustworthy links/status | Preserve branch chain; show draft status until reviewed |
| Firewall exports and history contain potential identifying material | Portfolio privacy, public source links | Review before reusing; no direct export links; no irreversible history action without approval |
| License and ownership undecided | Reuse of historical content | Independently author samples and publish only permitted content |
| GitHub Pages settings not verified | Live URL and HTTPS claims | Verify through Settings/deploy run at launch |
| Website branding cannot be assumed from a repo README | Visual consistency with davidtomofficial.com | Inspect actual approved branding before final theme |
| Hosted Windows Server CI is not representative Windows 11 lab | Compatibility and production claims | Keep separate evidence/status layers |
| Site demos are client-side simulations | User expectations | Label clearly and prohibit remote/device requests |

## 7. Resume and career impact (after evidence exists)

After the site is live and tested, the defensible portfolio description is:

> Built a static, accessible Windows systems administration project site featuring independently authored PowerShell examples, source-linked test evidence, and a client-side synthetic demonstration of bounded host-name planning.

Add measured outcomes only when captured. Include a prominent link from davidtomofficial.com only after verifying the live URL. Never imply the public demo runs privileged management tasks.

## 8. Handoff contract for future agent/refinement runs

1. Read this TODO plus current GitHub Issues, open PRs, `README.md` and `Docs/Provenance.md` (when PR #2 lands). Confirm actual branch/release states.
2. Select the **highest-priority unblocked** issue; implement the smallest coherent milestone in a feature branch with a draft PR. Prefer independent site changes based on `main` to avoid stacking further on #3.
3. Never merge, enable Pages, change DNS, release a product, or publish historical/private data implicitly. Request appropriate approval for real deployment or settings changes.
4. Test code and record the **exact** outcomes, not assumptions. Mark pending checks honestly, distinguish synthetic evidence from live host/lab evidence, and never advertise site URLs that were not visited successfully.
5. Update issue checkboxes, case-study status, this document and any relevant release record as work is verified; close an issue only after acceptance criteria are met.
6. Keep dependencies pinned, privileges minimal, demos local-only, and no telemetry unless deliberately reviewed and disclosed.

### Reference guides

- [GitHub Pages: configuring a publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [GitHub Pages: creating a site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
- [GitHub: managing a custom domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
