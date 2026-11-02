Set-StrictMode -Version Latest

function Test-WsaWindowsHost {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
}

function Get-WsaPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,
        [Parameter(Mandatory)]
        [string]$Name
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) {
        $property.Value
    }
}

function Get-WsaComputerInventory {
    <#
    .SYNOPSIS
    Collects a local, read-only Windows hardware and operating-system snapshot.
    .DESCRIPTION
    Queries three local CIM classes. Does not contact a remote target, install
    software, change policy, collect recovery keys, or write a report file.
    Throws without returning a partial inventory if a required query fails.
    This is inventory, not a security, patch, licensing, or readiness verdict.
    .PARAMETER IncludeIdentifiers
    Include the computer name, BIOS serial number, and domain/workgroup name.
    These fields are null by default. Other inventory fields can still be
    identifying in combination; review all output before sharing it.
    .PARAMETER OperationTimeoutSec
    Timeout requested for each CIM query, not a whole-command deadline.
    .EXAMPLE
    Get-WsaComputerInventory
    .EXAMPLE
    Get-WsaComputerInventory -IncludeIdentifiers -OperationTimeoutSec 60
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch]$IncludeIdentifiers,
        [ValidateRange(1, 300)]
        [uint32]$OperationTimeoutSec = 30
    )

    if (-not (Test-WsaWindowsHost)) {
        throw 'Local CIM inventory requires Windows. Target-name resolution is platform-independent.'
    }
    $null = Get-Command -Name Get-CimInstance -CommandType Cmdlet -ErrorAction Stop

    $query = @{
        Namespace           = 'root/cimv2'
        OperationTimeoutSec = $OperationTimeoutSec
        ErrorAction         = 'Stop'
    }
    $osRows = @(Get-CimInstance -ClassName Win32_OperatingSystem @query)
    $systemRows = @(Get-CimInstance -ClassName Win32_ComputerSystem @query)
    $biosRows = @(Get-CimInstance -ClassName Win32_BIOS @query)
    if ($osRows.Count -ne 1 -or $systemRows.Count -ne 1 -or $biosRows.Count -ne 1) {
        throw 'Expected exactly one instance from each local inventory class; no inventory was returned.'
    }

    $os = $osRows[0]
    $system = $systemRows[0]
    $bios = $biosRows[0]
    foreach ($field in @('Caption', 'Version', 'BuildNumber')) {
        if ([string]::IsNullOrWhiteSpace([string](Get-WsaPropertyValue -InputObject $os -Name $field))) {
            throw "Required operating-system field '$field' is missing; no inventory was returned."
        }
    }

    $lastBoot = Get-WsaPropertyValue -InputObject $os -Name LastBootUpTime
    $lastBootUtc = $null
    if ($null -ne $lastBoot) {
        $lastBootUtc = ([datetime]$lastBoot).ToUniversalTime().ToString('o')
    }
    $memory = Get-WsaPropertyValue -InputObject $system -Name TotalPhysicalMemory
    $memoryBytes = $null
    if ($null -ne $memory) {
        $memoryBytes = [uint64]$memory
    }
    $membership = Get-WsaPropertyValue -InputObject $system -Name PartOfDomain
    $partOfDomain = $null
    if ($null -ne $membership) {
        $partOfDomain = [bool]$membership
    }

    $computerName = $null
    $serialNumber = $null
    $domain = $null
    if ($IncludeIdentifiers) {
        $computerName = Get-WsaPropertyValue -InputObject $system -Name Name
        $serialNumber = Get-WsaPropertyValue -InputObject $bios -Name SerialNumber
        $domain = Get-WsaPropertyValue -InputObject $system -Name Domain
    }

    [pscustomobject][ordered]@{
        PSTypeName               = 'WindowsSysAdmin.ComputerInventory'
        SchemaVersion            = '1.0'
        CollectedAtUtc           = [datetime]::UtcNow.ToString('o')
        IdentifiersIncluded      = [bool]$IncludeIdentifiers
        ComputerName             = $computerName
        SerialNumber             = $serialNumber
        Domain                   = $domain
        Manufacturer             = Get-WsaPropertyValue -InputObject $system -Name Manufacturer
        Model                    = Get-WsaPropertyValue -InputObject $system -Name Model
        Windows                  = [string]$os.Caption
        Version                  = [string]$os.Version
        BuildNumber              = [string]$os.BuildNumber
        LastBootTimeUtc          = $lastBootUtc
        PartOfDomain             = $partOfDomain
        TotalPhysicalMemoryBytes = $memoryBytes
    }
}

function Resolve-WsaComputerGroup {
    <#
    .SYNOPSIS
    Validates explicit short computer names or expands a bounded naming range.
    .DESCRIPTION
    Returns names only. Never queries DNS/AD, opens RDP, creates sessions, or
    changes a computer. Validates the complete selection before emitting names.
    Accepts this toolkit's conservative short-name subset: 1-15 ASCII letters,
    digits and internal hyphens, with at least one letter. No FQDNs, IP addresses,
    wildcards, whitespace, underscores, command strings, or implicit discovery.
    .PARAMETER ComputerName
    An explicit array; duplicates are removed case-insensitively in input order.
    .PARAMETER Prefix
    Prefix for generated names, for example LAB-. Final names are validated too.
    .PARAMETER Start
    Inclusive first number, from 0 through 9999.
    .PARAMETER End
    Inclusive last number. Must not precede Start.
    .PARAMETER Pad
    Minimum numeric width, from 1 through 4. Larger numbers are never truncated.
    .PARAMETER MaximumTargets
    Maximum unique names returned. Defaults to 50; hard limit is 256.
    .EXAMPLE
    Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 3
    .EXAMPLE
    Resolve-WsaComputerGroup -ComputerName @('LAB-01', 'lab-01', 'LAB-02')
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'List')]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, 256)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'Range')]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9-]{0,13}$')]
        [string]$Prefix,

        [Parameter(Mandatory, ParameterSetName = 'Range')]
        [ValidateRange(0, 9999)]
        [int]$Start,

        [Parameter(Mandatory, ParameterSetName = 'Range')]
        [ValidateRange(0, 9999)]
        [int]$End,

        [Parameter(ParameterSetName = 'Range')]
        [ValidateRange(1, 4)]
        [int]$Pad = 2,

        [ValidateRange(1, 256)]
        [int]$MaximumTargets = 50
    )

    if ($PSCmdlet.ParameterSetName -eq 'Range') {
        if ($End -lt $Start) {
            throw 'End must be greater than or equal to Start.'
        }
        if (($End - $Start + 1) -gt $MaximumTargets) {
            throw 'The requested range exceeds MaximumTargets.'
        }
        $candidates = @(foreach ($number in $Start..$End) {
            '{0}{1}' -f $Prefix, $number.ToString("D$Pad", [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    else {
        $candidates = $ComputerName
    }

    $names = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or
            $candidate.Length -gt 15 -or
            $candidate -cnotmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$' -or
            $candidate -cnotmatch '[A-Za-z]') {
            throw 'Invalid computer name. Use 1-15 ASCII letters/digits and internal hyphens, including at least one letter.'
        }
        if ($seen.Add($candidate)) {
            $names.Add($candidate)
        }
    }
    if ($names.Count -gt $MaximumTargets) {
        throw 'The unique target selection exceeds MaximumTargets.'
    }
    $names.ToArray()
}

Export-ModuleMember -Function Get-WsaComputerInventory, Resolve-WsaComputerGroup
