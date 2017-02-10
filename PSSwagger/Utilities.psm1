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
