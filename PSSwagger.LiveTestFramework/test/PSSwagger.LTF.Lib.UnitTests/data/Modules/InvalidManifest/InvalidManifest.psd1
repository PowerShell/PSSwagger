@{
    RootModule = 'InvalidManifest.psm1'
    ModuleVersion = '0.0.1'
    GUID = 'fa800c34-46a9-4a8b-87c0-fff415923e7d'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'Module with invalid manifest'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('New-Guitar','Get-Guitar')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @('PowerShellGet')
    NestedModules = @()
    FileList = @(
        'InvalidManifest.psd1',
        'InvalidManifest.psm1'
    )
}