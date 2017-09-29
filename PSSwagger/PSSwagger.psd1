@{
RootModule = 'PSSwagger.psm1'
ModuleVersion = '0.3.0'
PowerShellVersion = '5.1'
GUID = '6c925abf-49bc-49f4-8a47-12b95c9a8b37'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = @'
The PowerShell cmdlet generator from OpenAPI (f.k.a Swagger) specification.
Please refer to https://github.com/PowerShell/PSSwagger/blob/developer/README.md for more details.
'@
FunctionsToExport = @(
                        'New-PSSwaggerModule',
                        'New-PSSwaggerMetadataFile'
                    )
CmdletsToExport = ''
VariablesToExport = ''
AliasesToExport = ''

NestedModules = @(
                    'PSSwaggerMetadata.psm1',
                    'PSSwaggerUtility'
                )

FileList = @(
             'Definitions.psm1',
             'Generated.Resources.psd1',
             'Paths.psm1',
             'PSSwagger.Constants.ps1',
             'PSSwagger.psd1',
             'PSSwagger.psm1',
             'PSSwagger.Resources.psd1',
             'PSSwaggerMetadata.psm1',
             'SwaggerUtils.psm1',
             'Utilities.psm1',
             'Trie.ps1'
            )

PrivateData = @{
    PSData = @{
        Tags = @('Azure',
                 'Swagger',
                 'OpenApi',
                 'PSEdition_Desktop')
        ProjectUri = 'https://github.com/PowerShell/PSSwagger'
        LicenseUri = 'https://github.com/PowerShell/PSSwagger/blob/master/LICENSE'
        ReleaseNotes = @'
Please refer to https://github.com/PowerShell/PSSwagger/blob/developer/CHANGELOG.md
'@
    }
}

}

