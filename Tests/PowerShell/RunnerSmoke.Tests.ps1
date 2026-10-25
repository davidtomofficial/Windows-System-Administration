BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../Modules/WindowsSysAdmin/WindowsSysAdmin.psd1') -Force -ErrorAction Stop
}

Describe 'Read-only Windows runner smoke test' -Tag RunnerSmoke {
    It 'collects real local CIM data without writing it to the test log' {
        # No formatting, JSON export, or inventory artifact publication here.
        $inventory = Get-WsaComputerInventory
        $inventory.SchemaVersion | Should -Be '1.0'
        $inventory.Version | Should -Not -BeNullOrEmpty
        $inventory.BuildNumber | Should -Not -BeNullOrEmpty
        $inventory.IdentifiersIncluded | Should -BeFalse
        ($null -eq $inventory.ComputerName) | Should -BeTrue
        ($null -eq $inventory.SerialNumber) | Should -BeTrue
        ($null -eq $inventory.Domain) | Should -BeTrue
    }
}
