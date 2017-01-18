@{
RootModule = 'Generated.Azure.Common.Helpers.psm1'
ModuleVersion = '0.1.0'
GUID = '2a66628c-b4b8-4fb7-9188-c1dd4164cfbf'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with Azure common helper functions'
RequiredModules = @(@{ModuleName='AzureRM.profile';ModuleVersion='1.0.5'})

RequiredAssemblies = @("$PSScriptRoot\Net45\Microsoft.Rest.ClientRuntime.dll",
                       "$PSScriptRoot\net45\Microsoft.IdentityModel.Clients.ActiveDirectory.dll",
                       "$PSScriptRoot\net45\Newtonsoft.Json.dll",
                       "$PSScriptRoot\net45\Microsoft.Rest.ClientRuntime.Azure.dll")
FunctionsToExport = @('Get-AzDelegatingHandler',
                      'Get-AzServiceCredential',
                      'Get-AzSubscriptionId',
                      'Get-AzSServiceCredential',
                      'New-AzSEnvironment',
                      'Remove-AzSEnvironment')
CmdletsToExport = ''
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

