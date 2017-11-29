#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################

$helpDescStr = @'
.SYNOPSIS
    $synopsis

.DESCRIPTION
    $description
'@

$parameterAttributeString = '[Parameter(Mandatory = $isParamMandatory$ValueFromPipelineByPropertyNameString$ValueFromPipelineString$ParameterSetPropertyString)]'

$parameterDefString = @'
    
        $AllParameterSetsString$ParameterAliasAttribute$ValidateSetDefinition
        $paramType$paramName$parameterDefaultValueOption,

'@

$parameterDefaultValueString = ' = $parameterDefaultValue'

$DynamicAssemblyGenerationBlock = @'
`$dllFullName = Join-Path -Path `$ClrPath -ChildPath '$DllFileName'
if(-not (Test-Path -Path `$dllFullName -PathType Leaf)) {
    . (Join-Path -Path `$PSScriptRoot -ChildPath 'AssemblyGenerationHelpers.ps1')
    New-SDKAssembly -AssemblyFileName '$DllFileName' -IsAzureSDK:`$$UseAzureCSharpGenerator
}
'@

$RootModuleContents = @'
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

# If the user supplied -Prefix to Import-Module, that applies to the nested module as well
# Force import the nested module again without -Prefix
if (-not (Get-Command Get-OperatingSystemInfo -Module PSSwaggerUtility -ErrorAction Ignore)) {
    Import-Module PSSwaggerUtility -Force
}

if ((Get-OperatingSystemInfo).IsCore) {
    $testCoreModuleRequirements`$clr = 'coreclr'
}
else {
    $testFullModuleRequirements`$clr = 'fullclr'
}

`$ClrPath = Join-Path -Path `$PSScriptRoot -ChildPath 'ref' | Join-Path -ChildPath `$clr
$DynamicAssemblyGenerationCode
`$allDllsPath = Join-Path -Path `$ClrPath -ChildPath '*.dll'
if (Test-Path -Path `$ClrPath -PathType Container) {
    Get-ChildItem -Path `$allDllsPath -File | ForEach-Object { Add-Type -Path `$_.FullName -ErrorAction SilentlyContinue }
}

. (Join-Path -Path `$PSScriptRoot -ChildPath 'New-ServiceClient.ps1')
. (Join-Path -Path `$PSScriptRoot -ChildPath 'Get-TaskResult.ps1')
$(if($UseAzureCsharpGenerator) {
". (Join-Path -Path `$PSScriptRoot -ChildPath 'Get-ArmResourceIdParameterValue.ps1')"
})
`$allPs1FilesPath = Join-Path -Path `$PSScriptRoot -ChildPath '$GeneratedCommandsName' | Join-Path -ChildPath '*.ps1'
Get-ChildItem -Path `$allPs1FilesPath -Recurse -File | ForEach-Object { . `$_.FullName}
'@

$advFnSignatureForDefintion = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
    param($paramblock
    )
    $body
}
'@

$AsJobParameterString = @'

        [Parameter(Mandatory = $false)]
        [switch]
        $AsJob
'@


