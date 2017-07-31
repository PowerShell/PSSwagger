@{
    RootModule = 'PSSwagger.LiveTestFramework.psm1'
    ModuleVersion = '9.9.9'
    GUID = '026fa119-121b-4816-9556-5a306bebb963'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'PowerShell module with commands for generating or manipulating PSSwagger.LiveTestFramework binaries.'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('Start-PSSwaggerLiveTestServer','Add-PSSwaggerLiveTestLibType','Add-PSSwaggerLiveTestServerType')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @('PSSwaggerUtility')
    NestedModules = @()

    FileList = @(
        'PSSwagger.LiveTestFramework.psd1',
        'PSSwagger.LiveTestFramework.psm1'
    )

    PrivateData = @{
        PSData = @{
            Tags = @('Azure',
                'Swagger',
                'PSEdition_Desktop',
                'PSEdition_Core',
                'Linux',
                'Mac')
            ProjectUri = 'https://github.com/PowerShell/PSSwagger'
            LicenseUri = 'https://github.com/PowerShell/PSSwagger/blob/master/LICENSE'
            ReleaseNotes = @'
- Initial development release 
'@
        }
    }

}

