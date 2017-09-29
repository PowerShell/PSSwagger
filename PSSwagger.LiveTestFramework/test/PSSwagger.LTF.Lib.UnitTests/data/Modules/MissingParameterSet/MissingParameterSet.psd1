@{
    RootModule = 'MissingParameterSet.psm1'
    ModuleVersion = '0.0.1'
    GUID = '7f122ac5-8607-4970-9325-db1e59016b34'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'Module with at least one function missing a parameter set'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('New-Guitar','Get-Guitar')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @('PowerShellGet')
    NestedModules = @()
    FileList = @(
        'MissingParameterSet.psd1',
        'MissingParameterSet.psm1'
    )
}