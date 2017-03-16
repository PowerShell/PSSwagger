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

        [Parameter(Mandatory = $true)]
        [hashTable]
        $swaggerDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $JsonPathItemObject.value.PSObject.Properties | ForEach-Object {
        $operationId = $_.Value.operationId

        $FunctionDescription = ""
        if((Get-Member -InputObject $_.value -Name 'description') -and $_.value.description) {
            $FunctionDescription = $_.value.description 
        }
        
        $paramInfo = Get-PathParamInfo -JsonPathItemObject $_.value `
                                       -SwaggerDict $swaggerDict `
                                       -DefinitionFunctionsDetails $DefinitionFunctionsDetails

        $responses = ""
        if((Get-Member -InputObject $_.value -Name 'responses') -and $_.value.responses) {
            $responses = $_.value.responses 
        }

        
        $paramObject = Convert-ParamTable -ParamTable $paramInfo
        if((Get-Member -InputObject $_.value -Name 'x-ms-cmdlet-name') -and $_.value.'x-ms-cmdlet-name')
        {
            $commandNames = $_.value.'x-ms-cmdlet-name'
        } else {
            $commandNames = Get-PathCommandName -OperationId $operationId
        }

        $ParameterSetDetail = @{
            Description = $FunctionDescription
            ParameterDetails = $paramInfo
            RequiredParamList = $paramObject['RequiredParamList']
            OptionalParamList = $paramObject['OptionalParamList']
            Responses = $responses
            OperationId = $operationId
            Priority = 100 # Default
        }

        # There's probably a better way to do this...
        $opIdValues = $operationId -split "_",2
        if(-not $opIdValues -or ($opIdValues.Count -ne 2)) {
            $approximateVerb = $operationId
        } else {
            $approximateVerb = $opIdValues[1]
        }

        if ($approximateVerb.StartsWith("List")) {
            $ParameterSetDetail.Priority = 0
        }

        $commandNames | ForEach-Object {
            $FunctionDetails = @{}
            if ($PathFunctionDetails.ContainsKey($_)) {
                $FunctionDetails = $PathFunctionDetails[$_]
            } else {
                $FunctionDetails['CommandName'] = $_
            }

            $ParameterSetDetails = @()
            if ($FunctionDetails.ContainsKey('ParameterSetDetails')) {
                $ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
            } 

            $ParameterSetDetails += $ParameterSetDetail
            $FunctionDetails['ParameterSetDetails'] = $ParameterSetDetails
            $PathFunctionDetails[$_] = $FunctionDetails
        }
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
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerDict
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionsToExport = @()
    $PathFunctionDetails.Keys | ForEach-Object {
        $FunctionDetails = $PathFunctionDetails[$_]
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $FunctionDetails `
                                              -SwaggerMetaDict $SwaggerMetaDict `
                                              -SwaggerDict $SwaggerDict
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
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerDict
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $commandName = $FunctionDetails.CommandName
    $parameterSetDetails = $FunctionDetails['ParameterSetDetails']

    $description = ''
    $paramBlock = ''
    $paramHelp = ''
    $parametersToAdd = @{}
    $parameterHitCount = @{}
    foreach ($parameterSetDetail in $parameterSetDetails) {
        foreach ($parameterDetails in $parameterSetDetail.ParameterDetails.Values) {
            $parameterName = $parameterDetails.Name
            if($parameterDetails.IsParameter) {
                if (-not $parameterHitCount.ContainsKey($parameterName)) {
                    $parameterHitCount[$parameterName] = 0
                }

                $parameterHitCount[$parameterName]++
                if (-not ($parametersToAdd.ContainsKey($parameterName))) {
                    $parametersToAdd[$parameterName] = @{
                        # We can grab details like Type, Name, ValidateSet from any of the parameter definitions
                        Details = $parameterDetails
                        ParameterSetInfo = @(@{
                            Name = $parameterSetDetail.OperationId
                            Mandatory = $parameterDetails.Mandatory
                        })
                    }
                } else {
                    $parametersToAdd[$parameterName].ParameterSetInfo += @{
                                                                                Name = $parameterSetDetail.OperationId
                                                                                Mandatory = $parameterDetails.Mandatory
                                                                          }
                }
            }
        }
    }

    $nonUniqueParameterSets = @()
    foreach ($parameterSetDetail in $parameterSetDetails) {
        $isUnique = $false
        foreach ($parameterDetails in $parameterSetDetail.ParameterDetails.Values) {
            if ($parameterHitCount[$parameterDetails.Name] -eq 1) {
                $isUnique = $true
                break
            }
        }
        if (-not $isUnique) {
            # At this point none of the parameters in this set are unique
            $nonUniqueParameterSets += $parameterSetDetail
        }
    }

    # For description, we're currently using the default parameter set's description, since concatenating multiple descriptions doesn't ever really work out well.
    if ($nonUniqueParameterSets.Length -gt 1) {
        # Pick the highest priority set among $nonUniqueParameterSets, but really it doesn't matter, cause...
        # Print warning that this generated cmdlet has ambiguous parameter sets
        $defaultParameterSet = $nonUniqueParameterSets | Sort-Object -Property Priority | Select-Object -First 1
        $DefaultParameterSetName = $defaultParameterSet.OperationId
        $description = $defaultParameterSet.Description
        Write-Warning -Message ($LocalizedDataCmdletHasAmbiguousParameterSets -f ($commandName))
    } elseif ($nonUniqueParameterSets.Length -eq 1) {
        # If there's only one non-unique, we can prevent errors by making this the default
        $DefaultParameterSetName = $nonUniqueParameterSets[0].OperationId
        $description = $nonUniqueParameterSets[0].Description
    } else {
        # Pick the highest priority set among all sets
        $defaultParameterSet = $parameterSetDetails | Sort-Object -Property Priority | Select-Object -First 1
        $DefaultParameterSetName = $defaultParameterSet.OperationId
        $description = $defaultParameterSet.Description
    }
    
    foreach ($parameterToAdd in $parametersToAdd.Values) {
        $parameterName = $parameterToAdd.Details.Name
        $AllParameterSetsString = ''
        foreach ($parameterSetInfo in $parameterToAdd.ParameterSetInfo) {
            $isParamMandatory = $parameterSetInfo.Mandatory
            $ParameterSetPropertyString = ", ParameterSetName = '$($parameterSetInfo.Name)'"
            if ($AllParameterSetsString) {
                # Two tabs
                $AllParameterSetsString += [Environment]::NewLine + "        " + $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
            } else {
                $AllParameterSetsString = $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
            }
        }

        $paramName = "`$$parameterName" 
        $paramType = $parameterToAdd.Details.Type

        $ValidateSetDefinition = $null
        if ($parameterToAdd.Details.ValidateSet)
        {
            $ValidateSetString = $parameterToAdd.Details.ValidateSet
            $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
        }

        $paramBlock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
        $pDescription = $parameterToAdd.Details.Description
        $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
    }

    $paramBlock = $paramBlock.TrimEnd().TrimEnd(",")
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)
    if ($paramBlock) {
        $paramblockWithAsJob = $paramBlock + ",`r`n" + $AsJobParameterString
    } else {
        $paramblockWithAsJob = $AsJobParameterString
    }
    
    $functionBodyParams = @{
                ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
                SwaggerDict = $SwaggerDict
                SwaggerMetaDict = $SwaggerMetaDict
            }

    $bodyObject = Get-PathFunctionBody @functionBodyParams

    $body = $bodyObject.Body
    $outputTypeBlock = $bodyObject.OutputTypeBlock

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
