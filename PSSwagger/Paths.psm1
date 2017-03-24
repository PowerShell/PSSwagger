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
        $DefinitionFunctionsDetails
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    
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
        $SwaggerDict,

        [string]
        $OutputAssembly,

        [string[]]
        $References
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $Info = $swaggerDict['Info']
    $modulePostfix = $Info['infoName']
    $NameSpace = $info.namespace
    $fullModuleName = $Namespace + '.' + $modulePostfix

    $cliXmlTmpPath = Get-TemporaryCliXmlFilePath -FullModuleName $fullModuleName
    try {
        Export-CliXml -InputObject $PathFunctionDetails -Path $cliXmlTmpPath
        $refString = ''
        foreach ($ref in $References) {
            $refString += "'$ref',"
        }

        $refString = $refString.Trim(',')
        $refString = "@($refString)"
        $out = & powershell -command "& { Import-Module `"`$(Join-Path -Path `"$PSScriptRoot`" -ChildPath `"Paths.psm1`")`";
                                   Set-ExtendedCodeMetadata -MainClientTypeName $fullModuleName ``
                                                            -OutputAssembly $OutputAssembly ``
                                                            -CliXmlTmpPath $cliXmlTmpPath ``
                                                            -References $refString }"
        
        $codeReflectionResult = Import-CliXml -Path $cliXmlTmpPath
        if ($codeReflectionResult.VerboseMessages.Count -gt 0) {
            $verboseMessages = $codeReflectionResult.VerboseMessages -Join [Environment]::NewLine
            Write-Verbose -Message $verboseMessages
        }

        if ($codeReflectionResult.WarningMessages.Count -gt 0) {
            $warningMessages = $codeReflectionResult.WarningMessages -Join [Environment]::NewLine
            Write-Warning -Message $warningMessages
        }

        Write-Verbose -Message ($LocalizedData.ResultCodeMetadataExtraction -f ($out | Out-String))

        if (-not ($codeReflectionResult.Result)) {
            $errorMessage = (,($LocalizedData.MetadataExtractFailed) + 
                $codeReflectionResult.ErrorMessages) -Join [Environment]::NewLine
            throw $errorMessage
        }

        $PathFunctionDetails = $codeReflectionResult.Result
    } finally {
        if (Test-Path -Path $cliXmlTmpPath) {
            $null = Remove-Item -Path $cliXmlTmpPath
        }
    }

    $FunctionsToExport = @()
    $PathFunctionDetails.Keys | ForEach-Object {
        $FunctionDetails = $PathFunctionDetails[$_]
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $FunctionDetails `
                                              -SwaggerMetaDict $SwaggerMetaDict `
                                              -SwaggerDict $SwaggerDict `
                                              -OutputAssembly $OutputAssembly `
                                              -References $References
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
        $SwaggerDict,

        [string]
        $OutputAssembly,

        [string[]]
        $References
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $commandName = $FunctionDetails.CommandName
    $parameterSetDetails = $FunctionDetails['ParameterSetDetails']

    $functionBodyParams = @{
                                ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
                                SwaggerDict = $SwaggerDict
                                SwaggerMetaDict = $SwaggerMetaDict
                                OutputAssembly = $OutputAssembly
                                References = $References
                           }

    # This call evaluates the extended function details like default values as well
    $pathGenerationPhaseResult = Get-PathFunctionBody @functionBodyParams
    $bodyObject = $pathGenerationPhaseResult.BodyObject
    $parameterSetDetails = $pathGenerationPhaseResult.ParameterSetDetails

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
        $paramType = "$($parameterToAdd.Details.ExtendedData.Type)"
        $ValidateSetDefinition = $null
        if ($parameterToAdd.Details.ValidateSet)
        {
            $ValidateSetString = $parameterToAdd.Details.ValidateSet
            $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
        }

        $parameterDefaultValueOption = ""
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
        $OutputAssembly,

        [Parameter(Mandatory=$true)]
        [string]
        $CliXmlTmpPath,

        [Parameter(Mandatory=$true)]
        [string[]]
        $References
    )

    $resultRecord = @{
        VerboseMessages = @()
        ErrorMessages = @()
        WarningMessages = @()
    }
    
    $resultRecord.VerboseMessages += $LocalizedData.ExtractingMetadata

    foreach ($reference in $References) {
        try {
            $null = Add-Type -Path $reference -PassThru
        }
        catch {
            if ($_.Exception -and $_.Exception.LoaderExceptions) {
                $resultRecord.ErrorMessages += ($_.Exception.LoaderExceptions[0] | Out-String)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                return
            }
        }
        
    }

    try {
        $null = Add-Type -Path $OutputAssembly -PassThru
    }
    catch {
        if ($_.Exception -and $_.Exception.LoaderExceptions) {
            $resultRecord.ErrorMessages += ($_.Exception.LoaderExceptions[0] | Out-String)
            Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
            return
        }
    }

    $PathFunctionDetails = Import-CliXml -Path $CliXmlTmpPath
    $PathFunctionDetails.Keys | ForEach-Object {
        $FunctionDetails = $PathFunctionDetails[$_]
        $ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
        foreach ($parameterSetDetail in $ParameterSetDetails) {
            $operationId = $parameterSetDetail.OperationId
            $methodName = ''
            $operations = ''
            $opIdValues = $operationId -split '_',2 
            if(-not $opIdValues -or ($opIdValues.count -ne 2)) {
                $methodName = $operationId + 'WithHttpMessagesAsync'
            } else {            
                $operationName = $operationId.Split('_')[0]
                $operationType = $operationId.Split('_')[1]
                $operations = ".$operationName"
                if ($parameterSetDetail['UseOperationsSuffix'] -and $parameterSetDetail['UseOperationsSuffix'])
                { 
                    $operations = $operations + 'Operations'
                }

                $methodName = $operationType + 'WithHttpMessagesAsync'
            }

            $parameterSetDetail['MethodName'] = $methodName
            $parameterSetDetail['Operations'] = $operations
            
            # For some reason, moving this out of this loop causes issues
            $clientType = Invoke-Expression -Command "[$MainClientTypeName]"
            if (-not $clientType) {
                $resultRecord.ErrorMessages += $LocalizedData.ExpectedServiceClientTypeNotFound -f ($MainClientTypeName)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                return
            }

            if ($operations) {
                $operationName = $operations.Substring(1)
                $propertyObject = $clientType.GetProperties() | Where-Object { $_.Name -eq $operationName } | Select-Object -First 1
                if (-not $propertyObject) {
                    $resultRecord.ErrorMessages += $LocalizedData.ExpectedOperationsClientTypeNotFound -f ($operationName, $clientType)
                    Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                    return
                }

                $clientType = $propertyObject.PropertyType
            }

            $methodInfo = $clientType.GetMethods() | Where-Object { $_.Name -eq $MethodName } | Select-Object -First 1
            if (-not $methodInfo) {
                $resultRecord.ErrorMessages += $LocalizedData.ExpectedMethodOnTypeNotFound -f ($MethodName, $clientType)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                return
            }

            $paramObject = $parameterSetDetail.ParameterDetails
            $ParamList = @()
            $methodInfo.GetParameters() | Sort-Object -Property Position | ForEach-Object {
                $hasDefaultValue = $_.HasDefaultValue
                # All Types should be converted to their string names, otherwise the CLI XML gets too large
                $type = $_.ParameterType.ToString()
                $metadata = @{
                    Name = Get-PascalCasedString -Name $_.Name
                    HasDefaultValue = $hasDefaultValue
                    Type = $type
                }

                $matchingParamDetail = $paramObject.Values | Where-Object { $_.Name -eq $metadata.Name } | Select-Object -First 1
                if ($matchingParamDetail) {
                    $paramToAdd = "`$$($metadata.Name)"
                    # Not all parameters in the code is present in the Swagger spec (autogenerated parameters like CustomHeaders)
                    if ($hasDefaultValue) {
                        # Setting this default value actually matter, but we might as well
                        $defaultValue = $_.DefaultValue
                        if ("System.String" -eq $type) {
                            if ($defaultValue -eq $null) {
                                $defaultValue = [NullString]::Value
                                # This is the part that works around PS automatic string coercion
                                $paramToAdd = "`$(if (`$PSBoundParameters.ContainsKey('$($metadata.Name)')) { $paramToAdd } else { [NullString]::Value })"
                            }
                        } elseif ("System.Nullable``1[System.Boolean]" -eq $type) {
                            $defaultValue = "`$$defaultValue"
                        } else {
                            $defaultValue = $_.DefaultValue
                            if (-not ($_.ParameterType.IsValueType) -and $defaultValue) {
                                $resultRecord.ErrorMessages += $LocalizedData.ReferenceTypeDefaultValueNotSupported
                                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                                return
                            }
                        }

                        $metadata['DefaultValue'] = $defaultValue
                    } else {
                        if ('$false' -eq $matchingParamDetail.Mandatory) {
                            # This happens in the case of optional path parameters, even if the path parameter is at the end
                            $resultRecord.WarningMessages += $LocalizedData.OptionalParameterNowRequired
                        }
                    }
                    
                    $matchingParamDetail['ExtendedData'] = $metadata
                    $ParamList += $paramToAdd
                }
            }

            $parameterSetDetail['ExpandedParamList'] = $ParamList -Join ", "
        }
    }

    $resultRecord.Result = $PathFunctionDetails
    Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
}

function Get-TemporaryCliXmlFilePath {
    param(
        [string]
        $FullModuleName
    )

    $filePath = Join-Path -Path $script:AppLocalPath -ChildPath "$FullModuleName.tmp.xml"
    return $filePath
}