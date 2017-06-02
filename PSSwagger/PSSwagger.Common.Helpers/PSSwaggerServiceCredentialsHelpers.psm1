function Get-BasicAuthCredentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credential
    )

    if(('Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -as [Type]))
    {
        # If the Extended type exists, use it
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -ArgumentList $Credential.UserName,$Credential.Password
    } else {
        # Otherwise this version should exist
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthentication' -ArgumentList $Credential.UserName,$Credential.Password
    }
}

function Get-ApiKeyCredentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey,

        [Parameter(Mandatory=$false)]
        [string]
        $In,

        [Parameter(Mandatory=$false)]
        [string]
        $Name
    )

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSApiKeyAuthentication' -ArgumentList $APIKey,$In,$Name
}

function Get-EmptyAuthCredentialInternal {
    [CmdletBinding()]
    param()

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSDummyAuthentication'
}