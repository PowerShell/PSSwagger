function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()

    $AzureContext = AzureRM.Profile\Get-AzureRmContext -ErrorAction Stop
    $authenticationFactory = [Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory]::new() 
    $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    $serviceCredentials
}

function Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    ,[System.Net.Http.DelegatingHandler[]]::new(0) 
}

function Get-AzSubscriptionId
{
    [CmdletBinding()]
    param()

    $AzureContext = AzureRM.Profile\Get-AzureRmContext -ErrorAction Stop    
    $AzureContext.Subscription.SubscriptionId
}

function Get-AzResourceManagerUrl
{
    [CmdletBinding()]
    param()

    $AzureContext = AzureRM.Profile\Get-AzureRmContext -ErrorAction Stop    
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
    AzureRM.Profile\Add-AzureRmEnvironment -Name $Name `
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

    AzureRM.Profile\Remove-AzureRmEnvironment @PSBoundParameters
}