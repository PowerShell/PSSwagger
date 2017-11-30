#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################

function Get-PascalCasedString
{
    param([string] $Name)

    if($Name) {
        $Name = Remove-SpecialCharacter -Name $Name
        $startIndex = 0
        $subStringLength = 1

        return $($Name.substring($startIndex, $subStringLength)).ToUpper() + $Name.substring($subStringLength)
    }

}

<#
.DESCRIPTION
    Some hashtables can have 'Count' as a key value, 
    in that case, $Hashtable.Count return the value rather than hashtable keys count in PowerShell.
    This utility uses enumerator to count the number of keys in a hashtable.
#>
function Get-HashtableKeyCount
{
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Hashtable
    )

    $KeyCount = 0
    $Hashtable.GetEnumerator() | ForEach-Object { $KeyCount++ }    
    return $KeyCount
}

function Remove-SpecialCharacter
{
    param([string] $Name)

    $pattern = '[^a-zA-Z0-9]'
    return ($Name -replace $pattern, '')
}

# Utility to throw an errorrecord
function Write-TerminatingError
{
    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,
        
        [System.Object]
        $ExceptionObject,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
        
    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject    
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}

<#
.DESCRIPTION
    This function is a helper function for any script module Advanced Function.
    Fetches "Preference" variable values from the caller's scope and sets them locally.
    Script module functions do not automatically inherit their caller's variables, but they can be
    obtained through the $PSCmdlet variable in Advanced Functions.
.PARAMETER Cmdlet
    The $PSCmdlet object from a script module Advanced Function.
.PARAMETER SessionState
    The $ExecutionContext.SessionState object from a script module Advanced Function. 
#>
function Get-CallerPreference
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState
    )

    # List of preference variables
    $Variables = @{
        'ErrorActionPreference' = 'ErrorAction'
        'DebugPreference' = 'Debug'
        'ConfirmPreference' = 'Confirm'
        'WhatIfPreference' = 'WhatIf'
        'VerbosePreference' = 'Verbose'
        'WarningPreference' = 'WarningAction'
        'ProgressPreference' = $null
        'PSDefaultParameterValues' = $null
    }

    $Variables.GetEnumerator() | ForEach-Object {
        $VariableName = $_.Name
        $VariableValue = $_.Value

        if (-not $VariableValue -or
            -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($VariableValue))
        {
            $Variable = $Cmdlet.SessionState.PSVariable.Get($VariableName)
            if ($Variable)
            {
                if ($SessionState -eq $ExecutionContext.SessionState)
                {
                    $params = @{
                        Scope = 1
                        Name = $Variable.Name
                        Value = $Variable.Value
                        Force = $true
                        Confirm = $false
                        WhatIf = $false
                    }
                    Set-Variable @params
                }
                else
                {
                    $SessionState.PSVariable.Set($Variable.Name, $Variable.Value)
                }
            }
        }
    }
}

function Get-ParameterGroupName {
    [CmdletBinding(DefaultParameterSetName="Name")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Name")]
        [string]
        $RawName,

        [Parameter(Mandatory=$true, ParameterSetName="Postfix")]
        [string]
        $OperationId,

        [Parameter(Mandatory=$false, ParameterSetName="Postfix")]
        [string]
        $Postfix
    )

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        # AutoRest only capitalizes the first letter and the first letter after a hyphen
        $newName = ''
        $capitalize = $true
        foreach ($char in $RawName.ToCharArray()) {
            if ('-' -eq $char) {
                $capitalize = $true
            } elseif ($capitalize) {
                $capitalize = $false
                if ((97 -le $char) -and (122 -ge $char)) {
                    [char]$char = $char-32
                }

                $newName += $char
            } else {
                $newName += $char
            }
        }

        return Remove-SpecialCharacter -Name $newName
    } else {
        if (-not $Postfix) {
            $Postfix = "Parameters"
        }

        $split = $OperationId.Split('_')
        if ($split.Count -eq 2) {
            return "$($split[0])$($split[1])$Postfix"
        } else {
            # Don't ask
            return "HyphenMinus$($OperationId)HyphenMinus$Postfix"
        }
    }
}

function Get-FormattedFunctionContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('None', 'PSScriptAnalyzer')]
        [string]
        $Formatter,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Content
    )

    $singleStringContent = $Content | Out-String
    $singleStringContent = $singleStringContent -replace "`r`n","`n"
    $singleStringContent = $singleStringContent -replace "`r","`n"
    if ($Formatter -eq 'None') {
        $singleStringContent
    } elseif ($Formatter -eq 'PSScriptAnalyzer') {
        PSScriptAnalyzer\Invoke-Formatter -ScriptDefinition $singleStringContent
    } else {
        $singleStringContent
    }
}