BeforeAll {
    $manifest = Join-Path $PSScriptRoot '../../Modules/WindowsSysAdmin/WindowsSysAdmin.psd1'
    Import-Module $manifest -Force -ErrorAction Stop
}

Describe 'Module contract' -Tag Unit {
    It 'has a valid preview manifest with exactly two public commands' {
        $manifest = Join-Path $PSScriptRoot '../../Modules/WindowsSysAdmin/WindowsSysAdmin.psd1'
        $module = Test-ModuleManifest $manifest -ErrorAction Stop
        $module.Version.ToString() | Should -Be '0.1.0'
        $module.PrivateData.PSData.Prerelease | Should -Be 'preview1'
        @($module.ExportedFunctions.Keys).Count | Should -Be 2
        $module.ExportedFunctions.Keys | Should -Contain 'Get-WsaComputerInventory'
        $module.ExportedFunctions.Keys | Should -Contain 'Resolve-WsaComputerGroup'
    }
    It 'does not export private implementation helpers' {
        @(Get-Command -Module WindowsSysAdmin).Name | Should -Not -Contain 'Test-WsaWindowsHost'
        @(Get-Command -Module WindowsSysAdmin).Name | Should -Not -Contain 'Get-WsaPropertyValue'
    }
}

Describe 'Resolve-WsaComputerGroup' -Tag Unit {
    It 'expands a padded inclusive range' {
        $names = @(Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 4 -End 6)
        $names.Count | Should -Be 3
        ($names -join ',') | Should -Be 'LAB-04,LAB-05,LAB-06'
    }
    It 'supports a single target and zero' {
        @(Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 0 -End 0)[0] | Should -Be 'LAB-00'
    }
    It 'supports custom padding without truncating larger numbers' {
        @(Resolve-WsaComputerGroup -Prefix 'PC' -Start 999 -End 999 -Pad 2)[0] | Should -Be 'PC999'
        @(Resolve-WsaComputerGroup -Prefix 'PC' -Start 1 -End 1 -Pad 4)[0] | Should -Be 'PC0001'
    }
    It 'deduplicates explicit names case-insensitively and preserves first spelling/order' {
        $names = @(Resolve-WsaComputerGroup -ComputerName @('LAB-02', 'lab-02', 'LAB-01'))
        ($names -join ',') | Should -Be 'LAB-02,LAB-01'
    }
    It 'allows one-character and 15-character names' {
        @(Resolve-WsaComputerGroup -ComputerName @('A', 'ABCDEFGHIJKLMNO')).Count | Should -Be 2
    }
    It 'checks the unique selection rather than the raw duplicate count' {
        @(Resolve-WsaComputerGroup -ComputerName @('A', 'a') -MaximumTargets 1).Count | Should -Be 1
    }
    It 'rejects reversed ranges' {
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 3 -End 2 } | Should -Throw '*End*'
    }
    It 'rejects ranges over the default maximum' {
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 51 } | Should -Throw '*MaximumTargets*'
    }
    It 'supports an explicit maximum up to the hard cap' {
        @(Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 256 -MaximumTargets 256).Count | Should -Be 256
    }
    It 'rejects an explicit list exceeding the requested maximum' {
        { Resolve-WsaComputerGroup -ComputerName @('A', 'B') -MaximumTargets 1 } | Should -Throw '*MaximumTargets*'
    }
    It 'rejects generated names beyond the short-name limit' {
        { Resolve-WsaComputerGroup -Prefix 'ABCDEFGHIJKLM-' -Start 10 -End 10 } | Should -Throw '*Invalid computer name*'
    }
    It 'rejects invalid explicit name <Name>' -ForEach @(
        @{ Name = 'LAB-*' }, @{ Name = 'LAB-01.example.test' }, @{ Name = '192.0.2.1' },
        @{ Name = '-LAB' }, @{ Name = 'LAB-' }, @{ Name = 'LAB_01' },
        @{ Name = ' LAB-01' }, @{ Name = 'LAB 01' }, @{ Name = 'LAB-01 ' },
        @{ Name = 'LAB;whoami' }, @{ Name = '12345' }, @{ Name = 'ABCDEFGHIJKLMNOP' },
        @{ Name = 'LAB/01' }, @{ Name = 'LAB\01' }, @{ Name = 'LAB' + [char]10 + '01' }
    ) {
        { Resolve-WsaComputerGroup -ComputerName @($Name) } | Should -Throw
    }
    It 'rejects blank, null and empty lists' {
        { Resolve-WsaComputerGroup -ComputerName @('') } | Should -Throw
        { Resolve-WsaComputerGroup -ComputerName @(' ') } | Should -Throw
        { Resolve-WsaComputerGroup -ComputerName $null } | Should -Throw
        { Resolve-WsaComputerGroup -ComputerName @() } | Should -Throw
    }
    It 'rejects invalid prefixes' {
        { Resolve-WsaComputerGroup -Prefix 'LAB.*' -Start 1 -End 2 } | Should -Throw
        { Resolve-WsaComputerGroup -Prefix '-LAB' -Start 1 -End 2 } | Should -Throw
    }
    It 'rejects out-of-range numeric arguments' {
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start -1 -End 1 } | Should -Throw
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 10000 } | Should -Throw
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 1 -Pad 0 } | Should -Throw
        { Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 1 -Pad 5 } | Should -Throw
        { Resolve-WsaComputerGroup -ComputerName @('A') -MaximumTargets 257 } | Should -Throw
        { Resolve-WsaComputerGroup -ComputerName @('A') -MaximumTargets 0 } | Should -Throw
    }
    It 'emits no partial target list when a later candidate is invalid' {
        $captured = [System.Collections.Generic.List[string]]::new()
        try {
            Resolve-WsaComputerGroup -ComputerName @('LAB-01', 'LAB-*') |
                ForEach-Object { $captured.Add($_) }
        }
        catch { }
        $captured.Count | Should -Be 0
    }
    It 'emits no partial range when a later number makes the name too long' {
        $captured = [System.Collections.Generic.List[string]]::new()
        try {
            Resolve-WsaComputerGroup -Prefix 'ABCDEFGHIJKLM-' -Start 9 -End 10 -Pad 1 |
                ForEach-Object { $captured.Add($_) }
        }
        catch { }
        $captured.Count | Should -Be 0
    }
    It 'does not query CIM while resolving names' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin { throw 'Unexpected CIM query' }
        $null = Resolve-WsaComputerGroup -Prefix 'LAB-' -Start 1 -End 2
        Should -Invoke Get-CimInstance -ModuleName WindowsSysAdmin -Times 0 -Exactly
    }
}

