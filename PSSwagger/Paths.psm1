#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Paths Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1) -DisableNameChecking
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath SwaggerUtils.psm1) -DisableNameChecking
. "$PSScriptRoot\PSSwagger.Constants.ps1" -Force
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1
$script:AppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PSSwagger\'

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
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ParameterGroupCache
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    
    $JsonPathItemObject.value.PSObject.Properties | ForEach-Object {
        if(Get-Member -InputObject $_.Value -Name 'OperationId')
        {
            $operationId = $_.Value.operationId
            Write-Verbose -Message ($LocalizedData.GettingSwaggerSpecPathInfo -f $operationId)

            $FunctionDescription = ""
            if((Get-Member -InputObject $_.value -Name 'description') -and $_.value.description) {
                $FunctionDescription = $_.value.description 
            }
            
            $paramInfo = Get-PathParamInfo -JsonPathItemObject $_.value `
                                        -SwaggerDict $swaggerDict `
                                        -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                        -ParameterGroupCache $ParameterGroupCache

            $responses = ""
            if((Get-Member -InputObject $_.value -Name 'responses') -and $_.value.responses) {
                $responses = $_.value.responses 
            }

            if((Get-Member -InputObject $_.value -Name 'x-ms-cmdlet-name') -and $_.value.'x-ms-cmdlet-name')
            {
                $commandNames = $_.value.'x-ms-cmdlet-name'
            } else {
                $commandNames = Get-PathCommandName -OperationId $operationId
            }

            $ParameterSetDetail = @{
                Description = $FunctionDescription
                ParameterDetails = $paramInfo
                Responses = $responses
                OperationId = $operationId
                Priority = 100 # Default
            }

            if ((Get-Member -InputObject $_.Value -Name 'x-ms-odata') -and $_.Value.'x-ms-odata') {
                # Currently only the existence of this property is really important, but might as well save the value
                $ParameterSetDetail.'x-ms-odata' = $_.Value.'x-ms-odata'
            }

            # There's probably a better way to do this...
            $opIdValues = $operationId -split "_",2
            if(-not $opIdValues -or ($opIdValues.Count -ne 2)) {
                $approximateVerb = $operationId
            } else {
                $approximateVerb = $opIdValues[1]
                if ((-not $UseAzureCsharpGenerator) -and 
                    (Test-OperationNameInDefinitionList -Name $opIdValues[0] -SwaggerDict $swaggerDict))
                { 
                    $ParameterSetDetail['UseOperationsSuffix'] = $true
                }
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
        else 
        {
            $Message = $LocalizedData.UnsupportedSwaggerProperties -f ('JsonPathItemObject', $($_.Value | Out-String))
            Write-Warning -Message $Message
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
    $Info = $swaggerDict['Info']
    $modulePostfix = $Info['infoName']
    $NameSpace = $info.namespace
    $fullModuleName = $Namespace + '.' + $modulePostfix

    $FunctionsToExport = @()
    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $_.Value `
                                              -SwaggerMetaDict $SwaggerMetaDict `
                                              -SwaggerDict $SwaggerDict
    }

    return $FunctionsToExport
}

function Add-UniqueParameter {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $CandidateParameterDetails,

        [Parameter(Mandatory=$true)]
        [string]
        $OperationId,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ParametersToAdd,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ParameterHitCount
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameterName = $CandidateParameterDetails.Name
    if($parameterDetails.IsParameter) {
        if (-not $parameterHitCount.ContainsKey($parameterName)) {
            $parameterHitCount[$parameterName] = 0
        }

        $parameterHitCount[$parameterName]++
        if (-not ($parametersToAdd.ContainsKey($parameterName))) {
            $parametersToAdd[$parameterName] = @{
                # We can grab details like Type, Name, ValidateSet from any of the parameter definitions
                Details = $CandidateParameterDetails
                ParameterSetInfo = @{$OperationId = @{
                    Name = $OperationId
                    Mandatory = $CandidateParameterDetails.Mandatory
                }}
            }
        } else {
            $parametersToAdd[$parameterName].ParameterSetInfo[$OperationId] = @{
                                                                        Name = $OperationId
                                                                        Mandatory = $CandidateParameterDetails.Mandatory
                                                                    }
        }
    }
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
        $parameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
            $parameterDetails = $_.Value
            if ($parameterDetails.ContainsKey('x_ms_parameter_grouping_group')) {
                foreach ($parameterDetailEntry in $parameterDetails.'x_ms_parameter_grouping_group'.GetEnumerator()) {
                    Add-UniqueParameter -CandidateParameterDetails $parameterDetailEntry.Value -OperationId $parameterSetDetail.OperationId -ParametersToAdd $parametersToAdd -ParameterHitCount $parameterHitCount
                }
            } else {
                Add-UniqueParameter -CandidateParameterDetails $parameterDetails -OperationId $parameterSetDetail.OperationId -ParametersToAdd $parametersToAdd -ParameterHitCount $parameterHitCount
            }
        }
    }

    $nonUniqueParameterSets = @()
    foreach ($parameterSetDetail in $parameterSetDetails) {
        $isUnique = $false
        $parameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
            $parameterDetails = $_.Value
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
        Write-Warning -Message ($LocalizedData.CmdletHasAmbiguousParameterSets -f ($commandName))
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

    $oDataExpression = ""
    $oDataExpressionBlock = ""
    # Variable used to replace in function body
    $parameterGroupsExpressionBlock = ""
    # Variable used to store all group expressions, concatenate, then store in $parameterGroupsExpressionBlock
    $parameterGroupsExpressions = @{}
    $parametersToAdd.GetEnumerator() | ForEach-Object {
        $parameterToAdd = $_.Value
        $parameterName = $parameterToAdd.Details.Name
        $AllParameterSetsString = ''
        foreach ($parameterSetInfoEntry in $parameterToAdd.ParameterSetInfo.GetEnumerator()) {
            $parameterSetInfo = $parameterSetInfoEntry.Value
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
        $ValidateSetDefinition = $null
        if ($parameterToAdd.Details.ValidateSet)
        {
            $ValidateSetString = $parameterToAdd.Details.ValidateSet
            $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
        }

        $parameterDefaultValueOption = ""
        if ($parameterToAdd.Details.ContainsKey('ExtendedData')) {
            if ($parameterToAdd.Details.ExtendedData.ContainsKey('IsODataParameter') -and $parameterToAdd.Details.ExtendedData.IsODataParameter) {
                $paramType = "$($parameterToAdd.Details.Type)"
                $oDataExpression += "    if (`$$parameterName) { `$oDataQuery += `"&```$$parameterName=`$$parameterName`" }" + [Environment]::NewLine
            } else {
                # Assuming you can't group ODataQuery parameters
                if ($parameterToAdd.Details.ContainsKey('x_ms_parameter_grouping') -and $parameterToAdd.Details.'x_ms_parameter_grouping') {
                    $parameterGroupPropertyName = $parameterToAdd.Details.Name
                    $groupName = $parameterToAdd.Details.'x_ms_parameter_grouping'
                    $fullGroupName = $parameterToAdd.Details.ExtendedData.GroupType
                    if ($parameterGroupsExpressions.ContainsKey($groupName)) {
                        $parameterGroupsExpression = $parameterGroupsExpressions[$groupName]
                    } else {
                        $parameterGroupsExpression = $executionContext.InvokeCommand.ExpandString($parameterGroupCreateExpression)
                    }

                    $parameterGroupsExpression += [Environment]::NewLine + $executionContext.InvokeCommand.ExpandString($parameterGroupPropertyExpression)
                    $parameterGroupsExpressions[$groupName] = $parameterGroupsExpression
                }

                $paramType = "$($parameterToAdd.Details.ExtendedData.Type)"
                if ($parameterToAdd.Details.ExtendedData.HasDefaultValue) {
                    if ($parameterToAdd.Details.ExtendedData.DefaultValue) {
                        if ([NullString]::Value -eq $parameterToAdd.Details.ExtendedData.DefaultValue) {
                            $parameterDefaultValue = "[NullString]::Value"
                        } elseif ("System.String" -eq $parameterToAdd.Details.ExtendedData.Type) {
                            $parameterDefaultValue = "`"$($parameterToAdd.Details.ExtendedData.DefaultValue)`""
                        } else {
                            $parameterDefaultValue = "$($parameterToAdd.Details.ExtendedData.DefaultValue)"
                        }
                    } else {
                        $parameterDefaultValue = "`$null"
                    }

                    $parameterDefaultValueOption = $executionContext.InvokeCommand.ExpandString($parameterDefaultValueString)
                }
            }

            $paramBlock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
            $pDescription = $parameterToAdd.Details.Description
            $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
        } else {
            Write-Warning ($LocalizedData.ParameterMissingFromAutoRestCode -f ($parameterName, $commandName))
        }
    }

    foreach ($parameterGroupsExpressionEntry in $parameterGroupsExpressions.GetEnumerator()) {
        $parameterGroupsExpressionBlock += $parameterGroupsExpressionEntry.Value + [Environment]::NewLine
    }

    if ($oDataExpression) {
        $oDataExpression = $oDataExpression.Trim()
        $oDataExpressionBlock = $executionContext.InvokeCommand.ExpandString($oDataExpressionBlockStr)
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
                                ODataExpressionBlock = $oDataExpressionBlock
                                ParameterGroupsExpressionBlock = $parameterGroupsExpressionBlock
                                SwaggerDict = $SwaggerDict
                                SwaggerMetaDict = $SwaggerMetaDict
                           }

    $pathGenerationPhaseResult = Get-PathFunctionBody @functionBodyParams
    $bodyObject = $pathGenerationPhaseResult.BodyObject

    $body = $bodyObject.Body
    $outputTypeBlock = $bodyObject.OutputTypeBlock

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignatureForPath)
    $GeneratedCommandsPath = Join-Path -Path (Join-Path -Path $SwaggerMetaDict['outputDirectory'] -ChildPath $GeneratedCommandsName) `
                                       -ChildPath 'SwaggerPathCommands'

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$commandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    Write-Verbose -Message ($LocalizedData.GeneratedPathCommand -f $commandName)

    return $commandName
}

function Set-ExtendedCodeMetadata {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $MainClientTypeName,

        [Parameter(Mandatory=$true)]
        [string]
        $CliXmlTmpPath
    )

    $resultRecord = @{
        VerboseMessages = @()
        ErrorMessages = @()
        WarningMessages = @()
    }
    
    $resultRecord.VerboseMessages += $LocalizedData.ExtractingMetadata

    $PathFunctionDetails = Import-CliXml -Path $CliXmlTmpPath
    $errorOccurred = $false
    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $FunctionDetails = $_.Value
        $ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
        foreach ($parameterSetDetail in $ParameterSetDetails) {
            if ($errorOccurred) {
                return
            }
            
            $operationId = $parameterSetDetail.OperationId
            $methodName = ''
            $operations = ''
            $operationsWithSuffix = ''
            $opIdValues = $operationId -split '_',2 
            if(-not $opIdValues -or ($opIdValues.count -ne 2)) {
                $methodName = $operationId + 'WithHttpMessagesAsync'
            } else {            
                $operationName = $opIdValues[0]
                $operationType = $opIdValues[1]
                $operations = ".$operationName"
                if ($parameterSetDetail['UseOperationsSuffix'] -and $parameterSetDetail['UseOperationsSuffix'])
                { 
                    $operationsWithSuffix = $operations + 'Operations'
                }

                $methodName = $operationType + 'WithHttpMessagesAsync'
            }

            $parameterSetDetail['MethodName'] = $methodName
            $parameterSetDetail['Operations'] = $operations

            # For some reason, moving this out of this loop causes issues
            $clientType = $MainClientTypeName -as [Type]
            if (-not $clientType) {
                $resultRecord.ErrorMessages += $LocalizedData.ExpectedServiceClientTypeNotFound -f ($MainClientTypeName)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                $errorOccurred = $true
                return
            }

            if ($operationsWithSuffix) {
                $operationName = $operationsWithSuffix.Substring(1)
                $propertyObject = $clientType.GetProperties() | Where-Object { $_.Name -eq $operationName } | Select-Object -First 1 -ErrorAction Ignore
                if (-not $propertyObject) {
                    # The Operations suffix logic isn't rock solid, so this is safety check.
                    $operationName = $operations.Substring(1)
                    $propertyObject = $clientType.GetProperties() | Where-Object { $_.Name -eq $operationName } | Select-Object -First 1 -ErrorAction Ignore
                    if (-not $propertyObject) {
                        $resultRecord.ErrorMessages += $LocalizedData.ExpectedOperationsClientTypeNotFound -f ($operationName, $clientType)
                        Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                        $errorOccurred = $true
                        return
                    }
                } else {
                    $parameterSetDetail['Operations'] = $operationsWithSuffix
                }

                $clientType = $propertyObject.PropertyType
            } elseif ($operations) {
                $operationName = $operations.Substring(1)
                $propertyObject = $clientType.GetProperties() | Where-Object { $_.Name -eq $operationName } | Select-Object -First 1 -ErrorAction Ignore
                if (-not $propertyObject) {
                    $resultRecord.ErrorMessages += $LocalizedData.ExpectedOperationsClientTypeNotFound -f ($operationName, $clientType)
                    Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                    $errorOccurred = $true
                    return
                }

                $clientType = $propertyObject.PropertyType
            }

            $methodInfo = $clientType.GetMethods() | Where-Object { $_.Name -eq $MethodName } | Select-Object -First 1
            if (-not $methodInfo) {
                $resultRecord.ErrorMessages += $LocalizedData.ExpectedMethodOnTypeNotFound -f ($MethodName, $clientType)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                $errorOccurred = $true
                return
            }
            # TODO: The parameter group will never be in the parameter details list
            $paramObject = $parameterSetDetail.ParameterDetails
            $ParamList = @()
            $oDataQueryFound = $false
            $methodInfo.GetParameters() | Sort-Object -Property Position | ForEach-Object {
                $hasDefaultValue = $_.HasDefaultValue
                # All Types should be converted to their string names, otherwise the CLI XML gets too large
                $type = $_.ParameterType.ToString()
                $metadata = @{
                    Name = Get-PascalCasedString -Name $_.Name
                    HasDefaultValue = $hasDefaultValue
                    Type = $type
                }

                $matchingParamDetail = $paramObject.GetEnumerator() | Where-Object { $_.Value.Name -eq $metadata.Name } | Select-Object -First 1 -ErrorAction Ignore
                if ($matchingParamDetail) {
                    # Not all parameters in the code is present in the Swagger spec (autogenerated parameters like CustomHeaders or ODataQuery parameters)
                    $matchingParamDetail = $matchingParamDetail[0].Value
                    if ($matchingParamDetail.ContainsKey('x_ms_parameter_grouping_group')) {
                        # Look through this parameter group's parameters and extract the individual metadata
                        $paramToAdd = "`$$($matchingParamDetail.Name)"
                        $parameterGroupType = $_.ParameterType
                        $parameterGroupType.GetProperties() | ForEach-Object {
                            $parameterGroupProperty = $_
                            $matchingGroupedParameterDetailEntry = $matchingParamDetail.'x_ms_parameter_grouping_group'.GetEnumerator() | Where-Object { $_.Value.Name -eq $parameterGroupProperty.Name } | Select-Object -First 1 -ErrorAction Ignore
                            if ($matchingGroupedParameterDetailEntry) {
                                $setSingleParameterMetadataParms = @{
                                    CommandName = $FunctionDetails['CommandName']
                                    Name = $matchingParamDetail.Name
                                    HasDefaultValue = $false
                                    IsGrouped = $true
                                    Type = $_.PropertyType
                                    MatchingParamDetail = $matchingGroupedParameterDetailEntry.Value
                                    ResultRecord = $resultRecord
                                }

                                if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms))
                                {
                                    Export-CliXml -InputObject $ResultRecord -Path $CliXmlTmpPath
                                    $errorOccurred = $true
                                    return
                                }

                                $matchingGroupedParameterDetailEntry.Value.ExtendedData.GroupType = $parameterGroupType.ToString()
                            }
                        }
                    } else {
                        # Single parameter
                        $setSingleParameterMetadataParms = @{
                            CommandName = $FunctionDetails['CommandName']
                            Name = $_.Name
                            HasDefaultValue = $hasDefaultValue
                            IsGrouped = $false
                            Type = $_.ParameterType
                            MatchingParamDetail = $matchingParamDetail
                            ResultRecord = $resultRecord
                        }

                        if ($hasDefaultValue) {
                            $setSingleParameterMetadataParms['DefaultValue'] = $_.DefaultValue
                        }

                        if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms))
                        {
                            Export-CliXml -InputObject $ResultRecord -Path $CliXmlTmpPath
                            $errorOccurred = $true
                            return
                        }

                        $paramToAdd = $matchingParamDetail.ExtendedData.ParamToAdd
                    }
                    
                    $ParamList += $paramToAdd
                } else {
                    if ($metadata.Type.StartsWith("Microsoft.Rest.Azure.OData.ODataQuery``1")) {
                        if ($oDataQueryFound) {
                            $resultRecord.ErrorMessages += ($LocalizedData.MultipleODataQueriesOneFunction -f ($operationId))
                            Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                            return
                        } else {
                            # Escape backticks
                            $oDataQueryType = $metadata.Type.Replace("``", "````")
                            $ParamList += "`$(if (`$oDataQuery) { New-Object -TypeName `"$oDataQueryType`" -ArgumentList `$oDataQuery } else { `$null })"
                            $oDataQueryFound = $true
                        }
                    }
                }
            }

            if ($parameterSetDetail.ContainsKey('x-ms-odata') -and $parameterSetDetail.'x-ms-odata') {
                $paramObject.GetEnumerator() | ForEach-Object {
                    $paramDetail = $_.Value

                    if (-not $paramDetail.ContainsKey('ExtendedData')) {
                        $metadata = @{
                            IsODataParameter = $true
                        }

                        $paramDetail.ExtendedData = $metadata
                    }
                }
            }

            $parameterSetDetail['ExpandedParamList'] = $ParamList -Join ", "
        }

        if ($errorOccurred) {
            return
        }
    }

    $resultRecord.Result = $PathFunctionDetails
    Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
}

function Set-SingleParameterMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $CommandName,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [bool]
        $HasDefaultValue,

        [Parameter(Mandatory=$true)]
        [bool]
        $IsGrouped,

        [Parameter(Mandatory=$true)]
        [System.Type]
        $Type,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $MatchingParamDetail,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResultRecord,

        [Parameter(Mandatory=$false)]
        [object]
        $DefaultValue
    )
    
    $name = Get-PascalCasedString -Name $_.Name
    $metadata = @{
                    Name = $name
                    HasDefaultValue = $HasDefaultValue
                    Type = $Type.ToString()
                    ParamToAdd = "`$$name"
                }

    if ($HasDefaultValue) {
        # Setting this default value actually matter, but we might as well
        if ("System.String" -eq $metadata.Type) {
            if ($DefaultValue -eq $null) {
                $metadata.HasDefaultValue = $false
                # This is the part that works around PS automatic string coercion
                $metadata.ParamToAdd = "`$(if (`$PSBoundParameters.ContainsKey('$($metadata.Name)')) { $($metadata.ParamToAdd) } else { [NullString]::Value })"
            }
        } elseif ("System.Nullable``1[System.Boolean]" -eq $metadata.Type) {
            if($DefaultValue -ne $null) {
                $DefaultValue = "`$$DefaultValue"
            }

            $metadata.Type = "switch"
        } else {
            $DefaultValue = $_.DefaultValue
            if (-not ($_.ParameterType.IsValueType) -and $DefaultValue) {
                $ResultRecord.ErrorMessages += $LocalizedData.ReferenceTypeDefaultValueNotSupported -f ($metadata.Name, $metadata.Type, $CommandName)
                return $false
            }
        }

        $metadata['DefaultValue'] = $DefaultValue
    } else {
        if ('$false' -eq $matchingParamDetail.Mandatory -and (-not $IsGrouped)) {
            # This happens in the case of optional path parameters, even if the path parameter is at the end
            $ResultRecord.WarningMessages += ($LocalizedData.OptionalParameterNowRequired -f ($metadata.Name, $CommandName))
        }
    }

    $MatchingParamDetail['ExtendedData'] = $metadata
    return $true
}

function Get-TemporaryCliXmlFilePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $FullModuleName
    )

    if (-not (Test-Path -Path $script:AppLocalPath -PathType Container)) {
        $null = New-Item -Path $script:AppLocalPath -ItemType Directory
    }
    
    $random = [Guid]::NewGuid().Guid
    $filePath = Join-Path -Path $script:AppLocalPath -ChildPath "$FullModuleName.$random.xml"
    return $filePath
}