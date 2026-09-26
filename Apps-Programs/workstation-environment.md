# Windows 11 25H2 Enterprise Workstation Baseline

| Document field | Value |
| --- | --- |
| Baseline version | 1.1 — draft for review |
| Target platform | Windows 11 Enterprise 25H2; Pro 25H2 where licensing and required capabilities permit |
| Architecture | x64; ARM64 requires separate application, driver, and peripheral validation |
| Intended users | General office and administrative staff |
| Deployment model | Common Windows foundation with centrally assigned applications and policies |
| Document reviewed | September 26, 2026 |
| Review cadence | Quarterly and whenever platform, application, or organizational requirements change |
| Production validation | Pending testing and approval in the adopting environment |

## Purpose and baseline philosophy

This document defines a common workstation environment for employees using Windows 11 25H2. It provides a consistent starting point for productivity, communication, web access, file collaboration, device management, and approved remote access.

> **A baseline provides a functional, manageable, and supportable workstation. It does not mean the device is 100% secure.** Security depends on how the device is configured, maintained, monitored, and used, together with the identities, networks, applications, and services it accesses.

The common baseline should be extended with department-specific applications, access permissions, and data-handling requirements. A finance analyst may need SQL reporting access, a legal employee may need Legal Files, and a public safety employee may need an approved PremierOne client. Those needs should be assigned to the appropriate users or devices rather than added to every workstation.

Core protections belong in the initial deployment. Additional controls can be introduced as requirements evolve, but controls required for a department's data or systems must be in place **before access is granted**. Installing this baseline does not establish regulatory compliance or replace a security assessment.

Here, **baseline image** means the documented target configuration. Applications and policies may be provisioned after Windows installation; they do not all need to be embedded in a captured image. This document is a design reference, not an installable Windows image or evidence that a particular device has passed validation.

## Scope and deployment approach

Use this baseline for organization-owned, general-purpose workstations. Shared clinical stations, dispatch consoles, kiosks, privileged administration devices, and other specialized systems need their own validated profiles.

The intended deployment sequence is:

```text
Windows 11 25H2 and approved updates
    → Hardware drivers and firmware
    → Organizational identity and device-management enrollment
    → Core security and configuration policies
    → Common productivity applications
    → Department applications and access controls
    → User configuration, validation, and handoff
    → Ongoing patching, monitoring, and review
```

Microsoft Intune with Windows Autopilot is one possible provisioning approach. Microsoft Configuration Manager, provisioning packages, or an approved imaging process may also be used. Select methods that support the organization's identity, network, licensing, and operational requirements.

Use Windows 11 25H2 with current organization-approved security updates. Record the tested edition, OS build, and update level in deployment records rather than permanently fixing this document to one cumulative update. Review [Windows release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information) and [25H2 known issues](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-25h2) before rollout and during lifecycle planning.

## Core device configuration

The following are proposed minimum expectations for this baseline. The adopting organization must document the actual policy settings, owners, and any approved exceptions.

| Area | Baseline expectation |
| --- | --- |
| Hardware and firmware | Supported Windows 11 hardware, TPM 2.0, Secure Boot enabled, and approved BIOS, firmware, and drivers. Validate docks, displays, cameras, headsets, printers, and other required peripherals. |
| Identity and enrollment | Organization-approved Microsoft Entra ID or Active Directory identity model, correct device ownership, and enrollment in the designated management platform. |
| User privileges | Standard user access for routine work; separate, controlled administrative access. Manage local administrator credentials through Windows LAPS or an approved equivalent. |
| Authentication | Organization-approved sign-in, multifactor authentication for supported organizational services, and automatic session locking. Apply access policies to the systems the user will reach. |
| Disk encryption | BitLocker protection with recovery information stored in an approved, access-controlled location. Verify recovery-key availability before handoff. |
| Endpoint protection | Microsoft Defender Antivirus active and healthy for this proposed baseline, current protection updates, and centrally managed firewall policies. Document any approved replacement protection. |
| Updates | Assigned Windows, application, browser, driver, and firmware update policies, including rollout groups and restart expectations. |
| Data and recovery | Approved storage locations, sharing restrictions, retention requirements, and a tested recovery approach. OneDrive synchronization alone is not the complete backup and recovery plan. |
| Operations | Device inventory, application inventory, management check-in, security monitoring ownership, and a documented support path. |

