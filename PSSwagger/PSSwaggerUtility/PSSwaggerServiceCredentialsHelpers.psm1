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

function Get-BasicAuthCredentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credential
    )

    if(("$($LocalizedData.CSharpNamespace).PSBasicAuthenticationEx" -as [Type]))
    {
        # If the Extended type exists, use it
        New-Object -TypeName "$($LocalizedData.CSharpNamespace).PSBasicAuthenticationEx" -ArgumentList $Credential.UserName,$Credential.Password
    } else {
        # Otherwise this version should exist
        New-Object -TypeName "$($LocalizedData.CSharpNamespace).PSBasicAuthentication" -ArgumentList $Credential.UserName,$Credential.Password
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
        $Location,

        [Parameter(Mandatory=$false)]
        [string]
        $Name
    )

    New-Object -TypeName "$($LocalizedData.CSharpNamespace).PSApiKeyAuthentication" -ArgumentList $APIKey,$Location,$Name
}

function Get-EmptyAuthCredentialInternal {
    [CmdletBinding()]
    param()

    New-Object -TypeName "$($LocalizedData.CSharpNamespace).PSDummyAuthentication"
}