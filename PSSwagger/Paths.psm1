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
    
    # First get path level common parameters, if any, which will be common to all operations in this swagger path.
    $PathCommonParameters = @{}
    if(Get-Member -InputObject $JsonPathItemObject.value -Name 'Parameters')
    {
        $GetPathParamInfo_params = @{
            JsonPathItemObject = $JsonPathItemObject.Value
            SwaggerDict = $swaggerDict
            DefinitionFunctionsDetails = $DefinitionFunctionsDetails
            ParameterGroupCache = $ParameterGroupCache
            ParametersTable = $PathCommonParameters
        }
        Get-PathParamInfo @GetPathParamInfo_params
    }

    $JsonPathItemObject.value.PSObject.Properties | ForEach-Object {
        $longRunningOperation = $false
        if (((Get-Member -InputObject $_.Value -Name 'x-ms-long-running-operation') -and $_.Value.'x-ms-long-running-operation')) {
            $longRunningOperation = $true
        }

        $x_ms_pageableObject = $null
        if (((Get-Member -InputObject $_.Value -Name 'x-ms-pageable') -and $_.Value.'x-ms-pageable')) {
            $x_ms_pageableObject = @{}
            if (((Get-Member -InputObject $_.Value.'x-ms-pageable' -Name 'operationName') -and $_.Value.'x-ms-pageable'.'operationName')) {
                $x_ms_pageableObject['operationName'] = $_.Value.'x-ms-pageable'.'operationName'
            }

            if (((Get-Member -InputObject $_.Value.'x-ms-pageable' -Name 'itemName') -and $_.Value.'x-ms-pageable'.'itemName')) {
                $x_ms_pageableObject['itemName'] = $_.Value.'x-ms-pageable'.'itemName'
            }

            if ((Get-Member -InputObject $_.Value.'x-ms-pageable' -Name 'nextLinkName')) {
                if ($_.Value.'x-ms-pageable'.'nextLinkName') {
                    $x_ms_pageableObject['nextLinkName'] = $_.Value.'x-ms-pageable'.'nextLinkName'
                } else {
                    $x_ms_pageableObject = $null
                }
            }
        }

        if(Get-Member -InputObject $_.Value -Name 'OperationId')
        {
            $operationId = $_.Value.operationId
            Write-Verbose -Message ($LocalizedData.GettingSwaggerSpecPathInfo -f $operationId)

            $FunctionDescription = ""
            if((Get-Member -InputObject $_.value -Name 'description') -and $_.value.description) {
                $FunctionDescription = $_.value.description 
            }
            
            $ParametersTable = @{}
            # Add Path common parameters to the operation's parameters list.
            $PathCommonParameters.GetEnumerator() | ForEach-Object {
                $ParametersTable[$_.Key] = $_.Value
            }

            $GetPathParamInfo_params2 = @{
                JsonPathItemObject = $_.value
                SwaggerDict = $swaggerDict
                DefinitionFunctionsDetails = $DefinitionFunctionsDetails
                ParameterGroupCache = $ParameterGroupCache
                ParametersTable = $ParametersTable
            }
            Get-PathParamInfo @GetPathParamInfo_params2

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
                ParameterDetails = $ParametersTable
                Responses = $responses
                OperationId = $operationId
                Priority = 100 # Default
                'x-ms-pageable' = $x_ms_pageableObject
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
                    $FunctionDetails['x-ms-long-running-operation'] = $longRunningOperation
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
        elseif(-not ((Get-Member -InputObject $_ -Name 'Name') -and ($_.Name -eq 'Parameters')))
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

    $FunctionsToExport = @()
    Preprocess-PagingOperations -PathFunctionDetails $PathFunctionDetails
    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $_.Value `
                                              -SwaggerMetaDict $SwaggerMetaDict `
                                              -SwaggerDict $SwaggerDict `
                                              -PathFunctionDetails $PathFunctionDetails
    }

    return $FunctionsToExport
}

<# Mark any operations as paging operations if they're the target of any operation's x-ms-pageable.operationName property.
These operations will not generate -Page and -Paging, even though they're marked as pageable.
These are single page operations and should never be unrolled (in the case of -not -Paging) or accept IPage parameters (in the case of -Page) #>
function Preprocess-PagingOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $PathFunctionDetails
    )

    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $_.Value.ParameterSetDetails | ForEach-Object {
            $parameterSetDetail = $_
            if ($parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable') {
                if ($parameterSetDetail.'x-ms-pageable'.ContainsKey('operationName')) {
                    $matchingPath = $PathFunctionDetails.GetEnumerator() | Where-Object { $_.Value.ParameterSetDetails | Where-Object { $_.OperationId -eq $parameterSetDetail.'x-ms-pageable'.'operationName'} } | Select-Object -First 1
                    $matchingPath.Value['IsNextPageOperation'] = $true
                }
            }
        }
    }
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
        $SwaggerDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $PathFunctionDetails
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $commandName = $FunctionDetails.CommandName
    $parameterSetDetails = $FunctionDetails['ParameterSetDetails']
    $isLongRunningOperation = $FunctionDetails.ContainsKey('x-ms-long-running-operation') -and $FunctionDetails.'x-ms-long-running-operation'
    $isNextPageOperation = $FunctionDetails.ContainsKey('IsNextPageOperation') -and $FunctionDetails.'IsNextPageOperation'
    $info = $SwaggerDict['Info']
    $namespace = $info['NameSpace']
    $models = $info['Models']
    $modulePostfix = $info['infoName']
    $clientName = '$' + $modulePostfix
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']

    $description = ''
    $paramBlock = ''
    $paramHelp = ''
    $parametersToAdd = @{}
    $parameterHitCount = @{}
    $globalParameterBlock = ''
    $x_ms_pageableObject = $null
    foreach ($parameterSetDetail in $parameterSetDetails) {
        if ($parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            if ($x_ms_pageableObject -and 
                $x_ms_pageableObject.ContainsKey('ReturnType') -and 
                ($x_ms_pageableObject.ReturnType -ne 'NONE') -and
                ($x_ms_pageableObject.ReturnType -ne $parameterSetDetail.ReturnType)) {
                Write-Warning -Message ($LocalizedData.MultiplePageReturnTypes -f ($commandName))
                $x_ms_pageableObject.ReturnType = 'NONE'
            } elseif (-not $x_ms_pageableObject) {
                $x_ms_pageableObject = $parameterSetDetail.'x-ms-pageable'
                $x_ms_pageableObject['ReturnType'] = $parameterSetDetail.ReturnType
                if ($x_ms_pageableObject.Containskey('operationName')) {
                    # Search for the cmdlet with a parameter set with the given operationName
                    $pagingFunctionDetails = $PathFunctionDetails.GetEnumerator() | Where-Object { $_.Value.ParameterSetDetails | Where-Object { $_.OperationId -eq $x_ms_pageableObject.operationName }} | Select-Object -First 1
                    if (-not $pagingFunctionDetails) {
                        throw ($LocalizedData.FailedToFindPagingOperation -f ($($x_ms_pageableObject.OperationName), $commandName))
                    }

                    $pagingParameterSet = $pagingFunctionDetails.Value.ParameterSetDetails | Where-Object { $_.OperationId -eq $x_ms_pageableObject.operationName }
                    $unmatchedParameters = @()
                    # This list of parameters works for when -Page is called...
                    $cmdletArgsPageParameterSet = ''
                    # ...and this list of parameters works for when unrolling paged results (when -Paging is not used)
                    $cmdletArgsNoPaging = ''
                    foreach ($pagingParameterEntry in $pagingParameterSet.ParameterDetails.GetEnumerator()) {
                        $pagingParameter = $pagingParameterEntry.Value
                        # Ignore parameters that are readonly or have a constant value
                        if ($pagingParameter.ContainsKey('ReadOnlyGlobalParameter') -and $pagingParameter.ReadOnlyGlobalParameter) {
                            continue
                        }

                        if ($pagingParameter.ContainsKey('ConstantValue') -and $pagingParameter.ConstantValue) {
                            continue
                        }

                        $matchingCurrentParameter = $parameterSetDetail.ParameterDetails.GetEnumerator() | Where-Object { $_.Value.Name -eq $pagingParameter.Name } | Select-Object -First 1
                        if ($matchingCurrentParameter) {
                            $cmdletArgsPageParameterSet += "-$($pagingParameter.Name) `$$($pagingParameter.Name) "
                            $cmdletArgsNoPaging += "-$($pagingParameter.Name) `$$($pagingParameter.Name) "
                        } else {
                            $unmatchedParameters += $pagingParameter
                            $cmdletArgsPageParameterSet += "-$($pagingParameter.Name) `$Page.NextPageLink "
                            $cmdletArgsNoPaging += "-$($pagingParameter.Name) `$result.NextPageLink "
                        }
                    }

                    if ($unmatchedParameters.Count -ne 1) {
                        throw ($LocalizedData.InvalidPagingOperationSchema -f ($commandName, $pagingFunctionDetails.Value.CommandName))
                    }

                    $x_ms_pageableObject['Cmdlet'] = $pagingFunctionDetails.Value.CommandName
                    $x_ms_pageableObject['CmdletArgsPage'] = $cmdletArgsPageParameterSet.Trim()
                    $x_ms_pageableObject['CmdletArgsPaging'] = $cmdletArgsNoPaging.Trim()
                } else {
                    $x_ms_pageableObject['Operations'] = $parameterSetDetail.Operations
                    $x_ms_pageableObject['MethodName'] = "$($parameterSetDetail.MethodName.Substring(0, $parameterSetDetail.MethodName.IndexOf('WithHttpMessagesAsync')))NextWithHttpMessagesAsync"
                }
            }
        }

        $parameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
            $parameterDetails = $_.Value
            $parameterRequiresAdding = $true
            if ($parameterDetails.ContainsKey('x_ms_parameter_location') -and ('client' -eq $parameterDetails.'x_ms_parameter_location')) {
                # Check if a global has been added already
                if ($parametersToAdd.ContainsKey("$($parameterDetails.Name)Global")) {
                    $parameterRequiresAdding = $false
                } elseif ($parameterDetails.ContainsKey('ReadOnlyGlobalParameter') -and $parameterDetails.ReadOnlyGlobalParameter) {
                    $parameterRequiresAdding = $false
                } else {
                    $globalParameterName = $parameterDetails.Name
                    $globalParameterValue = "```$$($parameterDetails.Name)"
                    if ($parameterDetails.ContainsKey('ConstantValue') -and $parameterDetails.ConstantValue) {
                        # A parameter with a constant value doesn't need to be in the parameter block
                        $parameterRequiresAdding = $false
                        $globalParameterValue = $parameterDetails.ConstantValue
                    }
                    
                    $globalParameterBlock += [Environment]::NewLine + $executionContext.InvokeCommand.ExpandString($GlobalParameterBlockStr)
                }
            }

            if ($parameterRequiresAdding) {
                if ($parameterDetails.ContainsKey('x_ms_parameter_grouping_group')) {
                    foreach ($parameterDetailEntry in $parameterDetails.'x_ms_parameter_grouping_group'.GetEnumerator()) {
                        Add-UniqueParameter -CandidateParameterDetails $parameterDetailEntry.Value -OperationId $parameterSetDetail.OperationId -ParametersToAdd $parametersToAdd -ParameterHitCount $parameterHitCount
                    }
                } else {
                    Add-UniqueParameter -CandidateParameterDetails $parameterDetails -OperationId $parameterSetDetail.OperationId -ParametersToAdd $parametersToAdd -ParameterHitCount $parameterHitCount
                }
            } else {
                # This magic string is here to distinguish local vs global parameters with the same name, e.g. in the Azure Resources API
                $parametersToAdd["$($parameterDetails.Name)Global"] = $null
            }
        }
    }
    $topParameterToAdd = $null
    $skipParameterToAdd = $null
    $pagingBlock = ''
    $pagingOperationName = ''
    $pagingOperations = ''
    $Cmdlet = ''
    $CmdletParameter = ''
    $CmdletArgs = ''
    $pageType = 'Array'
    $resultBlockStr = $resultBlockNoPaging
    if ($x_ms_pageableObject) {
        if ($x_ms_pageableObject.ReturnType -ne 'NONE') {
            $pageType = $x_ms_pageableObject.ReturnType
        }

        if ($x_ms_pageableObject.ContainsKey('Operations')) {
            $pagingOperations = $x_ms_pageableObject.Operations
            $pagingOperationName = $x_ms_pageableObject.MethodName
        } else {
            $Cmdlet = $x_ms_pageableObject.Cmdlet
            $CmdletArgs = $x_ms_pageableObject.CmdletArgsPaging
        }

        $topParameterToAdd = @{
            Details = @{
                Name = 'Top'
                Type = 'int'
                Mandatory = '$false'
                Description = 'Return the top N items as specified by the parameter value. Applies after the -Skip parameter.'
                IsParameter = $true
                ValidateSet = $null
                ExtendedData = @{
                    Type = 'int'
                    HasDefaultValue = $true
                    DefaultValue = -1
                }
            }
            ParameterSetInfo = @{}
        }

        $skipParameterToAdd = @{
            Details = @{
                Name = 'Skip'
                Type = 'int'
                Mandatory = '$false'
                Description = 'Skip the first N items as specified by the parameter value.'
                IsParameter = $true
                ValidateSet = $null
                ExtendedData = @{
                    Type = 'int'
                    HasDefaultValue = $true
                    DefaultValue = -1
                }
            }
            ParameterSetInfo = @{}
        }
    }

    # Process security section
    $azSubscriptionIdBlock = ""
    $authFunctionCall = ""
    $overrideBaseUriBlock = ""
    $securityParametersToAdd = @()
    if ($SwaggerMetaDict.ContainsKey('ExtendedTempMetadata') -and $SwaggerMetaDict.ExtendedTempMetadata) {
        if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'Scheme')) {
            if ($SwaggerMetaDict.ExtendedTempMetadata.Scheme -eq "azure") {
                if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'CustomAuthFunction')) {
                    if (-not $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction) {
                        $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction = 'PSSwagger.Azure.Helpers\Get-AzServiceCredential'
                    }
                } else {
                    Add-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -MemberType NoteProperty -Name 'CustomAuthFunction' -Value 'PSSwagger.Azure.Helpers\Get-AzServiceCredential'
                }

                $azSubscriptionIdBlock = "`$subscriptionId = Get-AzSubscriptionId"
            } elseif ($SwaggerMetaDict.ExtendedTempMetadata.Scheme -eq "azurestack") {
                if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'CustomAuthFunction')) {
                    if (-not $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction) {
                        $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction = 'PSSwagger.Azure.Helpers\Get-AzServiceCredential'
                    }
                } else {
                    Add-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -MemberType NoteProperty -Name 'CustomAuthFunction' -Value 'PSSwagger.Azure.Helpers\Get-AzServiceCredential'
                }

                if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'OverrideBaseUriFunction')) {
                    if (-not $SwaggerMetaDict.ExtendedTempMetadata.OverrideBaseUriFunction) {
                        $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction = 'PSSwagger.Azure.Helpers\Get-AzResourceManagerUrl'
                    }
                } else {
                    Add-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -MemberType NoteProperty -Name 'OverrideBaseUriFunction' -Value 'PSSwagger.Azure.Helpers\Get-AzResourceManagerUrl'
                }

                $azSubscriptionIdBlock = "`$subscriptionId = Get-AzSubscriptionId"
            }
        }

        if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'CustomAuthFunction') -and $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction) {
            $authFunctionCall = $SwaggerMetaDict.ExtendedTempMetadata.CustomAuthFunction
        }

        if ((Get-Member -InputObject $SwaggerMetaDict.ExtendedTempMetadata -Name 'OverrideBaseUriFunction') -and $SwaggerMetaDict.ExtendedTempMetadata.OverrideBaseUriFunction) {
            $overrideBaseUriBlock = "`$ResourceManagerUrl = $($SwaggerMetaDict.ExtendedTempMetadata.OverrideBaseUriFunction)`n    `$clientName.BaseUri = `$ResourceManagerUrl"
        }

        # If the auth function hasn't been set by metadata, try to discover it from the security and securityDefinition objects in the spec
        if (-not $authFunctionCall) {
            if ($swaggerDict.ContainsKey('Security')) {
                # For now, just take the first security object
                $firstSecurityObject = Get-Member -InputObject $swaggerDict.Security[0] -MemberType NoteProperty
                # If there's no security object, we don't care about the security definition object
                if ($firstSecurityObject) {
                    # If there is one, we need to know the definition
                    if (-not $swaggerDict.ContainsKey("SecurityDefinitions")) {
                        throw $LocalizedData.SecurityDefinitionsObjectMissing
                    }

                    $securityDefinitions = $swaggerDict.SecurityDefinitions
                    $securityDefinition = $securityDefinitions.$($firstSecurityObject.Name)
                    if (-not $securityDefinition) {
                        throw ($LocalizedData.SecurityDefinitionsObjectMissing -f ($firstSecurityObject.Name))
                    }

                    if (-not (Get-Member -InputObject $securityDefinition -Name "type")) {
                        throw ($LocalizedData.SecurityDefinitionMissingType -f ($firstSecurityObject.Name))
                    }

                    $type = $securityDefinition.type
                    if ($type -eq 'basic') {
                        # For Basic Authentication, allow the user to pass in a PSCredential object.
                        $credentialParameter = @{
                            Details = @{
                                Name = 'Credential'
                                Type = 'PSCredential'
                                Mandatory = '$false'
                                Description = 'User credentials.'
                                IsParameter = $true
                                ValidateSet = $null
                                ExtendedData = @{
                                    Type = 'PSCredential'
                                    HasDefaultValue = $false
                                }
                            }
                            ParameterSetInfo = @{}
                        }
                        $securityParametersToAdd += @{
                            Parameter = $credentialParameter
                            Add = $true
                        }
                        $authFunctionCall = 'PSSwagger.Common.Helpers\Get-BasicAuthCredentials -Credential $Credential'
                    } elseif ($type -eq 'apiKey') {
                        if (-not (Get-Member -InputObject $securityDefinition -Name "name")) {
                            throw ($LocalizedData.SecurityDefinitionMissingName -f ($firstSecurityObject.Name))
                        }

                        if (-not (Get-Member -InputObject $securityDefinition -Name "in")) {
                            throw ($LocalizedData.SecurityDefinitionMissingIn -f ($firstSecurityObject.Name))
                        }

                        $name = $securityDefinition.name
                        $in = $securityDefinition.in
                        # For API key authentication, the user should supply the API key, but the in location and the name are generated from the spec
                        # In addition, we'd be unable to authenticate without the API key, so make it mandatory
                        $credentialParameter = @{
                            Details = @{
                                Name = 'APIKey'
                                Type = 'string'
                                Mandatory = '$true'
                                Description = 'API key given by service owner.'
                                IsParameter = $true
                                ValidateSet = $null
                                ExtendedData = @{
                                    Type = 'string'
                                    HasDefaultValue = $false
                                }
                            }
                            ParameterSetInfo = @{}
                        }
                        $securityParametersToAdd += @{
                            Parameter = $credentialParameter
                            Add = $true
                        }
                        $authFunctionCall = "PSSwagger.Common.Helpers\Get-ApiKeyCredentials -APIKey `$APIKey -In '$in' -Name '$name'"
                    } else {
                        Write-Warning -Message ($LocalizedData.UnsupportedAuthenticationType -f ($type))
                    }
                }
            }
        }
    }

    if (-not $authFunctionCall) {
        # At this point, there was no supported security object or overridden auth function, so assume no auth
        $authFunctionCall = 'PSSwagger.Common.Helpers\Get-EmptyAuthCredentials'
    }

    $nonUniqueParameterSets = @()
    foreach ($parameterSetDetail in $parameterSetDetails) {
        # Add parameter sets to paging parameter sets
        if ($topParameterToAdd -and $parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            $topParameterToAdd.ParameterSetInfo[$parameterSetDetail.OperationId] = @{
                Name = $parameterSetDetail.OperationId
                Mandatory = '$false'
            }
        }

        if ($skipParameterToAdd -and $parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            $skipParameterToAdd.ParameterSetInfo[$parameterSetDetail.OperationId] = @{
                Name = $parameterSetDetail.OperationId
                Mandatory = '$false'
            }
        }

        # Test for uniqueness of parameters
        $parameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
            $parameterDetails = $_.Value
            # Check if the paging parameters are conflicting
            # Note that this has to be moved elsewhere to be more generic, but this is temporarily located here to solve this scenario for paging at least
            if ($topParameterToAdd -and $parameterDetails.Name -eq 'Top') {
                $topParameterToAdd = $null
                # If the parameter is not OData, full paging support isn't possible.
                if (-not $parameterDetails.ExtendedData.ContainsKey('IsODataParameter') -or -not $parameterDetails.ExtendedData.IsODataParameter) {
                    Write-Warning -Message ($LocalizedData.ParameterConflictAndResult -f ('Top', $commandName, $parameterSetDetail.OperationId, $LocalizedData.PagingNotFullySupported))
                }
            }

            if ($skipParameterToAdd -and $parameterDetails.Name -eq 'Skip') {
                $skipParameterToAdd = $null
                # If the parameter is not OData, full paging support isn't possible.
                if (-not $parameterDetails.ExtendedData.ContainsKey('IsODataParameter') -or -not $parameterDetails.ExtendedData.IsODataParameter) {
                    Write-Warning -Message ($LocalizedData.ParameterConflictAndResult -f ('Skip', $commandName, $parameterSetDetail.OperationId, $LocalizedData.PagingNotFullySupported))
                }
            }

            foreach ($additionalParameter in $securityParametersToAdd) {
                if ($parameterDetails.Name -eq $additionalParameter.Parameter.Details.Name) {
                    $additionalParameter.Add = $false
                    Write-Warning -Message ($LocalizedData.ParameterConflictAndResult -f ($additionalParameter.Parameter.Details.Name, $commandName, $parameterSetDetail.OperationId, $LocalizedData.CredentialParameterNotSupported))
                }
            }
            
            if ($parameterHitCount[$parameterDetails.Name] -eq 1) {
                # continue here brings us back to the top of the $parameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object loop
                continue
            }
        }

        # At this point none of the parameters in this set are unique
        $nonUniqueParameterSets += $parameterSetDetail
    }

    if ($topParameterToAdd) {
        $parametersToAdd[$topParameterToAdd.Details.Name] = $topParameterToAdd
    }

    if ($skipParameterToAdd) {
        $parametersToAdd[$skipParameterToAdd.Details.Name] = $skipParameterToAdd
    }

    foreach ($additionalParameter in $securityParametersToAdd) {
        if ($additionalParameter.Add) {
            $parametersToAdd[$additionalParameter.Parameter.Details.Name] = $additionalParameter.Parameter
        }
    }
    
    if ($topParameterToAdd -and $skipParameterToAdd) {
        $resultBlockStr = $executionContext.InvokeCommand.ExpandString($resultBlockWithSkipAndTop)
    } elseif ($topParameterToAdd -and -not $skipParameterToAdd) {
        $resultBlockStr = $executionContext.InvokeCommand.ExpandString($resultBlockWithTop)
    } elseif (-not $topParameterToAdd -and $skipParameterToAdd) {
        $resultBlockStr = $executionContext.InvokeCommand.ExpandString($resultBlockWithSkip)
    }

    $getTaskResult = $executionContext.InvokeCommand.ExpandString($getTaskResultBlock)

    if ($pagingOperations) {
        if ($topParameterToAdd) {
            $pagingBlock = $executionContext.InvokeCommand.ExpandString($PagingBlockStrFunctionCallWithTop)
        } else {
            $pagingBlock = $executionContext.InvokeCommand.ExpandString($PagingBlockStrFunctionCall)
        }
    } elseif ($Cmdlet) {
        if ($topParameterToAdd) {
            $pagingBlock = $executionContext.InvokeCommand.ExpandString($PagingBlockStrCmdletCallWithTop)
        } else {
            $pagingBlock = $executionContext.InvokeCommand.ExpandString($PagingBlockStrCmdletCall)
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
        $defaultParameterSet = $parameterSetDetails | Sort-Object @{e = {$_.Priority -as [int] }} | Select-Object -First 1
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
        if ($parameterToAdd) {
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

            if (-not $AllParameterSetsString) {
                $isParamMandatory = $parameterToAdd.Details.Mandatory
                $ParameterSetPropertyString = ""
                $AllParameterSetsString = $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
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
                $paramType = "$([Environment]::NewLine)        "
                if ($parameterToAdd.Details.ExtendedData.ContainsKey('IsODataParameter') -and $parameterToAdd.Details.ExtendedData.IsODataParameter) {
                    $paramType = "[$($parameterToAdd.Details.Type)]$paramType"
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
                    
                    if ($parameterToAdd.Details.ExtendedData.Type) {
                        $paramType = "[$($parameterToAdd.Details.ExtendedData.Type)]$paramType"
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
                }

                $paramBlock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
                $pDescription = $parameterToAdd.Details.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            } else {
                Write-Warning ($LocalizedData.ParameterMissingFromAutoRestCode -f ($parameterName, $commandName))
            }
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
    if ($isLongRunningOperation) {
        if ($paramBlock) {
            $ParamBlockReplaceStr = $paramBlock + ",`r`n" + $AsJobParameterString
        } else {
            $ParamBlockReplaceStr = $AsJobParameterString
        }

        $PathFunctionBody = $executionContext.InvokeCommand.ExpandString($PathFunctionBodyAsJob)
    } else {
        $ParamBlockReplaceStr = $paramBlock
        $PathFunctionBody = $executionContext.InvokeCommand.ExpandString($PathFunctionBodySynch)
    }

    $functionBodyParams = @{
                                ParameterSetDetails = $parameterSetDetails
                                ODataExpressionBlock = $oDataExpressionBlock
                                ParameterGroupsExpressionBlock = $parameterGroupsExpressionBlock
                                GlobalParameterBlock = $GlobalParameterBlock
                                SwaggerDict = $SwaggerDict
                                SwaggerMetaDict = $SwaggerMetaDict
                                SecurityBlock = $executionContext.InvokeCommand.ExpandString($securityBlockStr)
                           }

    $pathGenerationPhaseResult = Get-PathFunctionBody @functionBodyParams
    $bodyObject = $pathGenerationPhaseResult.BodyObject

    $body = $bodyObject.Body
    $outputTypeBlock = $bodyObject.OutputTypeBlock

    if ($UseAzureCsharpGenerator) {
        $helperModule = "PSSwagger.Azure.Helpers"
    } else {
        $helperModule = "PSSwagger.Common.Helpers"
    }
    
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

            # Process global parameters
            $paramObject = $parameterSetDetail.ParameterDetails
            $clientType.GetProperties() | ForEach-Object {
                $propertyName = $_.Name
                $matchingParamDetail = $paramObject.GetEnumerator() | Where-Object { $_.Value.Name -eq $propertyName } | Select-Object -First 1 -ErrorAction Ignore
                if ($matchingParamDetail) {
                    $setSingleParameterMetadataParms = @{
                                                            CommandName = $FunctionDetails['CommandName']
                                                            Name = $matchingParamDetail.Value.Name
                                                            HasDefaultValue = $false
                                                            IsGrouped = $false
                                                            Type = $_.PropertyType
                                                            MatchingParamDetail = $matchingParamDetail.Value
                                                            ResultRecord = $resultRecord
                                                        }
                    if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms))
                    {
                        Export-CliXml -InputObject $ResultRecord -Path $CliXmlTmpPath
                        $errorOccurred = $true
                        return
                    }
                }
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

            # Process output type
            $returnType = $methodInfo.ReturnType
            if ($returnType.Name -eq 'Task`1') {
                $returnType = $returnType.GenericTypeArguments[0]
            }

            if ($returnType.Name -eq 'AzureOperationResponse`1') {
                $returnType = $returnType.GenericTypeArguments[0]
            }

            $returnTypeString = Convert-GenericTypeToString -Type $returnType
            $parameterSetDetail['ReturnType'] = $returnTypeString

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

function Convert-GenericTypeToString {
    param(
        [Parameter(Mandatory=$true)]
        [Type]$Type
    )

    if (-not $Type.IsGenericType) {
        return $Type.FullName
    }

    $genericTypeStr = ''
    foreach ($genericTypeArg in $Type.GenericTypeArguments) {
        $genericTypeStr += "$(Convert-GenericTypeToString -Type $genericTypeArg),"
    }

    $genericTypeStr = $genericTypeStr.Substring(0, $genericTypeStr.Length - 1)
    return "$($Type.FullName.Substring(0, $Type.FullName.IndexOf('`')))[$genericTypeStr]"
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

    $random = [Guid]::NewGuid().Guid
    $filePath = Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath "$FullModuleName.$random.xml"
    return $filePath
}