<#
.DESCRIPTION
    Creates a new CatDog with the specified parameters.

.PARAMETER name
    Name of the CatDog to create.

#>
function New-CatDog
{
   [CmdletBinding()]
   param(
    [Parameter(Mandatory = $true)]
    [string] $name
   )


    $serviceCredentials =  Get-AzServiceCredential
    $subscriptionId = Get-AzSubscriptionId
    $delegatingHandler = Get-AzDelegatingHandler

    $CatDogClient = [.CatDogClient]::new($serviceCredentials, $delegatingHandler)
    $CatDogClient.ApiVersion = "2015-12-01"
    $CatDogClient.SubscriptionId = $subscriptionId

    Write-Verbose 'Performing operation CreateWithHttpMessagesAsync on $CatDogClient.'
    $taskResult = $CatDogClient.CatDogOperations.CreateWithHttpMessagesAsync($name)
    Write-Verbose "Waiting for the operation to complete."
    $taskResult.AsyncWaitHandle.WaitOne() | out-null
    Write-Verbose "Operation Completed."
    $taskResult.Result.Body
}