Describe 'Get-WsaComputerInventory with synthetic CIM data' -Tag Unit {
    BeforeEach {
        Mock Test-WsaWindowsHost -ModuleName WindowsSysAdmin { $true }
        Mock Get-CimInstance -ModuleName WindowsSysAdmin {
            switch ($ClassName) {
                'Win32_OperatingSystem' {
                    [pscustomobject]@{
                        Caption = 'Synthetic Windows'; Version = '10.0.12345'; BuildNumber = '12345'
                        LastBootUpTime = [datetime]'2026-01-01T12:00:00Z'
                    }
                }
                'Win32_ComputerSystem' {
                    [pscustomobject]@{
                        Name = 'LAB-01'; Manufacturer = 'Example Vendor'; Model = 'Example Model'
                        Domain = 'example.test'; PartOfDomain = $true; TotalPhysicalMemory = 17179869184
                    }
                }
                'Win32_BIOS' { [pscustomobject]@{ SerialNumber = 'SYNTHETIC-SERIAL' } }
                default { throw 'Unexpected class requested' }
            }
        }
    }
    It 'returns one versioned structured inventory object' {
        $rows = @(Get-WsaComputerInventory)
        $rows.Count | Should -Be 1
        $rows[0].SchemaVersion | Should -Be '1.0'
        $rows[0].Windows | Should -Be 'Synthetic Windows'
        $rows[0].Version | Should -Be '10.0.12345'
        $rows[0].BuildNumber | Should -Be '12345'
        $rows[0].Manufacturer | Should -Be 'Example Vendor'
        $rows[0].Model | Should -Be 'Example Model'
        $rows[0].TotalPhysicalMemoryBytes | Should -Be 17179869184
        $rows[0].PartOfDomain | Should -BeTrue
        $rows[0].CollectedAtUtc | Should -Match 'Z$'
        $rows[0].LastBootTimeUtc | Should -Be '2026-01-01T12:00:00.0000000Z'
    }
    It 'omits direct identifiers by default including serialized JSON' {
        $inventory = Get-WsaComputerInventory
        $inventory.IdentifiersIncluded | Should -BeFalse
        $inventory.ComputerName | Should -BeNullOrEmpty
        $inventory.SerialNumber | Should -BeNullOrEmpty
        $inventory.Domain | Should -BeNullOrEmpty
        ($inventory | ConvertTo-Json) | Should -Not -Match 'LAB-01|SYNTHETIC-SERIAL|example\.test'
    }
    It 'includes identifiers only on explicit request' {
        $inventory = Get-WsaComputerInventory -IncludeIdentifiers
        $inventory.IdentifiersIncluded | Should -BeTrue
        $inventory.ComputerName | Should -Be 'LAB-01'
        $inventory.SerialNumber | Should -Be 'SYNTHETIC-SERIAL'
        $inventory.Domain | Should -Be 'example.test'
    }
    It 'uses exactly three local read-only queries with terminating errors and the requested timeout' {
        $null = Get-WsaComputerInventory -OperationTimeoutSec 45
        Should -Invoke Get-CimInstance -ModuleName WindowsSysAdmin -Times 3 -Exactly -ParameterFilter {
            $Namespace -eq 'root/cimv2' -and $OperationTimeoutSec -eq 45 -and
            $ErrorAction -eq 'Stop' -and -not $ComputerName -and -not $CimSession
        }
        foreach ($class in @('Win32_OperatingSystem', 'Win32_ComputerSystem', 'Win32_BIOS')) {
            Should -Invoke Get-CimInstance -ModuleName WindowsSysAdmin -Times 1 -Exactly -ParameterFilter {
                $ClassName -eq $class
            }
        }
    }
    It 'rejects unsupported hosts before querying CIM' {
        Mock Test-WsaWindowsHost -ModuleName WindowsSysAdmin { $false }
        { Get-WsaComputerInventory } | Should -Throw '*requires Windows*'
        Should -Invoke Get-CimInstance -ModuleName WindowsSysAdmin -Times 0 -Exactly
    }
    It 'does not silently install a missing CIM prerequisite' {
        Mock Get-Command -ModuleName WindowsSysAdmin { throw 'CIM cmdlet unavailable' } -ParameterFilter {
            $Name -eq 'Get-CimInstance'
        }
        { Get-WsaComputerInventory } | Should -Throw '*CIM cmdlet unavailable*'
        Should -Invoke Get-CimInstance -ModuleName WindowsSysAdmin -Times 0 -Exactly
    }
    It 'propagates a failed query without returning a partial report' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin { throw 'Synthetic access denied' } -ParameterFilter {
            $ClassName -eq 'Win32_BIOS'
        }
        $captured = [System.Collections.Generic.List[object]]::new()
        { Get-WsaComputerInventory | ForEach-Object { $captured.Add($_) } } |
            Should -Throw '*Synthetic access denied*'
        $captured.Count | Should -Be 0
    }
    It 'rejects zero rows from a required class' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin { } -ParameterFilter { $ClassName -eq 'Win32_BIOS' }
        { Get-WsaComputerInventory } | Should -Throw '*exactly one*'
    }
    It 'rejects multiple rows from a required class' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin {
            [pscustomobject]@{ SerialNumber = 'A' }; [pscustomobject]@{ SerialNumber = 'B' }
        } -ParameterFilter { $ClassName -eq 'Win32_BIOS' }
        { Get-WsaComputerInventory } | Should -Throw '*exactly one*'
    }
    It 'rejects missing required OS fields rather than returning a misleading result' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin {
            [pscustomobject]@{ Caption = 'Synthetic Windows'; Version = ''; BuildNumber = '12345' }
        } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        { Get-WsaComputerInventory } | Should -Throw '*Required operating-system field*'
    }
    It 'preserves unknown optional data as null rather than false or zero' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin {
            [pscustomobject]@{ Caption = 'Synthetic Windows'; Version = '10.0'; BuildNumber = '12345' }
        } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Get-CimInstance -ModuleName WindowsSysAdmin { [pscustomobject]@{ Name = 'LAB-01' } } -ParameterFilter {
            $ClassName -eq 'Win32_ComputerSystem'
        }
        Mock Get-CimInstance -ModuleName WindowsSysAdmin { [pscustomobject]@{ Version = 'Synthetic' } } -ParameterFilter {
            $ClassName -eq 'Win32_BIOS'
        }
        $inventory = Get-WsaComputerInventory -IncludeIdentifiers
        ($null -eq $inventory.PartOfDomain) | Should -BeTrue
        ($null -eq $inventory.TotalPhysicalMemoryBytes) | Should -BeTrue
        ($null -eq $inventory.LastBootTimeUtc) | Should -BeTrue
        ($null -eq $inventory.SerialNumber) | Should -BeTrue
        ($null -eq $inventory.Model) | Should -BeTrue
    }
    It 'preserves a known false domain-membership value' {
        Mock Get-CimInstance -ModuleName WindowsSysAdmin {
            [pscustomobject]@{ PartOfDomain = $false; TotalPhysicalMemory = 0 }
        } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        $inventory = Get-WsaComputerInventory
        $inventory.PartOfDomain | Should -BeFalse
        $inventory.TotalPhysicalMemoryBytes | Should -Be 0
    }
    It 'rejects invalid timeout values' {
        { Get-WsaComputerInventory -OperationTimeoutSec 0 } | Should -Throw
        { Get-WsaComputerInventory -OperationTimeoutSec 301 } | Should -Throw
    }
}
