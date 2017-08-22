@{
    RootModule = 'BasicHappyPath.psm1'
    ModuleVersion = '0.0.1'
    GUID = '2cb82de2-af44-4483-9e8d-522a2c46436b'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'Basic happy path module'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('New-Guitar','Get-Guitar')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @('PowerShellGet')
    NestedModules = @()
    FileList = @(
        'BasicHappyPath.psd1',
        'BasicHappyPath.psm1'
    )
}

