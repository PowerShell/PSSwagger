
<#
.DESCRIPTION
    Gets the Azure Profile for the current process. 
    This command uses Login-AzureRMAccount
#>


function Get-AzServiceCredntial
{
    [CmdletBinding()]
    param()

    $ap = Get-Az
    $authenticationFactory = [Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory]::new() 
    $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($ap.Context)
    $serviceCredentials
}

fuction Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    [System.Net.Http.DelegatingHandler[]]::new(0) 
}