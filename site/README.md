# Windows System Administration — local portfolio preview

**State:** isolated draft website scaffold; not merged into main, not deployed to Pages, and not a Windows management service. Content uses public profile links and synthetic examples. The existing PowerShell work remains in unmerged draft PRs #1–#3. Publication/ownership review is tracked in [issue #4](https://github.com/davidtomofficial/Windows-System-Administration/issues/4).

## Preview with no build dependencies

From the repository root:

    cd site
    python3 -m http.server 8000 --bind 127.0.0.1

Open http://127.0.0.1:8000/. No external libraries, fonts, telemetry, logins, persistent storage or remote management. Serve over HTTP, not file://, because ES modules have file-origin restrictions. The browser needs JavaScript only for the optional lab.

## Test the GitHub Pages project-path prefix locally

From the repository root:

    mkdir -p /tmp/wsa-prefix/Windows-System-Administration
    cp -R site/. /tmp/wsa-prefix/Windows-System-Administration/
    cd /tmp/wsa-prefix
    python3 -m http.server 8001 --bind 127.0.0.1

Open http://127.0.0.1:8001/Windows-System-Administration/. All assets are relative. The expected Pages URL is **not** verified as live.

## Automated checks (Node.js 20+)

    node --test site/tests/name-planner.test.mjs
    node --check site/assets/app.js
    node --check site/demos/name-planner.mjs
    node tools/validate-portfolio-site.mjs

The new PR-only workflow runs checks without deploying. It does not modify PowerShell CI.

## Manual review before merge or publication

- Inspect widths 320px, 375px, 768px and 1280px for overflow, navigation and readable text.
- Use keyboard alone: skip link, nav links, mode switch, form, generate, reset, copy, outbound links; verify focus order and visible focus.
- Test Chromium and Firefox, 200% zoom, reduced motion, no-JavaScript content, and screen-reader labels/errors.
- Inspect browser console/network: no external network requests, PowerShell, remote device access, telemetry or cookies.
- Run automated accessibility tools and a screen-reader smoke test; record versions, results, exceptions. **WCAG 2.2 AA conformance is not certified by these static checks.**
- Review links, claims, historical exports, privacy and source provenance under issues #4, #5, #7 and #10.
- This PR does not activate or deploy GitHub Pages: no deployment workflow, CNAME, DNS edits or release. Document deployment/rollback separately after approval.

## Updating content

Edit narratives and evidence links in site/index.html; update design in site/assets/styles.css; change UI behavior in site/assets/app.js; change pure name validation in site/demos/name-planner.mjs with new fixture tests. The browser demonstration is a separate educational implementation, not PowerShell running on a visitor's computer.