Detailed hardening policies should be maintained alongside this document in `System-Hardening/`. Evaluate Microsoft's [Intune security baselines](https://learn.microsoft.com/en-us/intune/device-security/security-baselines/overview), test application impact, and resolve overlapping or conflicting settings before broad deployment.

## Software baseline

**Core** means expected on a standard office workstation using this Microsoft 365 model. **Conditional** means assigned when the hardware, role, license, or service requires it. Conditional applications belong in the managed catalog and do not need to be installed on every device.

Use supported, organization-approved releases. Inclusion in this catalog is not a claim that every version or configuration is certified for Windows 11 25H2.

### Management, protection, and hardware

| Application or component | Assignment | Purpose and deployment guidance |
| --- | --- | --- |
| Microsoft Intune Management Extension (IME) | Conditional: Intune-managed devices using features that require it | Supports capabilities such as Win32 app deployment and PowerShell scripts. Let Intune install and update the extension automatically when prerequisites and assignments are met; verify service health and deployment reporting. See [IME guidance](https://learn.microsoft.com/en-us/intune/device-management/tools/management-extension-windows). |
| Microsoft Defender Antivirus | Core | Built-in malware protection. Manage protection settings and updates centrally and verify healthy operation. |
| Microsoft Defender for Endpoint | Conditional: licensed and selected endpoint security service | Provides centrally managed endpoint security capabilities according to the licensed plan. Verify onboarding and reporting; the presence of Defender Antivirus alone does not establish enrollment. See [onboarding guidance](https://learn.microsoft.com/en-us/defender-endpoint/onboard-client). |
| Lenovo Commercial Vantage | Conditional: supported Lenovo hardware | Enterprise-oriented Vantage option for device settings and approved hardware updates. See [Lenovo Vantage guidance](https://download.lenovo.com/pccbbs/pubs/tp_p16_gen1/ug/html_en/en/The_Vantage_app.html). |
| Dell Command \| Update | Conditional: supported Dell commercial hardware | Approved BIOS, firmware, driver, and application updates. See [Dell deployment guidance](https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update). |

Select the OEM utility that matches the device manufacturer and model. Coordinate its update schedule with other management tools to avoid conflicting driver, firmware, and restart actions.

### Productivity and collaboration

| Application | Assignment | Purpose and deployment guidance |
| --- | --- | --- |
| Microsoft 365 Apps | Core, with appropriate licensing | Word, Excel, PowerPoint, Outlook, and approved Office components. Monthly Enterprise Channel is the proposed default; confirm feature and add-in requirements against Microsoft's [update channel guidance](https://learn.microsoft.com/en-us/microsoft-365-apps/updates/overview-update-channels). |
| Microsoft OneNote | Core, included in the approved Office configuration | Use the supported OneNote desktop application. Check the deployment configuration to prevent duplicate or obsolete editions; see the [OneNote deployment guide](https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/deployment-guide-onenote). |
| Microsoft Teams | Core for organizations using Teams | Managed installation for messaging, meetings, calling where licensed, and collaboration. Validate sign-in, audio, video, screen sharing, and required integrations. |
| Microsoft OneDrive | Core for organizations using OneDrive | Work-account file synchronization and collaboration. Configure approved tenant access, Files On-Demand, and Known Folder Move where appropriate. Validate sync and recovery requirements. |
| Microsoft Copilot for work | Conditional: approved AI use, tenant configuration, and entitlement | Specify the exact Copilot experience and licensing in the application catalog, including Microsoft 365 Copilot/Copilot Chat naming where used by the tenant. Require the approved work account and data-handling policy. Review [enterprise data protection](https://learn.microsoft.com/en-us/microsoft-365/copilot/enterprise-data-protection), web search, agents, and connected services before enabling sensitive workflows. |
| Adobe Creative Cloud | Conditional: licensed creative or communications roles | Provide the Creative Cloud desktop app and selected applications such as Photoshop, Illustrator, or InDesign. Build approved [managed packages](https://helpx.adobe.com/business/enterprise/deploy-apps-updates/create-packages/create-managed-packages.html) and define update and self-service permissions. |
| PDF viewing and editing | Core viewing capability; editing conditional | Use the approved PDF viewer, such as Edge or Adobe Acrobat Reader. Assign licensed Acrobat editing and document-processing capabilities to users who need them. |

Creative Cloud deployment does not imply installation of the entire suite. Copilot availability does not authorize unrestricted use of confidential information; data access and use must follow the approved organizational policy.

### Browsers and remote access

| Application | Assignment | Purpose and deployment guidance |
| --- | --- | --- |
| Microsoft Edge | Core | Managed enterprise browser with organizational policies. Maintain it through [Microsoft Edge Update policies](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-update-policies); browser servicing is separate from the Windows feature-update cycle. |
| Google Chrome | Conditional: approved secondary browser or organization standard | Use the enterprise distribution and a managed Stable channel. Configure extensions, organizational sign-in, and update policies. Make it core if required across the organization. |
| Mozilla Firefox | Conditional: alternative-browser or compatibility requirement | Firefox ESR is the proposed option when a slower feature-change cadence is useful. Maintain security updates and enterprise policies; see [Mozilla channel guidance](https://firefox-admin-docs.mozilla.org/guides/firefox-channels/). |
| Cisco Secure Client (AnyConnect VPN) | Conditional: approved VPN access | Deploy the supported release, required modules, and organization-managed VPN profile. Validate certificates, authentication, DNS, and connectivity against [Cisco release notes](https://www.cisco.com/c/en/us/td/docs/security/vpn_client/anyconnect/Cisco-Secure-Client-5/release/notes/release-notes-cisco-secure-client-5-1.html). |
| Remote Desktop Connection / Windows App | Conditional: approved remote desktops or applications | Select the client for the destination service. Built-in Remote Desktop Connection (`mstsc.exe`) supports direct RDP workflows; Windows App supports designated cloud desktop and application services. Confirm the current [Microsoft connection matrix](https://learn.microsoft.com/en-us/windows-app/get-started-connect-devices-desktops-apps) before standardizing a client. |

Installing or allowing a remote-access client does not require enabling inbound Remote Desktop on every workstation. Keep inbound access disabled unless a documented support or business requirement calls for it, with approved authentication and network restrictions.

## Department-specific extensions

Department profiles add the applications, permissions, and controls needed for a particular job. These examples are illustrative; each requires an application owner, licensing review, compatibility testing, and documented approval.

| Department | Example applications and capabilities | Additional access and data controls to consider |
| --- | --- | --- |
| Finance | Accounting or ERP clients, reporting tools, and SQL connectivity. Assign [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/ssms/) to authorized analysts or administrators when needed. | Read-only database permissions where sufficient; separate reporting and administration rights; approval controls for financial transactions; restricted exports; logging of sensitive access. |
| Legal | [Legal Files](https://www.legalfiles.com/product/legal-matter-management-software/) for case and matter management, plus approved document review, PDF editing, and electronic signature tools. | Matter-specific permissions; protection of confidential or privileged documents; controlled external sharing; retention and legal-hold workflows. |
| Healthcare | Approved electronic health record access, such as [Epic](https://www.epic.com/about/) or [Oracle Health EHR](https://docs.oracle.com/en/industries/health/oracle-health-ehr/), plus required clinical applications and peripherals. | Role-based patient-record access; individual authentication on shared stations; session locking; access auditing; workflow-specific restrictions on local downloads, printing, and removable media. |
| Public safety | Agency-approved [Motorola Solutions PremierOne](https://www.motorolasolutions.com/en_us/products/command-center-software/public-safety-software/premierone/premierone-records.html) components for CAD, Records, or Mobile workflows, depending on dispatch, records, or field duties. | Agency-defined access to incident and criminal justice information; approved remote connectivity; access auditing; vehicle and peripheral validation; continuity procedures for outages. |
| Communications and design | Licensed Creative Cloud applications, publishing tools, and approved media workflows. | Controlled asset sharing, appropriate storage capacity, licensed content management, and restrictions on publication permissions. |
| IT and engineering | Approved administration, development, database, virtualization, or diagnostic tools. | Separate privileged identities, restricted management access, controlled elevation, and dedicated administration environments where required. |

SQL access usually means a client connecting to a managed database; a SQL Server installation is not a default requirement on an employee workstation. Department applications may be delivered through a browser, installed client, or managed remote session.

Validate Windows 11 25H2 support for the exact application version, dependencies, delivery method, and peripherals. Specialized clinical or dispatch workflows may need a separately approved workstation profile. Applicable healthcare, criminal justice, legal, or financial obligations require their own assessment; these examples are not compliance certifications.

## Validation before handoff

Record the hardware model, OS build, application versions, assigned policies, reviewer, and test date. Confirm that:

- [ ] Windows is activated, updated, and free of unresolved deployment errors or pending restarts.
- [ ] Identity, enrollment, management check-in, and IME health where applicable are verified.
- [ ] Encryption, recovery-key storage, endpoint protection, firewall settings, and update policies meet the approved configuration.
- [ ] Standard-user sign-in and required organizational authentication work.
- [ ] Assigned applications install, launch, activate, and access the correct services.
- [ ] Office documents, Teams meetings, OneDrive synchronization, approved browsers, and required peripherals work.
- [ ] VPN and remote desktop access work for authorized users where assigned.
- [ ] Department workflows work, and access is limited to the approved role.
- [ ] Recovery procedures, support ownership, exceptions, and user handoff information are documented.

Passing these checks records operational readiness against the approved configuration at a point in time. Continued patching, monitoring, access review, and reassessment remain necessary.

## Maintenance and repository organization

Keep this document focused on intended behavior. Store deployment settings, application detection rules, and detailed security policies in their respective locations. A possible future structure is:

```text
Windows-System-Administration/
├── Apps-Programs/
│   ├── workstation-environment.md
│   ├── baseline-apps.json          # Planned application catalog
│   ├── Department-Profiles/        # Planned role-specific requirements
│   ├── Config/                     # Planned sanitized deployment settings
│   └── Acquisition/                # Planned vendor acquisition scripts
├── System-Hardening/               # Detailed security configuration
└── Intune Scripts/                 # Management and deployment automation
```

The proposed catalog and folders are a roadmap, not a claim that automation already exists. For each application, eventually record its identifier, owner, assignment, architecture, license requirement, approved source, update channel, detection method, and last validation date. For downloaded packages, also record the version, publisher signature, and SHA-256 hash.

Prefer official vendor sources or approved internal package storage. Keep credentials, license keys, private certificates, tenant-sensitive configuration, and employee or departmental data out of the public repository. Include installers only when redistribution rights and repository suitability have been confirmed.

Review application need, support status, licensing, update health, and department exceptions quarterly. Trigger an earlier review for a major OS or application change, security issue, new hardware model, or changed business requirement. Record the reason for each exception, its owner, compensating controls where needed, and its review or expiration date.

## Revision history

| Version | Date | Change |
| --- | --- | --- |
| 1.0 | Original draft | General enterprise Windows workstation software baseline. |
| 1.1 — draft | September 26, 2026 | Targets Windows 11 25H2; distinguishes functionality from security assurance; updates the application catalog; adds department profiles, validation criteria, and maintenance guidance. |
