Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
   Creates Service Client object.

.PARAMETER  FullClientTypeName
    Client type full name.

.PARAMETER  AddHttpClientHandler
    Switch to determine whether the client type constructor expects the HttpClientHandler object.

.PARAMETER  Credential
    Credential is required for for creating the HttpClientHandler object.

.PARAMETER  AuthenticationCommand
    Command that should return a Microsoft.Rest.ServiceClientCredentials object that implements custom authentication logic. 

.PARAMETER  AuthenticationCommandArgumentList
    Arguments to the AuthenticationCommand, if any.

.PARAMETER  HostOverrideCommand
    Command should return a custom hostname string.
    Overrides the default host in the specification.

.PARAMETER  GlobalParameterHashtable
    Global parameters to be set on client object.
#>
function New-ServiceClient {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $FullClientTypeName,

        [Parameter(Mandatory = $false)]
        [switch]
        $AddHttpClientHandler,

        [Parameter(Mandatory = $false)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [string]
        $AuthenticationCommand,

        [Parameter(Mandatory = $false)]
        [Object[]]
        $AuthenticationCommandArgumentList,

        [Parameter(Mandatory = $false)]
        [string]
        $HostOverrideCommand,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $GlobalParameterHashtable
    )

    $ClientArgumentList = @()
    $InvokeCommand_parameters = @{
        ScriptBlock = [scriptblock]::Create($AuthenticationCommand)
    }
    if ($AuthenticationCommandArgumentList) {
        $InvokeCommand_parameters['ArgumentList'] = $AuthenticationCommandArgumentList
    }
    $ClientArgumentList += Invoke-Command @InvokeCommand_parameters

    if ($AddHttpClientHandler) {
        if(-not ('System.Net.Http.HttpClientHandler' -as [Type])) {
            Add-Type -AssemblyName System.Net.Http
        }
        $httpClientHandler = New-Object -TypeName System.Net.Http.HttpClientHandler
        $httpClientHandler.PreAuthenticate = $true
        $httpClientHandler.Credentials = $Credential
        $ClientArgumentList += $httpClientHandler
    }
    
    $delegatingHandler = New-Object -TypeName System.Net.Http.DelegatingHandler[] -ArgumentList 0
    $ClientArgumentList += $delegatingHandler

    $Client = New-Object -TypeName $FullClientTypeName -ArgumentList $ClientArgumentList

    if ($HostOverrideCommand) {
        [scriptblock]$HostOverrideCommand = [scriptblock]::Create($HostOverrideCommand)
        $Client.BaseUri = Invoke-Command -ScriptBlock $HostOverrideCommand
    }

    if ($GlobalParameterHashtable) {
        $GlobalParameterHashtable.GetEnumerator() | ForEach-Object {
            if ($_.Value -and (Get-Member -InputObject $Client -Name $_.Key -MemberType Property)) {
                $Client."$($_.Key)" = $_.Value
            }    
        }
    }

    return $Client
}