$advFnSignatureForPath = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
    $outputTypeBlock[CmdletBinding(DefaultParameterSetName='$DefaultParameterSetName')]
    param($ParamBlockReplaceStr
    )

    Begin 
    {
	    $dependencyInitFunction
        `$tracerObject = `$null
        if (('continue' -eq `$DebugPreference) -or ('inquire' -eq `$DebugPreference)) {
            `$oldDebugPreference = `$global:DebugPreference
			`$global:DebugPreference = "continue"
            `$tracerObject = New-PSSwaggerClientTracing
            Register-PSSwaggerClientTracing -TracerObject `$tracerObject
        }
	}

    Process {
    $body

    $PathFunctionBody
    }

    End {
        if (`$tracerObject) {
            `$global:DebugPreference = `$oldDebugPreference
            Unregister-PSSwaggerClientTracing -TracerObject `$tracerObject
        }
    }
}
'@

$helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

$oDataExpressionBlockStr = @'


    `$oDataQuery = ""
    $oDataExpression
    `$oDataQuery = `$oDataQuery.Trim("&")
'@

$parameterGroupCreateExpression = @'
`$$groupName = New-Object -TypeName $fullGroupName
'@

$parameterGroupPropertyExpression = @'
    if (`$PSBoundParameters.ContainsKey('$parameterGroupPropertyName')) { `$$groupName.$parameterGroupPropertyName = `$$parameterGroupPropertyName }
'@

$constructFlattenedParameter = @'
    
    `$flattenedParameters = $flattenedParametersListStr
    `$utilityCmdParams = @{}
    `$flattenedParameters | ForEach-Object {
        if(`$PSBoundParameters.ContainsKey(`$_)) {
            `$utilityCmdParams[`$_] = `$PSBoundParameters[`$_]
        }
    }
    `$$SwaggerOperationParameterName = New-$($FlattenedParamType)Object @utilityCmdParams

'@

$functionBodyStr = @'

    `$ErrorActionPreference = 'Stop'

    `$NewServiceClient_params = @{
        FullClientTypeName = '$FullClientTypeName'
    }
$(
if($AuthenticationCommand){
"
    `$NewServiceClient_params['AuthenticationCommand'] = @'
    $AuthenticationCommand
`'@ "
    if($AuthenticationCommandArgumentName){
"
    `$NewServiceClient_params['AuthenticationCommandArgumentList'] = `$$AuthenticationCommandArgumentName"
    }
}
if($AddHttpClientHandler){
"
    `$NewServiceClient_params['AddHttpClientHandler'] = `$true
    `$NewServiceClient_params['Credential']           = `$Credential"
}
if($hostOverrideCommand){
"
    `$NewServiceClient_params['HostOverrideCommand'] = @'
    $hostOverrideCommand
`'@"
}
if($GlobalParameters) {
'
    $GlobalParameterHashtable = @{} '
    
    foreach($parameter in $GlobalParameters) {
"    
    `$GlobalParameterHashtable['$parameter'] = `$null
    if(`$PSBoundParameters.ContainsKey('$parameter')) {
        `$GlobalParameterHashtable['$parameter'] = `$PSBoundParameters['$parameter']
    }
"
    }
"
    `$NewServiceClient_params['GlobalParameterHashtable'] = `$GlobalParameterHashtable "
}
)
    $clientName = New-ServiceClient @NewServiceClient_params
    $oDataExpressionBlock
    $parameterGroupsExpressionBlock
    $flattenedParametersBlock
    $ParameterAliasMappingBlock
    $ResourceIdParamCodeBlock

    $parameterSetBasedMethodStr else {
        Write-Verbose -Message 'Failed to map parameter set to operation method.'
        throw 'Module failed to find operation to execute.'
    }
'@

$parameterSetBasedMethodStrIfCase = @'
if ($ParameterSetConditionsStr) {
$additionalConditionStart$methodBlock$additionalConditionEnd
    }
'@

$parameterSetBasedMethodStrElseIfCase = @'
 elseif ($ParameterSetConditionsStr) {
$additionalConditionStart$methodBlock$additionalConditionEnd
    }
'@

$methodBlockFunctionCall = @'
        Write-Verbose -Message 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($ParamList)
'@

$methodBlockCmdletCall = @'
        Write-Verbose -Message 'Calling cmdlet $Cmdlet.'
        $Cmdlet $CmdletArgs
        `$taskResult = `$null
'@

$PathFunctionBodyAsJob = @'
Write-Verbose -Message "Waiting for the operation to complete."

    `$PSSwaggerJobScriptBlock = {
        [CmdletBinding()]
        param(    
            [Parameter(Mandatory = `$true)]
            [System.Threading.Tasks.Task]
            `$TaskResult,

            [Parameter(Mandatory = `$true)]
			[string]
			`$TaskHelperFilePath
        )
        if (`$TaskResult) {
            . `$TaskHelperFilePath
            `$TopInfo = $TopPagingObjectStr
            `$SkipInfo = $SkipPagingObjectStr
            `$PageResult = $PageResultPagingObjectStr
            `$PageTypeType = $PageTypePagingObjectStr
            Get-TaskResult -TaskResult `$TaskResult -SkipInfo `$SkipInfo -TopInfo `$TopInfo -PageResult `$PageResult -PageType `$PageTypeType
            $pagingBlock
        }
    }

    `$PSCommonParameters = Get-PSCommonParameter -CallerPSBoundParameters `$PSBoundParameters

    if(`$AsJob)
    {
        `$ScriptBlockParameters = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,object]'
        `$ScriptBlockParameters['TaskResult'] = `$TaskResult
        `$ScriptBlockParameters['AsJob'] = `$AsJob
        `$ScriptBlockParameters['TaskHelperFilePath'] = Join-Path -Path `$ExecutionContext.SessionState.Module.ModuleBase -ChildPath 'Get-TaskResult.ps1'
        `$PSCommonParameters.GetEnumerator() | ForEach-Object { `$ScriptBlockParameters[`$_.Name] = `$_.Value }

        Start-PSSwaggerJobHelper -ScriptBlock `$PSSwaggerJobScriptBlock ``
                                     -CallerPSBoundParameters `$ScriptBlockParameters ``
                                     -CallerPSCmdlet `$PSCmdlet ``
                                     @PSCommonParameters
    }
    else
    {
        Invoke-Command -ScriptBlock `$PSSwaggerJobScriptBlock ``
                       -ArgumentList `$taskResult ``
                       @PSCommonParameters
    }
'@

$PathFunctionBodySynch = @'
if (`$TaskResult) {
        `$TopInfo = $TopPagingObjectStr
        `$SkipInfo = $SkipPagingObjectStr
        `$PageResult = $PageResultPagingObjectStr
        `$PageTypeType = $PageTypePagingObjectStr
        Get-TaskResult -TaskResult `$TaskResult -SkipInfo `$SkipInfo -TopInfo `$TopInfo -PageResult `$PageResult -PageType `$PageTypeType
        $pagingBlock
    }
'@

$TopPagingObjectBlock = @'
@{
            'Count' = 0
            'Max' = $Top
        }
'@

$SkipPagingObjectBlock = @'
@{
            'Count' = 0
            'Max' = $Skip
        }
'@

$PageResultPagingObjectBlock = @'
@{
            'Result' = $null
        }
'@

$PageTypeObjectBlock = @'
"$pageType" -as [Type]
'@

$PagingBlockStrGeneric = @'
    
        Write-Verbose -Message 'Flattening paged results.'
        while (`$PageResult -and `$PageResult.Result -and (Get-Member -InputObject `$PageResult.Result -Name '$NextLinkName') -and `$PageResult.Result.'$NextLinkName' -and ((`$TopInfo -eq `$null) -or (`$TopInfo.Max -eq -1) -or (`$TopInfo.Count -lt `$TopInfo.Max))) {
            `$PageResult.Result = `$null
            Write-Debug -Message "Retrieving next page: `$(`$PageResult.Result.'$NextLinkName')"
            $pagingOperationCall
        }
'@

$PagingOperationCallFunction = @'
`$taskResult = $clientName$pagingOperations.$pagingOperationName(`$PageResult.Result.'$NextLinkName')
            Get-TaskResult -TaskResult `$TaskResult -SkipInfo `$SkipInfo -TopInfo `$TopInfo -PageResult `$PageResult -PageType `$PageTypeType
'@

$PagingOperationCallCmdlet = @'
$Cmdlet $CmdletArgs
'@

$ValidateSetDefinitionString = @'

        [ValidateSet($ValidateSetString)]
'@

$ParameterAliasAttributeString = @'

        [Alias($AliasString)]
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
                    {200..299 -contains `$responseStatusCode} {
                        $successReturn
                    }$failWithDesc
                    
                    Default {Write-Error -Message "Status: `$responseStatusCode received."}
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

    `$PSBoundParameters.GetEnumerator() | ForEach-Object { 
        if(Get-Member -InputObject `$Object -Name `$_.Key -MemberType Property)
        {
            `$Object.`$(`$_.Key) = `$_.Value
        }
    }

    if(Get-Member -InputObject `$Object -Name Validate -MemberType Method)
    {
        `$Object.Validate()
    }

    return `$Object
'@

$GeneratedCommandsName = 'Generated.PowerShell.Commands'

$FormatViewDefinitionStr = @'
<?xml version="1.0" encoding="utf-8" ?>
{4}
<Configuration>
    <ViewDefinitions>
        <View>
            <Name>{0}</Name>
            <ViewSelectedBy>
                <TypeName>{1}</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
{2}
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
{3}
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

$TableColumnItemStr = @'
                            <TableColumnItem>
                                <PropertyName>{0}</PropertyName>
                            </TableColumnItem>
'@

$TableColumnHeaderStr = @'
                    <TableColumnHeader>
                        <Width>{0}</Width>
                    </TableColumnHeader>
'@

$LastTableColumnHeaderStr = @'
                    <TableColumnHeader/>
'@

$DefaultGeneratedFileHeader = @'
Code generated by Microsoft (R) PSSwagger {0}
Changes may cause incorrect behavior and will be lost if the code is regenerated.
'@

$PSCommentFormatString = "<#
{0}
#>
"

$XmlCommentFormatString = "<!--
{0}
-->
"

$DefaultGeneratedFileHeaderWithoutVersion = @'
Code generated by Microsoft (R) PSSwagger
Changes may cause incorrect behavior and will be lost if the code is regenerated.
'@

$MicrosoftApacheLicenseHeader = @'
Copyright (c) Microsoft and contributors.  All rights reserved.

Licensed under the Apache License, Version 2.0 (the ""License"");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

See the License for the specific language governing permissions and
limitations under the License.
'@

$MicrosoftMitLicenseHeader = @'
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the MIT License. See License.txt in the project root for license information.
'@

