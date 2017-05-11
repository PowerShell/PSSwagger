function Get-BasicAuthCredentialsInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credential
    )

    if (-not $Credential) {
        $Credential = Get-Credential
    }

    if(('Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -as [Type]))
    {
        # If the Extended type exists, use it
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -ArgumentList $Credential.UserName,$Credential.Password
    } else {
        # Otherwise this version should exist
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthentication' -ArgumentList $Credential.UserName,$Credential.Password
    }
}

function Get-ApiKeyCredentialsInternal {
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

function Get-EmptyAuthCredentialsInternal {
    [CmdletBinding()]
    param()

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSDummyAuthentication'
}