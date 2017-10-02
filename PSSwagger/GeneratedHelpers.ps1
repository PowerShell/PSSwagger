Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

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