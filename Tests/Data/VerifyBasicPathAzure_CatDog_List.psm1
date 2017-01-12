<#
.DESCRIPTION
    Gets all CatDogs registered to owner with name ownerName.

.PARAMETER ownerName
    Name of CatDog owner.

#>
function GetAll-CatDog
{
   [CmdletBinding()]
   param(
    [Parameter(Mandatory = $true)]
    [string] $ownerName
   )


    $serviceCredentials =  Get-AzServiceCredential
    $subscriptionId = Get-AzSubscriptionId
    $delegatingHandler = Get-AzDelegatingHandler

    $CatDogClient = [.CatDogClient]::new($serviceCredentials, $delegatingHandler)

    $CatDogClient.SubscriptionId = $subscriptionId

    Write-Verbose 'Performing operation ListWithHttpMessagesAsync on $CatDogClient.'
    $taskResult = $CatDogClient.CatDog.ListWithHttpMessagesAsync($ownerName)
    Write-Verbose "Waiting for the operation to complete."
    $taskResult.AsyncWaitHandle.WaitOne() | out-null
    Write-Verbose "Operation Completed."
    $taskResult.Result.Body
}