# Contributing

Use a feature branch and a draft pull request. Keep a change small enough to review and distinguish implementation, mocked test coverage, hosted-runner checks, and actual lab validation. Do not merge, release, or deploy merely because a test passes.

## Scope and provenance

Keep examples generic and fixtures synthetic. No DTS/DTP software, installers, integrations, employer-specific source, real device/user records, tenant configuration, recovery keys, credentials, or signing keys. Review [Provenance.md](Docs/Provenance.md) before importing any historical code. Licensing is unresolved; do not assume that a public repository grants redistribution rights.

Read-only operations must not repair, enroll, update, or restart as a side effect. Future change operations need explicit targets, prerequisite checks, SupportsShouldProcess where appropriate, documented failure/partial outcomes, and lab acceptance. Never use arbitrary command execution as configuration or solve signing/dependency failures by a blanket execution-policy bypass.

## Development tools

On your authorized Windows development machine, review and install the exact versions in [Tools/TestDependencies.psd1](Tools/TestDependencies.psd1). These are development dependencies, not prerequisites installed by the runtime module:

~~~powershell
$versions = Import-PowerShellDataFile .\Tools\TestDependencies.psd1
foreach ($name in $versions.Keys) {
    Install-Module -Name $name -RequiredVersion $versions[$name] -Repository PSGallery -Scope CurrentUser
}
.\Tools\Test-Repository.ps1
~~~

Use a session allowed by your organization's execution/signing policy. PowerShell 7 testing requires 7.4+ for the pinned Pester release; Windows PowerShell 5.1 is also tested by the workflow. Do not silently accept an unexpected repository/publisher prompt. The CI workflow sets PSGallery trust only inside its disposable runner and installs dependencies there; the test script itself does neither.

## Quality contract

The script parses PowerShell source and tests, analyzes Modules/, Scripts/, and Tools/ with zero PSScriptAnalyzer errors/warnings, runs Pester, and requests at least 80% command coverage of the first module. Pester test doubles are parsed but excluded from production-source linting. Generated XML goes to ignored TestResults/; coverage is a testing aid, not a security assurance.

-IncludeRunnerSmoke explicitly enables real, local, read-only CIM collection. CI runs it on disposable Windows Server runners in both powershell and pwsh jobs. Do not put production-host or tenant data in CI. No inventory artifacts are uploaded.

Before submitting, run git diff --check, inspect the full diff for private data, update the operator guide, and provide positive/negative tests. Commit the smallest coherent set. A passing unit test must never be described as a successful AD/GPO/Intune or Windows 11 deployment.

## Review and releases

The stable aggregate CI check is PowerShell quality. Recommend requiring it on main only after it exists and passes. Do not require an unavailable second reviewer on a solo-maintained repository. Branch settings, license selection, releases, and merges require the maintainer's separate decision. See [Lab-Validation.md](Docs/Lab-Validation.md) for evidence needed before promoting a preview.
