@{
    RootModule = 'PSSwagger.LiveTestFramework.Build.psm1'
    ModuleVersion = '0.0.1'
    GUID = '03459d8d-5fcc-48e1-9a88-94f7971e0335'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'PowerShell module with commands for building the PSSwagger.LiveTestFramework package.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Initialize-BuildDependency','Invoke-Build','Start-BuildDotNetProject')
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    RequiredModules = @()
    NestedModules = @()
	DefaultCommandPrefix = 'LTF'
    FileList = @(
        'PSSwagger.LiveTestFramework.Build.psd1',
        'PSSwagger.LiveTestFramework.Build.psm1'
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

