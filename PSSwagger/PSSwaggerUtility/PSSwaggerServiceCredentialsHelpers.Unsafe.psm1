#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwaggerUtility Module
#
#########################################################################################
function Get-BasicAuthCredentials {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credential
    )

    if (-not $Credential) {
        $Credential = Get-Credential
    }

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.BasicAuthenticationCredentialsEx' -ArgumentList $Credential.UserName,$Credential.Password
}