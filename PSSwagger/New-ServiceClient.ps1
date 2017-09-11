Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
   Creates Service Client object.

.PARAMETER  FullClientTypeName
    Client type full name.

.PARAMETER  ArgumentList
    List of argument to be passed in to the client type constructor.
#>
function New-ServiceClient {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $FullClientTypeName,

        [Parameter(Mandatory = $true)]
        [Object[]]
        $ArgumentList
    )

    return New-Object -TypeName $FullClientTypeName -ArgumentList $ArgumentList
}
