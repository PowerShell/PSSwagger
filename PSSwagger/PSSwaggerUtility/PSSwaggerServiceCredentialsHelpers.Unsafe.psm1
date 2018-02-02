#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwaggerUtility Module
#
#########################################################################################
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwaggerUtility.Resources.psd1

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

    New-Object -TypeName "$($LocalizedData.CSharpNamespace).BasicAuthenticationCredentialsEx" -ArgumentList $Credential.UserName,$Credential.Password
}