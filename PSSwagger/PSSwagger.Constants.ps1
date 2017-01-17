#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Localized PSSwagger.Constants.ps1
#
#########################################################################################

    $helpDescStr = @'
.DESCRIPTION
    $description
'@

    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)] $ValidateSetDefinition    
    [$paramType]
    $paramName,

'@

    $RootModuleContents = @'
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName" -Recurse -Filter *.ps1 -File | ForEach-Object { . `$_.FullName}
'@

    $advFnSignature = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
   $outputTypeBlock[CmdletBinding()]
   param($paramblock
   )

   $body
}
'@

    $helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

    $functionBodyStr = @'
 `$serviceCredentials =  Get-AzServiceCredential
    `$subscriptionId = Get-AzSubscriptionId
    `$delegatingHandler = Get-AzDelegatingHandler

    $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler
    $apiVersion
    $clientName.SubscriptionId = `$subscriptionId
    
    Write-Verbose 'Performing operation $methodName on $clientName.'
    `$taskResult = $clientName$operations.$methodName($requiredParamList)
    Write-Verbose "Waiting for the operation to complete."
    `$null = `$taskResult.AsyncWaitHandle.WaitOne()
    Write-Debug "`$(`$taskResult | Out-String)"

    if(`$taskResult.IsFaulted) {
       Write-Verbose 'Operation failed.'
       Throw "`$(`$taskResult.Exception.InnerExceptions | Out-String)"
    } elseif (`$taskResult.IsCanceled) {
       Write-Verbose 'Operation got cancelled.'
       Throw 'Operation got cancelled.'
    } else {
        Write-Verbose 'Operation completed successfully.'

        if(`$taskResult.Result -and 
           (Get-Member -InputObject `$taskResult.Result -Name 'Body') -and
           `$taskResult.Result.Body) 
        {
            `$responseStatusCode = `$taskResult.Result.Response.StatusCode.value__
            $responseBody
        }
    }   
'@

    $ValidateSetDefinitionString = @'

    [ValidateSet($ValidateSetString)]
'@

$successReturn = @'
Write-Verbose "Operation completed with return code: `$responseStatusCode."
                    $result = $taskResult.Result.Body
                    Write-Verbose -Message "$($result | Out-String)"
                    $result
'@

$responseBodySwitchCase = @'
switch (`$responseStatusCode)
            {
                {200..299 -contains `$responseStatusCode}{
                    $successReturn
                }$failWithDesc
                Default {Write-Error "Status: `$responseStatusCode received."}
            }
'@

$failCase = @'

    {`$responseStatusCode} {
        $responseStatusValue {$failureDescription}
    }
'@

    $outputTypeStr = @'
[OutputType([$fullPathDataType])]
   
'@

    $createObjectStr = @'

   `$Object = New-Object -TypeName $DefinitionTypeName

   `$PSBoundParameters.Keys | ForEach-Object { 
       `$Object.`$_ = `$PSBoundParameters[`$_]
   }

   if(Get-Member -InputObject `$Object -Name Validate -MemberType Method)
   {
       `$Object.Validate()
   }

   return `$Object
'@
