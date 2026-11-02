# Read-only inventory and target-name planning

**Release status:** Development preview. Only the two commands below are implemented. This guide does not authorize production use or certify any workstation baseline.

## Prerequisites and effects

Use an authorized local Windows machine and a reviewed checkout. Intended runtimes are Windows PowerShell 5.1 and PowerShell 7.4+ on Windows. The module requires the built-in Get-CimInstance cmdlet for inventory; it never installs missing prerequisites or changes execution policy. Local WMI/CIM permissions are required. Start without elevation; an access failure should be investigated with the system owner rather than automatically elevating.

Inventory requests exactly Win32_OperatingSystem, Win32_ComputerSystem, and Win32_BIOS in root/cimv2, locally. It does not request a remote session or computer name. It does not enumerate installed MSI products, retrieve recovery keys, contact a tenant, update software, change firewall rules, write files, or restart anything. Microsoft's [Get-CimInstance documentation](https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance) describes its local behavior when no remote target/session is supplied.

## Collect and inspect

~~~powershell
Import-Module .\Modules\WindowsSysAdmin\WindowsSysAdmin.psd1 -Force
$inventory = Get-WsaComputerInventory
$inventory | Format-List
~~~

The result is one WindowsSysAdmin.ComputerInventory object, with schema version 1.0, a UTC collection timestamp, OS/build, manufacturer/model, last-boot timestamp, domain-membership status, and memory in bytes. Unknown optional values remain null, not false or zero. Required query failures, empty/ambiguous class results, or missing OS fields produce a terminating error and **no partial report**.

By default, ComputerName, SerialNumber, and Domain are null. Domain here means the CIM domain/workgroup value, not proof of Entra join or Intune enrollment. Domain-membership false means the returned CIM value is false; null means it was unavailable.

~~~powershell
# Explicitly opt into sensitive identifiers for an authorized local workflow.
$inventory = Get-WsaComputerInventory -IncludeIdentifiers -OperationTimeoutSec 60
~~~

The timeout is requested separately for each query. It is not a deadline for the whole command. BIOS serial numbers can be absent, placeholder, or vendor-specific; the module does not certify their uniqueness.

The module never saves output automatically. A technician may export it only to an approved private destination using their normal process. That destination's permissions, retention, and overwrite behavior are the technician's responsibility. Do not attach raw output to public issues, PRs, or CI artifacts. Omission of direct identifiers is not a promise of complete anonymization.

## Plan names without contacting devices

~~~powershell
$targets = @(Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 3)
$targets
# LAB-01, LAB-02, LAB-03

$targets = @(Resolve-WsaComputerGroup -ComputerName @('LAB-02', 'lab-02', 'LAB-01'))
# First spelling/order retained: LAB-02, LAB-01
~~~

This is a conservative short-name contract, not validation of every name Windows or DNS permits: 1-15 ASCII letters/digits/internal hyphens, with at least one letter. FQDNs, IP literals, underscores, whitespace, wildcards, and command strings are rejected. Ranges are inclusive; padding is a minimum width and never truncates numbers. -MaximumTargets defaults to 50 and cannot exceed 256. An explicit list is capped at 256 input entries; the requested maximum applies after case-insensitive deduplication.

The entire selection is validated before any target is emitted. Names are **not evidence of existence, reachability, management enrollment, or permission**. The function performs no network discovery and starts no remote action. Review concrete names before using them in a separately approved tool.

## Failures and next steps

On an inventory error, retain the error in the approved private ticketing process, inspect the host/runtime/CIM prerequisites, and rerun only after resolving the cause. Do not interpret an empty result as a healthy device. Do not turn an access failure into a blanket policy bypass. For invalid names or a selection-limit error, correct the input; do not weaken validation to permit command strings or wildcard discovery.

A successful call establishes only that the selected data was collected. It does not validate Windows 11 support, patch compliance, secure boot, BitLocker escrow, Defender health, application readiness, or organizational approval. Those are separately scoped future checks in the [implementation plan](../Docs/Implementation-Plan.md).
