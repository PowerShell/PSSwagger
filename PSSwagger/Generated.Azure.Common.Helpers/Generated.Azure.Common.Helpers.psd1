﻿@{
RootModule = 'Generated.Azure.Common.Helpers.psm1'
ModuleVersion = '0.1.0'
GUID = '2a66628c-b4b8-4fb7-9188-c1dd4164cfbf'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with Azure common helper functions'
FunctionsToExport = @('Get-AzDelegatingHandler',
                      'Get-AzServiceCredential',
                      'Get-AzSubscriptionId',
                      'Get-AzResourceManagerUrl',
                      'Add-AzSRmEnvironment',
                      'Remove-AzSRmEnvironment',
                      'Invoke-SwaggerCommandUtility',
					  'New-PSSwaggerClientTracing',
					  'Register-PSSwaggerClientTracing',
					  'Unregister-PSSwaggerClientTracing')
CmdletsToExport = @('Start-PSSwaggerJob')
VariablesToExport = ''
AliasesToExport = ''

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

