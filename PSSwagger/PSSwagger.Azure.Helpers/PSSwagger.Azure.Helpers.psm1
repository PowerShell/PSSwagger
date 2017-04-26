Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
    . (Join-Path -Path "$PSScriptRoot" -ChildPath "Test-CoreRequirements.ps1")
    $moduleName = 'AzureRM.Profile.NetCore.Preview'
} else {
    . (Join-Path -Path "$PSScriptRoot" -ChildPath "Test-FullRequirements.ps1")
    $moduleName = 'AzureRM.Profile'
}

function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop
    $authenticationFactory = New-Object -TypeName Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory
    if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
        [Action[string]]$stringAction = {param($s)}
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext, $stringAction)
    } else {
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    }

    $serviceCredentials
}

function Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    New-Object -TypeName System.Net.Http.DelegatingHandler[] 0
}

function Get-AzSubscriptionId
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop    
    $AzureContext.Subscription.SubscriptionId
}

function Get-AzResourceManagerUrl
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop    
    $AzureContext.Environment.ResourceManagerUrl
}

function Add-AzSRmEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [string]
        $UserName,

        [Parameter(Mandatory = $true)]
        [string]
        $AzureStackDomain
    )
    
    $AadTenantId = $UserName.split('@')[-1]
    $Graphendpoint = "https://graph.$azureStackDomain"
    if ($AadTenantId -like '*.onmicrosoft.com')
    {
        $Graphendpoint = "https://graph.windows.net/"
    } 

    $Endpoints = Microsoft.PowerShell.Utility\Invoke-RestMethod -Method Get -Uri "https://api.$azureStackDomain/metadata/endpoints?api-version=1.0"
    $ActiveDirectoryServiceEndpointResourceId = $Endpoints.authentication.audiences[0]

    # Add the Microsoft Azure Stack environment
    & "$moduleName\Add-AzureRmEnvironment" -Name $Name `
                                           -ActiveDirectoryEndpoint "https://login.windows.net/$AadTenantId/" `
                                           -ActiveDirectoryServiceEndpointResourceId $ActiveDirectoryServiceEndpointResourceId `
                                           -ResourceManagerEndpoint "https://api.$azureStackDomain/" `
                                           -GalleryEndpoint "https://gallery.$azureStackDomain/" `
                                           -GraphEndpoint $Graphendpoint
}

function Remove-AzSRmEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    & "$moduleName\Remove-AzureRmEnvironment" @PSBoundParameters
}

<#
.DESCRIPTION
  Manually initialize PSSwagger's external dependencies. Use this function with -AcceptBootstrap for silent execution scenarios.

.PARAMETER  AllUsers
  Install dependencies in PSSwagger's global package cache.

.PARAMETER  AcceptBootstrap
  Automatically consent to downloading missing packages. If not specified, an interactive prompt will be appear.
#>
function Initialize-PSSwaggerDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $AcceptBootstrap
    )

    PSSwagger.Common.Helpers\Initialize-PSSwaggerDependencies -Azure @PSBoundParameters
}