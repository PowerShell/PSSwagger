#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Paths Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1)
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath SwaggerUtils.psm1)
. "$PSScriptRoot\PSSwagger.Constants.ps1" -Force
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

function Get-SwaggerSpecPathInfo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $PathFunctionDetails,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Info,
        
        [Parameter(Mandatory = $true)]
        [hashTable]
        $DefinitionList,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $JsonPathItemObject.value.PSObject.Properties | ForEach-Object {
        $operationId = $_.Value.operationId

        $FunctionDescription = ""
        if((Get-Member -InputObject $_.value -Name 'description') -and $_.value.description) {
            $FunctionDescription = $_.value.description 
        }
        
        $paramInfo = Get-PathParamInfo -JsonPathItemObject $_.value -Info $Info -DefinitionFunctionsDetails $DefinitionFunctionsDetails

        $responses = ""
        if((Get-Member -InputObject $_.value -Name 'responses') -and $_.value.responses) {
            $responses = $_.value.responses 
        }

        $FunctionDetails = @{}
        
        if((Get-Member -InputObject $_.value -Name 'x-ms-cmdlet-name') -and $_.value.'x-ms-cmdlet-name')
        {
            $FunctionDetails['CommandName'] = $_.value.'x-ms-cmdlet-name'
        } else {
            $FunctionDetails['CommandName'] = Get-PathCommandName -OperationId $operationId
        }

        $paramObject = Convert-ParamTable -ParamTable $paramInfo
        $FunctionDetails['ParamHelp'] = $paramObject['ParamHelp']
        $FunctionDetails['Paramblock'] = $paramObject['ParamBlock']
        $FunctionDetails['ParamblockWithAsJob'] = $paramObject['ParamBlockWithAsJob']
        $FunctionDetails['RequiredParamList'] = $paramObject['RequiredParamList']
        $FunctionDetails['OptionalParamList'] = $paramObject['OptionalParamList']

        $functionBodyParams = @{
            Responses = $responses
            Info = $Info
            DefinitionList = $DefinitionList
            operationId = $operationId
            RequiredParamList = $FunctionDetails['RequiredParamList']
            OptionalParamList = $FunctionDetails['OptionalParamList']
            SwaggerMetaDict = $SwaggerMetaDict
            SwaggerSpecDefinitionsAndParameters = $SwaggerSpecDefinitionsAndParameters
        }

        $bodyObject = Get-PathFunctionBody @functionBodyParams
        
        $FunctionDetails['Body'] = $bodyObject.body
        $FunctionDetails['OutputTypeBlock'] = $bodyObject.OutputTypeBlock
        $FunctionDetails['Description'] = $FunctionDescription
        $FunctionDetails['OperationId'] = $operationId
        $FunctionDetails['Responses'] = $responses
        $PathFunctionDetails[$operationId] = $FunctionDetails
    }
}

function New-SwaggerSpecPathCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $PathFunctionDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionsToExport = @()

    $PathFunctionDetails.Keys | ForEach-Object {
        $FunctionDetails = $PathFunctionDetails[$_]
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $FunctionDetails `
                                                -SwaggerMetaDict $SwaggerMetaDict
    }

    return $FunctionsToExport
}

function New-SwaggerPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $FunctionDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $commandName = $FunctionDetails.CommandName
    $description = $FunctionDetails.Description
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    $paramHelp = $FunctionDetails.ParamHelp
    $paramblock = $FunctionDetails.ParamBlock
    $paramblockWithAsJob = $FunctionDetails.ParamBlockWithAsJob
    $requiredParamList = $FunctionDetails.RequiredParamList
    $optionalParamList = $FunctionDetails.OptionalParamList

    $body = $FunctionDetails.Body
    $outputTypeBlock = $FunctionDetails.OutputTypeBlock

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignatureForPath)
    $GeneratedCommandsPath = Join-Path -Path (Join-Path -Path $SwaggerMetaDict['outputDirectory'] -ChildPath $GeneratedCommandsName) `
                                       -ChildPath 'SwaggerPathCommands'

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    Write-Verbose -Message $CommandString

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$commandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false
    return $commandName
}
