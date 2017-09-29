@{
    RootModule = 'PSSwagger.LiveTestFramework.Tests.psm1'
    ModuleVersion = '0.0.1'
    GUID = '9c0061e2-d82e-4c8a-b996-edcf70388412'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'PowerShell module with commands for testing the PSSwagger.LiveTestFramework module.'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('Initialize-TestDependency','Start-TestRun')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @('PSSwaggerUtility')
    NestedModules = @()
	DefaultCommandPrefix = 'LTF'
    FileList = @(
        'PSSwagger.LiveTestFramework.Tests.psd1',
        'PSSwagger.LiveTestFramework.Tests.psm1'
    )

    PrivateData = @{
        PSData = @{
            Tags = @('Swagger',
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

