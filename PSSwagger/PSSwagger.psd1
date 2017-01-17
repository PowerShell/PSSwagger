@{
RootModule = 'PSSwagger.psm1'
ModuleVersion = '0.1.0'
GUID = '6c925abf-49bc-49f4-8a47-12b95c9a8b37'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with commands for generating the PowerShell Cmdlets using Swagger based specifications.'
NestedModules = @('Generated.Azure.Common.Helpers')
FunctionsToExport = @('Export-CommandFromSwagger')
CmdletsToExport = ''
VariablesToExport = ''
AliasesToExport = ''

FileList = @('PSSwagger.Constants.ps1',
             'PSSwagger.psm1',
             'PSSwagger.Resources.psd1')

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

