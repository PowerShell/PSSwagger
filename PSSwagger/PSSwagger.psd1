@{
    RootModule        = 'PSSwagger.psm1'
    ModuleVersion     = '0.3.0'
    PowerShellVersion = '5.1'
    GUID              = '6c925abf-49bc-49f4-8a47-12b95c9a8b37'
    Author            = 'Microsoft Corporation'
    CompanyName       = 'Microsoft Corporation'
    Copyright         = '(c) Microsoft Corporation. All rights reserved.'
    Description       = @'
The PowerShell cmdlet generator from OpenAPI (f.k.a Swagger) specification.
Please refer to https://github.com/PowerShell/PSSwagger/blob/developer/README.md for more details.
'@
    FunctionsToExport = @(
        'New-PSSwaggerModule',
        'New-PSSwaggerMetadataFile'
    )
    CmdletsToExport   = ''
    VariablesToExport = ''
    AliasesToExport   = ''

    NestedModules     = @(
        'PSSwaggerMetadata.psm1',
        'PSSwaggerUtility'
    )

    FileList          = @(
        'AssemblyGenerationHelpers.ps1',
        'AssemblyGenerationHelpers.Resources.psd1',
        'Definitions.psm1',
        'New-ArmServiceClient.ps1',
        'New-ServiceClient.ps1',
        'Get-TaskResult.ps1',
        'Paths.psm1',
        'PluralToSingularMap.json',
        'PSCommandVerbMap.ps1',
        'PSSwagger.Constants.ps1',
        'PSSwagger.psd1',
        'PSSwagger.psm1',
        'PSSwagger.Resources.psd1',
        'PSSwaggerMetadata.psm1',
        'SwaggerUtils.psm1',
        'Test-CoreRequirements.ps1',
        'Test-FullRequirements.ps1',
        'Trie.ps1',
        'Utilities.psm1',
        'ServiceTypes\azure.PSMeta.json',
        'ServiceTypes\azure_stack.PSMeta.json'
    )

    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure',
                'Swagger',
                'OpenApi',
                'PSEdition_Desktop')
            ProjectUri   = 'https://github.com/PowerShell/PSSwagger'
            LicenseUri   = 'https://github.com/PowerShell/PSSwagger/blob/master/LICENSE'
            ReleaseNotes = @'
Please refer to https://github.com/PowerShell/PSSwagger/blob/developer/CHANGELOG.md
'@
        }
    }

}

