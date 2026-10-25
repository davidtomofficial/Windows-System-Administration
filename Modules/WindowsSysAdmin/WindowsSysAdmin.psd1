@{
    RootModule        = 'WindowsSysAdmin.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '0bfa0bc5-25bc-4b39-a7e2-ea1b8f35683c'
    Author            = 'David Tom'
    Description       = 'Read-only local Windows inventory and bounded, offline computer-name selection. Development preview; not a released product.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @('Get-WsaComputerInventory', 'Resolve-WsaComputerGroup')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData = @{
        PSData = @{
            Prerelease = 'preview1'
            Tags = @('Windows', 'PowerShell', 'SystemAdministration')
            ProjectUri = 'https://github.com/davidtomofficial/Windows-System-Administration'
        }
    }
}
