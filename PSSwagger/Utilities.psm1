#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Utilities Module
#
#########################################################################################

function Get-PascalCasedString
{
    param([string] $Name)

    if($Name) {
        $Name = Remove-SpecialCharacter -Name $Name
        $startIndex = 0
        $subStringLength = 1

        # Convert the two letter abbreviations to upper case.
        # Example: vmName --> VMName
        if($Name.Length -gt 2) {
            $thirdCharString = $Name.substring(2, 1)
            if($thirdCharString.ToUpper() -ceq $thirdCharString) {
                $subStringLength = 2
            }
        }

        return $($Name.substring($startIndex, $subStringLength)).ToUpper() + $Name.substring($subStringLength)
    }

}

function Remove-SpecialCharacter
{
    param([string] $Name)

    $pattern = '[^a-zA-Z]'
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

    $Variables.keys | ForEach-Object {
        $VariableName = $_
        $VariableValue = $Variables[$_]

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
