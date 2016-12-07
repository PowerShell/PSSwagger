
$script:azureRMProfile = $null

<#
.DESCRIPTION
    Gets the Azure Profile for the current process. 
    This command uses Login-AzureRMAccount
#>
function Get-AzRMProfile
{
   [CmdletBinding()]
   param()

   if (-not $script:azureRMProfile)
   {
        $script:azureRMProfile = Login-AzureRmAccount
   }
   $script:azureRMProfile
}


function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()

    $ap = Get-AzRMProfile
    $authenticationFactory = [Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory]::new() 
    $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($ap.Context)
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

    $ap = Get-AzureRmContext -ea stop
    $ap.Subscription.SubscriptionId
}