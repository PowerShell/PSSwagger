#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
   Creates AutoRest ServiceClientCredentials for Microsoft Azure using the logged in AzureRM context.
#>
function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()

    $AzureContext = & "Get-AzureRmContext" -ErrorAction Stop
    $authenticationFactory = New-Object -TypeName Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory
    if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
        [Action[string]]$stringAction = {param($s)}
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext, $stringAction)
    } else {
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    }

    $serviceCredentials
}

<#
.DESCRIPTION
   Creates delegating handlers for Microsoft Azure generated modules.
#>
function Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    New-Object -TypeName System.Net.Http.DelegatingHandler[] 0
}

<#
.DESCRIPTION
   Gets the Azure subscription ID from the logged in AzureRM context.
#>
function Get-AzSubscriptionId
{
    [CmdletBinding()]
    param()

    $AzureContext = & "Get-AzureRmContext" -ErrorAction Stop
    if(Get-Member -InputObject $AzureContext.Subscription -Name SubscriptionId)
    {
        return $AzureContext.Subscription.SubscriptionId
    }
    else
    {
        return $AzureContext.Subscription.Id        
    }
}

<#
.DESCRIPTION
   Gets the resource manager URL from the logged in AzureRM context.
#>
function Get-AzResourceManagerUrl
{
    [CmdletBinding()]
    param()

    $AzureContext = & "Get-AzureRmContext" -ErrorAction Stop    
    $AzureContext.Environment.ResourceManagerUrl
}

<#
.DESCRIPTION
   Creates a System.Net.Http.HttpClientHandler for the given credentials and sets preauthentication to true.
#>
function New-HttpClientHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credential
    )

    Add-Type -AssemblyName System.Net.Http
    $httpClientHandler = New-Object -TypeName System.Net.Http.HttpClientHandler
    $httpClientHandler.PreAuthenticate = $true
    $httpClientHandler.Credentials = $Credential
    $httpClientHandler
}