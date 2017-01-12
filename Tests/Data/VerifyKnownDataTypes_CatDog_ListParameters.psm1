<#
.DESCRIPTION
    Gets all CatDogs with matching parameters.

.PARAMETER catdogName
    Name of CatDog.

.PARAMETER birthday
    Full date birthday of CatDog.

.PARAMETER adoptionTime
    Date-time of CatDog's adoption.

.PARAMETER secretAgentName
    CatDog's secret agent name. Don't tell anyone.

.PARAMETER isSecretAgent
    Whether or not CatDog is a secret agent.

.PARAMETER age
    CatDog's age in years.

.PARAMETER ageInSeconds
    CatDog's age in seconds.

.PARAMETER score
    CatDog's score.

.PARAMETER scoreAdjustedForInflation
    CatDog's score, adjusted for score inflation.

.PARAMETER base64string
    Any string of binary data.

#>
function GetAll-CatDogParameters
{
   [CmdletBinding()]
   param(
    [Parameter(Mandatory = $false)]
    [string] $catdogName,
    [Parameter(Mandatory = $false)]
    [string] $birthday,
    [Parameter(Mandatory = $false)]
    [string] $adoptionTime,
    [Parameter(Mandatory = $false)]
    [string] $secretAgentName,
    [Parameter(Mandatory = $false)]
    [bool] $isSecretAgent,
    [Parameter(Mandatory = $false)]
    [int] $age,
    [Parameter(Mandatory = $false)]
    [long] $ageInSeconds,
    [Parameter(Mandatory = $false)]
    [single] $score,
    [Parameter(Mandatory = $false)]
    [double] $scoreAdjustedForInflation,
    [Parameter(Mandatory = $false)]
    [string] $basestring
   )


    $serviceCredentials =  Get-AzServiceCredential
    $subscriptionId = Get-AzSubscriptionId
    $delegatingHandler = Get-AzDelegatingHandler

    $CatDogClient = [.CatDogClient]::new($serviceCredentials, $delegatingHandler)

    $CatDogClient.SubscriptionId = $subscriptionId

    Write-Verbose 'Performing operation ListParametersWithHttpMessagesAsync on $CatDogClient.'
    $taskResult = $CatDogClient.CatDog.ListParametersWithHttpMessagesAsync()
    Write-Verbose "Waiting for the operation to complete."
    $taskResult.AsyncWaitHandle.WaitOne() | out-null
    Write-Verbose "Operation Completed."
    $taskResult.Result.Body
}