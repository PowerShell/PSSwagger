#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1) -DisableNameChecking
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath SwaggerUtils.psm1) -DisableNameChecking
. "$PSScriptRoot\PSSwagger.Constants.ps1" -Force
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

function Get-SwaggerSpecPathInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $JsonPathItemObject,

        [Parameter(Mandatory = $true)]
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

        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParameterGroupCache,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $PSMetaJsonObject
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    $EndpointRelativePath = $JsonPathItemObject.Name

    $PSMetaPathJsonObject = $null
    if ($PSMetaJsonObject) {
        if ((Get-Member -InputObject $PSMetaJsonObject -Name 'paths') -and (Get-Member -InputObject $PSMetaJsonObject.paths -Name $EndpointRelativePath)) {
            $PSMetaPathJsonObject = $PSMetaJsonObject.paths.$EndpointRelativePath
        }
        elseif ((Get-Member -InputObject $PSMetaJsonObject -Name 'x-ms-paths') -and (Get-Member -InputObject $PSMetaJsonObject.'x-ms-paths' -Name $EndpointRelativePath)) {
            $PSMetaPathJsonObject = $PSMetaJsonObject.'x-ms-paths'.$EndpointRelativePath
        }
    }

    # First get path level common parameters, if any, which will be common to all operations in this swagger path.
    $PathCommonParameters = @{}
    if (Get-Member -InputObject $JsonPathItemObject.value -Name 'Parameters') {
        $PSMetaParametersJsonObject = $null
        if ($PSMetaPathJsonObject -and (Get-Member -InputObject $PSMetaPathJsonObject -Name 'parameters')) {
            $PSMetaParametersJsonObject = $PSMetaPathJsonObject.'parameters'
        }

        $GetPathParamInfo_params = @{
            JsonPathItemObject         = $JsonPathItemObject.Value
            SwaggerDict                = $swaggerDict
            DefinitionFunctionsDetails = $DefinitionFunctionsDetails
            ParameterGroupCache        = $ParameterGroupCache
            ParametersTable            = $PathCommonParameters
            PSMetaParametersJsonObject = $PSMetaParametersJsonObject
        }
        Get-PathParamInfo @GetPathParamInfo_params
    }

    $ResourceIdAndInputObjectDetails = $null
    if ($UseAzureCsharpGenerator) {
        $GetResourceIdParameters_params = @{
            JsonPathItemObject = $JsonPathItemObject
            ResourceId         = $EndpointRelativePath
            Namespace          = $SwaggerDict['Info'].NameSpace
            Models             = $SwaggerDict['Info'].Models
            DefinitionList     = $swaggerDict['Definitions']
        }
        $ResourceIdAndInputObjectDetails = Get-AzureResourceIdParameters @GetResourceIdParameters_params
    }

    $JsonPathItemObject.value.PSObject.Properties | ForEach-Object {
        $longRunningOperation = $false
        $operationType = $_.Name
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
                }
                else {
                    $x_ms_pageableObject = $null
                }
            }
        }

        if (Get-Member -InputObject $_.Value -Name 'security') {
            $operationSecurityObject = $_.Value.'security'
        }
        elseif ($swaggerDict.ContainsKey('Security')) {
            $operationSecurityObject = $swaggerDict['Security']
        }
        else {
            $operationSecurityObject = $null
        }

        $cmdletInfoOverrides = @()
        $PSMetaOperationJsonObject = $null
        if ($PSMetaPathJsonObject -and
            (Get-Member -InputObject $PSMetaPathJsonObject -Name $operationType)) {
            $PSMetaOperationJsonObject = $PSMetaPathJsonObject.$operationType
        }

        if (Get-Member -InputObject $_.Value -Name 'OperationId') {
            $operationId = $_.Value.operationId
            Write-Verbose -Message ($LocalizedData.GettingSwaggerSpecPathInfo -f $operationId)

            $defaultCommandNames = Get-PathCommandName -OperationId $operationId
            if ($PSMetaOperationJsonObject -and
                (Get-Member -InputObject $PSMetaOperationJsonObject -Name 'x-ps-cmdlet-infos')) {
                $PSMetaOperationJsonObject.'x-ps-cmdlet-infos' | ForEach-Object {
                    $metadataName = $null
                    if (Get-Member -InputObject $_ -Name 'name') {
                        $metadataName = $_.name
                    }

                    $cmdletInfoOverride = @{
                        Name     = $metadataName
                        Metadata = $_
                    }

                    # If no name override is specified, apply all these overrides to each default command name
                    if (-not $metadataName) {
                        foreach ($defaultCommandName in $defaultCommandNames) {
                            $cmdletInfoOverrides += @{
                                Name     = $defaultCommandName.name
                                Metadata = $cmdletInfoOverride.Metadata
                            }
                        }
                    }
                    else {
                        $cmdletInfoOverrides += $cmdletInfoOverride
                    }
                }
            }
            elseif ((Get-Member -InputObject $_.Value -Name 'x-ps-cmdlet-infos') -and $_.Value.'x-ps-cmdlet-infos') {
                foreach ($cmdletMetadata in $_.Value.'x-ps-cmdlet-infos') {
                    $cmdletInfoOverride = @{
                        Metadata = $cmdletMetadata
                    }
                    if ((Get-Member -InputObject $cmdletMetadata -Name 'name') -and $cmdletMetadata.name) {
                        $cmdletInfoOverride['name'] = $cmdletMetadata.name
                    }

                    # If no name override is specified, apply all these overrides to each default command name
                    if (-not (Get-Member -InputObject $cmdletMetadata -Name 'name')) {
                        foreach ($defaultCommandName in $defaultCommandNames) {
                            $cmdletInfoOverrides += @{
                                Name     = $defaultCommandName.name
                                Metadata = $cmdletInfoOverride.Metadata
                            }
                        }
                    }
                    else {
                        $cmdletInfoOverrides += $cmdletInfoOverride
                    }
                }
            }

            $FunctionDescription = ""
            if ((Get-Member -InputObject $_.value -Name 'description') -and $_.value.description) {
                $FunctionDescription = $_.value.description 
            }

            $FunctionSynopsis = ''
            if ((Get-Member -InputObject $_.value -Name 'Summary') -and $_.value.Summary) {
                $FunctionSynopsis = $_.value.Summary 
            }
            
            $ParametersTable = @{}
            # Add Path common parameters to the operation's parameters list.
            $PathCommonParameters.GetEnumerator() | ForEach-Object {
                # Cloning the common parameters object so that some values can be updated.
                $PathCommonParamDetails = $_.Value.Clone()
                if ($PathCommonParamDetails.ContainsKey('OriginalParameterName') -and $PathCommonParamDetails.OriginalParameterName) {
                    $PathCommonParamDetails['OriginalParameterName'] = ''
                }
                $ParametersTable[$_.Key] = $PathCommonParamDetails
            }

            $PSMetaParametersJsonObject = $null
            if ($PSMetaOperationJsonObject -and (Get-Member -InputObject $PSMetaOperationJsonObject -Name 'parameters')) {
                $PSMetaParametersJsonObject = $PSMetaOperationJsonObject.'parameters'
            }

            $GetPathParamInfo_params2 = @{
                JsonPathItemObject         = $_.value
                SwaggerDict                = $swaggerDict
                DefinitionFunctionsDetails = $DefinitionFunctionsDetails
                ParameterGroupCache        = $ParameterGroupCache
                ParametersTable            = $ParametersTable
                PSMetaParametersJsonObject = $PSMetaParametersJsonObject
            }
            Get-PathParamInfo @GetPathParamInfo_params2

            $responses = ""
            if ((Get-Member -InputObject $_.value -Name 'responses') -and $_.value.responses) {
                $responses = $_.value.responses 
            }

            if ($cmdletInfoOverrides) {
                $commandNames = $cmdletInfoOverrides
            }
            else {
                $commandNames = Get-PathCommandName -OperationId $operationId
            }
            
            # Priority of a parameterset will be used to determine the default parameterset of a cmdlet.
            $Priority = 0
            $ParametersCount = Get-HashtableKeyCount -Hashtable $ParametersTable
            if ($ParametersCount) {
                # Priority for parameter sets with mandatory parameters starts at 100
                $Priority = 100

                # Get Name parameter details, if exists.
                # If Name parameter is already available, ResourceName parameter name will not be changed.
                $NameParameterDetails = $ParametersTable.GetEnumerator() | Foreach-Object {
                    if ($_.Value.Name -eq 'Name') {
                        $_.Value
                    }
                }
                    
                $ParametersTable.GetEnumerator() | ForEach-Object {
                    if ($_.Value.ContainsKey('Mandatory') -and $_.Value.Mandatory -eq '$true') {
                        $Priority++
                    }

                    # Add alias for the resource name parameter.
                    if ($ResourceIdAndInputObjectDetails -and
                        -not $NameParameterDetails -and
                        ($_.Value.Name -ne 'Name') -and
                        ($_.Value.Name -eq $ResourceIdAndInputObjectDetails.ResourceName)) {
                        $_.Value['Alias'] = 'Name'
                    }
                }

                # If there are no mandatory parameters, use the parameter count as the priority.                
                if ($Priority -eq 100) {
                    $Priority = $ParametersCount
                }
            }

            $ParameterSetDetail = @{
                Description          = $FunctionDescription
                Synopsis             = $FunctionSynopsis
                ParameterDetails     = $ParametersTable
                Responses            = $responses
                ParameterSetName     = $operationId
                OperationId          = $operationId
                OperationType        = $operationType
                EndpointRelativePath = $EndpointRelativePath
                PathCommonParameters = $PathCommonParameters
                Priority             = $Priority
                'x-ms-pageable'      = $x_ms_pageableObject
            }

            if ((Get-Member -InputObject $_.Value -Name 'x-ms-odata') -and $_.Value.'x-ms-odata') {
                # Currently only the existence of this property is really important, but might as well save the value
                $ParameterSetDetail.'x-ms-odata' = $_.Value.'x-ms-odata'
            }

            # There's probably a better way to do this...
            $opIdValues = $operationId -split "_", 2
            if (-not $opIdValues -or ($opIdValues.Count -ne 2)) {
                $approximateVerb = $operationId
            }
            else {
                $approximateVerb = $opIdValues[1]
                if ((-not $UseAzureCsharpGenerator) -and 
                    (Test-OperationNameInDefinitionList -Name $opIdValues[0] -SwaggerDict $swaggerDict)) { 
                    $ParameterSetDetail['UseOperationsSuffix'] = $true
                }
            }
            
            $InputObjectParameterSetDetail = $null
            $ResourceIdParameterSetDetail = $null
            if ($ResourceIdAndInputObjectDetails) {
                # InputObject parameterset
                $InputObjectParameterDetails = @{
                    Name                  = 'InputObject'
                    Type                  = $ResourceIdAndInputObjectDetails.InputObjectParameterType
                    ValidateSet           = ''
                    Mandatory             = '$true'
                    Description           = "The input object of type $($ResourceIdAndInputObjectDetails.InputObjectParameterType)."
                    IsParameter           = $true
                    OriginalParameterName = 'InputObject'
                    FlattenOnPSCmdlet     = $false
                    ValueFromPipeline     = $true
                }
                $InputObjectParamSetParameterDetails = @{ 0 = $InputObjectParameterDetails }
                $index = 1
                $ClonedParameterSetDetail = $ParameterSetDetail.Clone()
                $ClonedParameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
                    $paramDetails = $_.Value
                    if ($ResourceIdAndInputObjectDetails.ResourceIdParameters -notcontains $paramDetails.Name) {
                        $InputObjectParamSetParameterDetails[$index++] = $paramDetails
                    }
                }
                $ClonedParameterSetDetail.ParameterDetails = $InputObjectParamSetParameterDetails
                $ClonedParameterSetDetail.Priority += 1
                $ClonedParameterSetDetail.ParameterSetName = "InputObject_$($ClonedParameterSetDetail.ParameterSetName)"
                $InputObjectParameterSetDetail = $ClonedParameterSetDetail

                # ResourceId parameterset
                $ResourceIdParameterDetails = @{
                    Name                            = 'ResourceId'
                    Type                            = 'System.String'
                    ValidateSet                     = ''
                    Mandatory                       = '$true'
                    Description                     = 'The resource id.'
                    IsParameter                     = $true
                    OriginalParameterName           = 'ResourceId'
                    FlattenOnPSCmdlet               = $false
                    ValueFromPipelineByPropertyName = $true
                }
                $ResourceIdParamSetParameterDetails = @{ 0 = $ResourceIdParameterDetails }
                $index = 1
                $ClonedParameterSetDetail = $ParameterSetDetail.Clone()
                $ClonedParameterSetDetail.ParameterDetails.GetEnumerator() | ForEach-Object {
                    $paramDetails = $_.Value
                    if ($ResourceIdAndInputObjectDetails.ResourceIdParameters -notcontains $paramDetails.Name) {
                        $ResourceIdParamSetParameterDetails[$index++] = $paramDetails
                    }
                }
                $ClonedParameterSetDetail.ParameterDetails = $ResourceIdParamSetParameterDetails
                $ClonedParameterSetDetail.Priority += 2
                $ClonedParameterSetDetail.ParameterSetName = "ResourceId_$($ClonedParameterSetDetail.ParameterSetName)"
                $ResourceIdParameterSetDetail = $ClonedParameterSetDetail

                $ParameterSetDetail['ClonedParameterSetNames'] = @(
                    "InputObject_$($ParameterSetDetail.ParameterSetName)",
                    "ResourceId_$($ParameterSetDetail.ParameterSetName)"
                )
                $ParameterSetDetail['ResourceIdParameters'] = $ResourceIdAndInputObjectDetails.ResourceIdParameters
            }

            $commandNames | ForEach-Object {
                $FunctionDetails = @{}
                if ($PathFunctionDetails.ContainsKey($_.name)) {
                    $FunctionDetails = $PathFunctionDetails[$_.name]
                }
                else {
                    $FunctionDetails['CommandName'] = $_.name
                    $FunctionDetails['x-ms-long-running-operation'] = $longRunningOperation
                }

                if ($_.ContainsKey('Metadata') -and (-not $FunctionDetails.ContainsKey("Metadata"))) {
                    $FunctionDetails['Metadata'] = $_.Metadata
                }

                if ($operationSecurityObject) {
                    $FunctionDetails['Security'] = $operationSecurityObject
                }

                $ParameterSetDetails = @()
                if ($FunctionDetails.ContainsKey('ParameterSetDetails')) {
                    $ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
                } 

                $ParameterSetDetails += $ParameterSetDetail
                if ($InputObjectParameterSetDetail) {
                    $ParameterSetDetails += $InputObjectParameterSetDetail
                }
                if ($ResourceIdParameterSetDetail) {
                    $ParameterSetDetails += $ResourceIdParameterSetDetail
                }
    
                $FunctionDetails['ParameterSetDetails'] = $ParameterSetDetails
                $PathFunctionDetails[$_.name] = $FunctionDetails
            }
        }
        elseif (-not ((Get-Member -InputObject $_ -Name 'Name') -and ($_.Name -eq 'Parameters'))) {
            $Message = $LocalizedData.UnsupportedSwaggerProperties -f ('JsonPathItemObject', $($_.Value | Out-String))
            Write-Warning -Message $Message
        }
    }
}

function New-SwaggerSpecPathCommand {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $PathFunctionDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PSHeaderComment,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'PSScriptAnalyzer')]
        [string]
        $Formatter = 'None',

        [Parameter(Mandatory = $false)]
        [hashtable]
        $PowerShellCodeGen
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $FunctionsToExport = @()
    Preprocess-PagingOperations -PathFunctionDetails $PathFunctionDetails
    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $FunctionsToExport += New-SwaggerPath -FunctionDetails $_.Value `
            -SwaggerMetaDict $SwaggerMetaDict `
            -SwaggerDict $SwaggerDict `
            -PathFunctionDetails $PathFunctionDetails `
            -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
            -PSHeaderComment $PSHeaderComment `
            -Formatter $Formatter `
            -PowerShellCodeGen $PowerShellCodeGen
    }

    return $FunctionsToExport
}

<# Mark any operations as paging operations if they're the target of any operation's x-ms-pageable.operationName property.
These operations will not generate -Page and -Paging, even though they're marked as pageable.
These are single page operations and should never be unrolled (in the case of -not -Paging) or accept IPage parameters (in the case of -Page) #>
function Preprocess-PagingOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParameterDetails,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $CandidateParameterDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterSetName,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersToAdd,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParameterHitCount
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameterName = $CandidateParameterDetails.Name
    if ($parameterDetails.IsParameter) {
        if (-not $parameterHitCount.ContainsKey($parameterName)) {
            $parameterHitCount[$parameterName] = 0
        }

        $parameterHitCount[$parameterName]++
        if (-not ($parametersToAdd.ContainsKey($parameterName))) {
            $parametersToAdd[$parameterName] = @{
                # We can grab details like Type, Name, ValidateSet from any of the parameter definitions
                Details          = $CandidateParameterDetails
                ParameterSetInfo = @{$ParameterSetName = @{
                        Name      = $ParameterSetName
                        Mandatory = $CandidateParameterDetails.Mandatory
                    }
                }
            }
        }
        else {
            $parametersToAdd[$parameterName].ParameterSetInfo[$ParameterSetName] = @{
                Name      = $ParameterSetName
                Mandatory = $CandidateParameterDetails.Mandatory
            }
        }
    }
}

function New-SwaggerPath {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
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
        $PathFunctionDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,
        
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PSHeaderComment,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'PSScriptAnalyzer')]
        [string]
        $Formatter = 'None',

        [Parameter(Mandatory = $false)]
        [hashtable]
        $PowerShellCodeGen
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $commandName = $FunctionDetails.CommandName
    $parameterSetDetails = $FunctionDetails['ParameterSetDetails']
    $isLongRunningOperation = $FunctionDetails.ContainsKey('x-ms-long-running-operation') -and $FunctionDetails.'x-ms-long-running-operation'
    $isNextPageOperation = $FunctionDetails.ContainsKey('IsNextPageOperation') -and $FunctionDetails.'IsNextPageOperation'
    $info = $SwaggerDict['Info']
    $namespace = $info['NameSpace']
    $models = $info['Models']
    $clientName = '$' + $info['ClientTypeName']
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    
    $description = ''
    $synopsis = ''
    $paramBlock = ''
    $paramHelp = ''
    $parametersToAdd = @{}
    $flattenedParametersOnPSCmdlet = @{}
    $parameterHitCount = @{}
    $globalParameters = @()
    $x_ms_pageableObject = $null
    $globalParametersStatic = @{}
    $filterBlock = $null
    # Process global metadata for commands
    if ($SwaggerDict.ContainsKey('CommandDefaults')) {
        foreach ($entry in $SwaggerDict['CommandDefaults'].GetEnumerator()) {
            $globalParametersStatic[$entry.Name] = Get-ValueText($entry.Value)
        }
    }
    # Process metadata for the overall command
    if ($FunctionDetails.ContainsKey('Metadata')) {
        if (Get-Member -InputObject $FunctionDetails['Metadata'] -Name 'ClientParameters') {
            foreach ($property in (Get-Member -InputObject $FunctionDetails['Metadata'].ClientParameters -MemberType NoteProperty)) {
                $globalParametersStatic[$property.Name] = Get-ValueText($FunctionDetails['Metadata'].ClientParameters.$($property.Name))
            }
        }
        if (Get-Member -InputObject $FunctionDetails['Metadata'] -Name 'clientSideFilters') {
            foreach ($clientSideFilter in $FunctionDetails['Metadata'].ClientSideFilters) {
                foreach ($filter in $clientSideFilter.Filters) {
                    if ($filter.Type -eq 'wildcard') {
                        if (-not (Get-Member -InputObject $filter -Name 'Character')) {
                            Add-Member -InputObject $filter -Name 'Character' -Value $PowerShellCodeGen['defaultWildcardChar'] -MemberType NoteProperty
                        }
                    }
                }
                $matchingParameters = @()
                $serverSideFunctionDetails = $null
                if ($clientSideFilter.ServerSideResultCommand -eq '.') {
                    $serverSideFunctionDetails = $FunctionDetails
                }
                else {
                    $serverSideFunctionDetails = $PathFunctionDetails[$clientSideFilter.ServerSideResultCommand]
                }
                if (-not $serverSideFunctionDetails) {
                    Write-Warning -Message ($LocalizedData.CouldntFindServerSideResultOperation -f $clientSideFilter.ServerSideResultCommand)
                }
                else {
                    $serverSideParameterSet = $serverSideFunctionDetails['ParameterSetDetails'] | Where-Object { $_.OperationId -eq $clientSideFilter.ServerSideResultParameterSet}
                    if (-not $serverSideParameterSet) {
                        # Warning: Couldn't find specified server-side parameter set
                        Write-Warning -Message ($LocalizedData.CouldntFindServerSideResultParameterSet -f $clientSideFilter.ServerSideResultParameterSet)
                    }
                    else {
                        $clientSideParameterSet = $parameterSetDetails | Where-Object { $_.OperationId -eq $clientSideFilter.ClientSideParameterSet }
                        if (-not $clientSideParameterSet) {
                            Write-Warning -Message ($LocalizedData.CouldntFindClientSideParameterSet -f $clientSideFilter.ClientSideParameterSet)
                        }
                        else {
                            $valid = $true
                            foreach ($parametersDetail in $serverSideParameterSet.ParameterDetails) {
                                foreach ($parameterDetailEntry in $parametersDetail.GetEnumerator()) {
                                    if ($parameterDetailEntry.Value.Mandatory -eq '$true' -and
                                        ((-not $parameterDetailEntry.Value.ContainsKey('ReadOnlyGlobalParameter')) -or $parameterDetailEntry.Value.ReadOnlyGlobalParameter) -and
                                        ((-not $parameterDetailEntry.Value.ContainsKey('ConstantValue')) -or $parameterDetailEntry.Value.ConstantValue)) {
                                        $clientSideParameter = $null
                                        foreach ($pd in $clientSideParameterSet.ParameterDetails.GetEnumerator()) {
                                            foreach ($entry in $pd.GetEnumerator()) {
                                                if (($entry.Value.Mandatory -eq '$true') -and ($entry.Value.Name -eq $parameterDetailEntry.Value.Name)) {
                                                    $clientSideParameter = $entry
                                                }
                                            }
                                        }
                                        if (-not $clientSideParameterSet) {
                                            # Warning: Missing client-side parameter
                                            Write-Warning -Message ($LocalizedData.MissingRequiredFilterParameter -f $parameterDetailEntry.Value.Name)
                                        }
                                        else {
                                            $matchingParameters += $parameterDetailEntry.Value.Name
                                        }
                                    }
                                }
                            }

                            if ($valid) {
                                $filterBlock = $executionContext.InvokeCommand.ExpandString($FilterBlockStr)
                            }
                        }
                    }
                }
                # If this is filled out, means that all the inputs were validated (except maybe the filter details)
                if ($filterBlock) {
                    foreach ($filter in $clientSideFilter.Filters) {
                        if (Get-Member -InputObject $filter -Name 'appendParameterInfo') {
                            $parameterDetails = @{
                                'Name'        = [Char]::ToUpper($filter.Parameter[0]) + $filter.Parameter.Substring(1)
                                'Mandatory'   = '$false'
                                'Type'        = $filter.AppendParameterInfo.Type
                                'ValidateSet' = ''
                                'Description' = 'Filter parameter'
                                'IsParameter' = $true
                            }
                            $AddUniqueParameter_params = @{
                                ParameterDetails          = $parameterDetails
                                CandidateParameterDetails = $parameterDetails
                                ParameterSetName          = $clientSideFilter.ClientSideParameterSet
                                ParametersToAdd           = $parametersToAdd
                                ParameterHitCount         = $parameterHitCount
                            }
                            Add-UniqueParameter @AddUniqueParameter_params
                        }
                    }
                }
            }
        }
    }
    foreach ($parameterSetDetail in $parameterSetDetails) {
        if ($parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            if ($x_ms_pageableObject -and 
                $x_ms_pageableObject.ContainsKey('ReturnType') -and 
                ($x_ms_pageableObject.ReturnType -ne 'NONE') -and
                ($x_ms_pageableObject.ReturnType -ne $parameterSetDetail.ReturnType)) {
                Write-Warning -Message ($LocalizedData.MultiplePageReturnTypes -f ($commandName))
                $x_ms_pageableObject.ReturnType = 'NONE'
            }
            elseif (-not $x_ms_pageableObject) {
                $x_ms_pageableObject = $parameterSetDetail.'x-ms-pageable'
                $x_ms_pageableObject['ReturnType'] = $parameterSetDetail.ReturnType
                if ($parameterSetDetail.ContainsKey('PSCmdletOutputItemType')) {
                    $x_ms_pageableObject['PSCmdletOutputItemType'] = $parameterSetDetail.PSCmdletOutputItemType
                }
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
                        }
                        else {
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
                }
                else {
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
                }
                elseif ($parameterDetails.ContainsKey('ReadOnlyGlobalParameter') -and $parameterDetails.ReadOnlyGlobalParameter) {
                    $parameterRequiresAdding = $false
                }
                else {
                    $globalParameterName = $parameterDetails.Name
                    $globalParameterValue = "```$$($parameterDetails.Name)"
                    if ($parameterDetails.ContainsKey('ConstantValue') -and $parameterDetails.ConstantValue) {
                        # A parameter with a constant value doesn't need to be in the parameter block
                        $parameterRequiresAdding = $false
                        $globalParameterValue = $parameterDetails.ConstantValue
                    }
                    
                    $globalParameters += $globalParameterName
                }
            }

            if ($parameterRequiresAdding) {
                $AddUniqueParameter_params = @{
                    ParameterDetails  = $parameterDetails
                    ParameterSetName  = $parameterSetDetail.ParameterSetName
                    ParametersToAdd   = $parametersToAdd
                    ParameterHitCount = $parameterHitCount
                }

                if ($parameterDetails.ContainsKey('x_ms_parameter_grouping_group')) {
                    foreach ($parameterDetailEntry in $parameterDetails.'x_ms_parameter_grouping_group'.GetEnumerator()) {
                        $AddUniqueParameter_params['CandidateParameterDetails'] = $parameterDetailEntry.Value
                        Add-UniqueParameter @AddUniqueParameter_params
                    }
                }
                elseif ($parameterDetails.ContainsKey('FlattenOnPSCmdlet') -and $parameterDetails.FlattenOnPSCmdlet) {
                    $DefinitionName = ($parameterDetails.Type -split '[.]')[-1]
                    if ($DefinitionFunctionsDetails.ContainsKey($DefinitionName)) {
                        $DefinitionDetails = $DefinitionFunctionsDetails[$DefinitionName]
                        $flattenedParametersOnPSCmdlet[$parameterDetails.Name] = $DefinitionDetails
                        $DefinitionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
                            if (-not $UseAzureCsharpGenerator -or (-not $_.value.ContainsKey('Source') -or ($_.value['Source'] -ne 'Resource') `
                                        -or ($_.value['Name'] -ne 'Name'))) {
                                $AddUniqueParameter_params['CandidateParameterDetails'] = $_.value
                                Add-UniqueParameter @AddUniqueParameter_params 
                                $_.value['IsFlattened'] = $true
                            }
                        }
                    }
                    else {
                        Throw ($LocalizedData.InvalidPSMetaFlattenParameter -f ($parameterDetails.Name, $parameterDetails.Type))
                    }
                }
                else {
                    $AddUniqueParameter_params['CandidateParameterDetails'] = $parameterDetails
                    Add-UniqueParameter @AddUniqueParameter_params
                }
            }
            else {
                # This magic string is here to distinguish local vs global parameters with the same name, e.g. in the Azure Resources API
                $parametersToAdd["$($parameterDetails.Name)Global"] = $null
            }
        }
    }
    $topParameterToAdd = $null
    $skipParameterToAdd = $null
    $pagingBlock = ''
    $pagingOperationName = ''
    $NextLinkName = 'NextLink'
    $pagingOperations = ''
    $Cmdlet = ''
    $CmdletParameter = ''
    $CmdletArgs = ''
    $pageType = 'Array'
    $PSCmdletOutputItemType = ''
    if ($x_ms_pageableObject) {
        if ($x_ms_pageableObject.ReturnType -ne 'NONE') {
            $pageType = $x_ms_pageableObject.ReturnType
            if ($x_ms_pageableObject.ContainsKey('PSCmdletOutputItemType')) {
                $PSCmdletOutputItemType = $x_ms_pageableObject.PSCmdletOutputItemType                
            }
        }

        if ($x_ms_pageableObject.ContainsKey('Operations')) {
            $pagingOperations = $x_ms_pageableObject.Operations
            $pagingOperationName = $x_ms_pageableObject.MethodName
        }
        else {
            $Cmdlet = $x_ms_pageableObject.Cmdlet
            $CmdletArgs = $x_ms_pageableObject.CmdletArgsPaging
        }

        if ($x_ms_pageableObject.ContainsKey('NextLinkName') -and $x_ms_pageableObject.NextLinkName) {
            $NextLinkName = $x_ms_pageableObject.NextLinkName
        }

        $topParameterToAdd = @{
            Details          = @{
                Name         = 'Top'
                Type         = 'int'
                Mandatory    = '$false'
                Description  = 'Return the top N items as specified by the parameter value. Applies after the -Skip parameter.'
                IsParameter  = $true
                ValidateSet  = $null
                ExtendedData = @{
                    Type            = 'int'
                    HasDefaultValue = $true
                    DefaultValue    = -1
                }
            }
            ParameterSetInfo = @{}
        }

        $skipParameterToAdd = @{
            Details          = @{
                Name         = 'Skip'
                Type         = 'int'
                Mandatory    = '$false'
                Description  = 'Skip the first N items as specified by the parameter value.'
                IsParameter  = $true
                ValidateSet  = $null
                ExtendedData = @{
                    Type            = 'int'
                    HasDefaultValue = $true
                    DefaultValue    = -1
                }
            }
            ParameterSetInfo = @{}
        }
    }

    # Process security section
    $AuthenticationCommand = ""
    $AuthenticationCommandArgumentName = ''
    $hostOverrideCommand = ''
    $AddHttpClientHandler = $false
    $securityParametersToAdd = @()
    $PowerShellCodeGen = $SwaggerMetaDict['PowerShellCodeGen']

    # CustomAuthCommand and HostOverrideCommand are not required for Arm Services
    if (($PowerShellCodeGen['ServiceType'] -ne 'azure') -and ($PowerShellCodeGen['ServiceType'] -eq 'azure_stack')) {
        if ($PowerShellCodeGen['CustomAuthCommand']) {
            $AuthenticationCommand = $PowerShellCodeGen['CustomAuthCommand']
        }
        if ($PowerShellCodeGen['HostOverrideCommand']) {
            $hostOverrideCommand = $PowerShellCodeGen['HostOverrideCommand']
        }
    }

    # If the auth function hasn't been set by metadata, try to discover it from the security and securityDefinition objects in the spec
    if (-not $AuthenticationCommand -and -not $UseAzureCsharpGenerator) {
        if ($FunctionDetails.ContainsKey('Security')) {
            # For now, just take the first security object
            if ($FunctionDetails.Security.Count -gt 1) {
                Write-Warning ($LocalizedData.MultipleSecurityTypesNotSupported -f $commandName)
            }
            $firstSecurityObject = Get-Member -InputObject $FunctionDetails.Security[0] -MemberType NoteProperty
            # If there's no security object, we don't care about the security definition object
            if ($firstSecurityObject) {
                # If there is one, we need to know the definition
                if (-not $swaggerDict.ContainsKey("SecurityDefinitions")) {
                    throw $LocalizedData.SecurityDefinitionsObjectMissing
                }

                $securityDefinitions = $swaggerDict.SecurityDefinitions
                $securityDefinition = $securityDefinitions.$($firstSecurityObject.Name)
                if (-not $securityDefinition) {
                    throw ($LocalizedData.SpecificSecurityDefinitionMissing -f ($firstSecurityObject.Name))
                }

                if (-not (Get-Member -InputObject $securityDefinition -Name 'type')) {
                    throw ($LocalizedData.SecurityDefinitionMissingProperty -f ($firstSecurityObject.Name, 'type'))
                }

                $type = $securityDefinition.type
                if ($type -eq 'basic') {
                    # For Basic Authentication, allow the user to pass in a PSCredential object.
                    $credentialParameter = @{
                        Details          = @{
                            Name         = 'Credential'
                            Type         = 'PSCredential'
                            Mandatory    = '$true'
                            Description  = 'User credentials.'
                            IsParameter  = $true
                            ValidateSet  = $null
                            ExtendedData = @{
                                Type            = 'PSCredential'
                                HasDefaultValue = $false
                            }
                        }
                        ParameterSetInfo = @{}
                    }
                    $securityParametersToAdd += @{
                        Parameter                           = $credentialParameter
                        IsConflictingWithOperationParameter = $false
                    }
                    # If the service is specified to not issue authentication challenges, we can't rely on HttpClientHandler
                    if ($PowerShellCodeGen['NoAuthChallenge'] -and ($PowerShellCodeGen['NoAuthChallenge'] -eq $true)) {
                        $AuthenticationCommand = 'param([pscredential]$Credential) Get-AutoRestCredential -Credential $Credential'
                        $AuthenticationCommandArgumentName = 'Credential'
                    }
                    else {
                        # Use an empty service client credentials object because we're using HttpClientHandler instead
                        $AuthenticationCommand = 'Get-AutoRestCredential'
                        $AddHttpClientHandler = $true
                    }
                }
                elseif ($type -eq 'apiKey') {
                    if (-not (Get-Member -InputObject $securityDefinition -Name 'name')) {
                        throw ($LocalizedData.SecurityDefinitionMissingProperty -f ($firstSecurityObject.Name, 'name'))
                    }

                    if (-not (Get-Member -InputObject $securityDefinition -Name 'in')) {
                        throw ($LocalizedData.SecurityDefinitionMissingProperty -f ($firstSecurityObject.Name, 'in'))
                    }

                    $name = $securityDefinition.name
                    $in = $securityDefinition.in
                    # For API key authentication, the user should supply the API key, but the in location and the name are generated from the spec
                    # In addition, we'd be unable to authenticate without the API key, so make it mandatory
                    $credentialParameter = @{
                        Details          = @{
                            Name         = 'APIKey'
                            Type         = 'string'
                            Mandatory    = '$true'
                            Description  = 'API key given by service owner.'
                            IsParameter  = $true
                            ValidateSet  = $null
                            ExtendedData = @{
                                Type            = 'string'
                                HasDefaultValue = $false
                            }
                        }
                        ParameterSetInfo = @{}
                    }
                    $securityParametersToAdd += @{
                        Parameter                           = $credentialParameter
                        IsConflictingWithOperationParameter = $false
                    }
                    $AuthenticationCommand = "param([string]`$APIKey) Get-AutoRestCredential -APIKey `$APIKey -Location '$in' -Name '$name'"
                    $AuthenticationCommandArgumentName = 'APIKey'
                }
                else {
                    Write-Warning -Message ($LocalizedData.UnsupportedAuthenticationType -f ($type))
                }
            }
        }
    }

    if (-not $AuthenticationCommand -and -not $UseAzureCsharpGenerator) {
        # At this point, there was no supported security object or overridden auth function, so assume no auth
        $AuthenticationCommand = 'Get-AutoRestCredential'
    }

    $nonUniqueParameterSets = @()
    foreach ($parameterSetDetail in $parameterSetDetails) {
        # Add parameter sets to paging parameter sets
        if ($topParameterToAdd -and $parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            $topParameterToAdd.ParameterSetInfo[$parameterSetDetail.ParameterSetName] = @{
                Name      = $parameterSetDetail.ParameterSetName
                Mandatory = '$false'
            }
        }

        if ($skipParameterToAdd -and $parameterSetDetail.ContainsKey('x-ms-pageable') -and $parameterSetDetail.'x-ms-pageable' -and (-not $isNextPageOperation)) {
            $skipParameterToAdd.ParameterSetInfo[$parameterSetDetail.ParameterSetName] = @{
                Name      = $parameterSetDetail.ParameterSetName
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
                    $additionalParameter.IsConflictingWithOperationParameter = $true
                    Write-Warning -Message ($LocalizedData.ParameterConflictAndResult -f ($additionalParameter.Parameter.Details.Name, $commandName, $parameterSetDetail.ParameterSetName, $LocalizedData.CredentialParameterNotSupported))
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
        if (-not $additionalParameter.IsConflictingWithOperationParameter) {
            $parametersToAdd[$additionalParameter.Parameter.Details.Name] = $additionalParameter.Parameter
        }
    }

    $pagingOperationCall = $null
    $PageResultPagingObjectStr = $null
    $TopPagingObjectStr = $null
    $SkipPagingObjectStr = $null
    $PageTypePagingObjectStr = $null
    if ($pagingOperations) {
        $pagingOperationCall = $executionContext.InvokeCommand.ExpandString($PagingOperationCallFunction)
    }
    elseif ($Cmdlet) {
        $pagingOperationCall = $executionContext.InvokeCommand.ExpandString($PagingOperationCallCmdlet)
    }

    if ($pagingOperationCall) {
        $pagingBlock = $executionContext.InvokeCommand.ExpandString($PagingBlockStrGeneric)
        $PageResultPagingObjectStr = $PageResultPagingObjectBlock
        $PageTypePagingObjectStr = $executionContext.InvokeCommand.ExpandString($PageTypeObjectBlock)
        if ($topParameterToAdd) {
            $TopPagingObjectStr = $TopPagingObjectBlock
        }

        if ($skipParameterToAdd) {
            $SkipPagingObjectStr = $SkipPagingObjectBlock
        }
    }

    # For description, we're currently using the default parameter set's description, since concatenating multiple descriptions doesn't ever really work out well.
    if ($nonUniqueParameterSets.Length -gt 1) {
        # Pick the highest priority set among $nonUniqueParameterSets, but really it doesn't matter, cause...
        # Print warning that this generated cmdlet has ambiguous parameter sets
        $defaultParameterSet = $nonUniqueParameterSets | Sort-Object {$_.Priority} | Select-Object -First 1
        $DefaultParameterSetName = $defaultParameterSet.ParameterSetName
        $description = $defaultParameterSet.Description
        $synopsis = $defaultParameterSet.Synopsis
        Write-Warning -Message ($LocalizedData.CmdletHasAmbiguousParameterSets -f ($commandName))
    }
    elseif ($nonUniqueParameterSets.Length -eq 1) {
        # If there's only one non-unique, we can prevent errors by making this the default
        $DefaultParameterSetName = $nonUniqueParameterSets[0].ParameterSetName
        $description = $nonUniqueParameterSets[0].Description
        $synopsis = $nonUniqueParameterSets[0].Synopsis
    }
    else {
        # Pick the highest priority set among all sets
        $defaultParameterSet = $parameterSetDetails | Sort-Object @{e = {$_.Priority -as [int] }} | Select-Object -First 1
        $DefaultParameterSetName = $defaultParameterSet.ParameterSetName
        $description = $defaultParameterSet.Description
        $synopsis = $defaultParameterSet.Synopsis        
    }

    $oDataExpression = ""
    $oDataExpressionBlock = ""
    # Variable used to replace in function body
    $parameterGroupsExpressionBlock = ""
    # Variable used to store all group expressions, concatenate, then store in $parameterGroupsExpressionBlock
    $parameterGroupsExpressions = @{}
    $ParameterAliasMapping = @{}
    $parametersToAdd.GetEnumerator() | ForEach-Object {
        $parameterToAdd = $_.Value
        $ValueFromPipelineString = ''
        $ValueFromPipelineByPropertyNameString = ''
        if ($parameterToAdd) {
            $parameterName = $parameterToAdd.Details.Name
            
            if ($parameterToAdd.Details.Containskey('ValueFromPipeline') -and $parameterToAdd.Details.ValueFromPipeline) {
                $ValueFromPipelineString = ', ValueFromPipeline = $true'
            }

            if ($parameterToAdd.Details.Containskey('ValueFromPipelineByPropertyName') -and $parameterToAdd.Details.ValueFromPipelineByPropertyName) {
                $ValueFromPipelineByPropertyNameString = ', ValueFromPipelineByPropertyName = $true'
            }

            $AllParameterSetsString = ''
            foreach ($parameterSetInfoEntry in $parameterToAdd.ParameterSetInfo.GetEnumerator()) {
                $parameterSetInfo = $parameterSetInfoEntry.Value
                $isParamMandatory = $parameterSetInfo.Mandatory
                $ParameterSetPropertyString = ", ParameterSetName = '$($parameterSetInfo.Name)'"
                if ($AllParameterSetsString) {
                    # Two tabs
                    $AllParameterSetsString += [Environment]::NewLine + "        " + $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
                }
                else {
                    $AllParameterSetsString = $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
                }
            }

            if (-not $AllParameterSetsString) {
                $isParamMandatory = $parameterToAdd.Details.Mandatory
                $ParameterSetPropertyString = ""
                $AllParameterSetsString = $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
            }

            $ParameterAliasAttribute = $null
            # Parameter has Name as an alias, change the parameter name to Name and add the current parameter name as an alias.            
            if ($parameterToAdd.Details.Containskey('Alias') -and 
                $parameterToAdd.Details.Alias -and
                ($parameterToAdd.Details.Alias -eq 'Name')) {
                $ParameterAliasMapping[$parameterName] = 'Name'
                $AliasString = "'$parameterName'"
                $parameterName = 'Name'
                $ParameterAliasAttribute = $executionContext.InvokeCommand.ExpandString($ParameterAliasAttributeString)
            }

            $paramName = "`$$parameterName"
            $ValidateSetDefinition = $null
            if ($parameterToAdd.Details.ValidateSet) {
                $ValidateSetString = $parameterToAdd.Details.ValidateSet
                $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
            }

            $parameterDefaultValueOption = ""
            $paramType = "$([Environment]::NewLine)        "
            if ($parameterToAdd.Details.ContainsKey('ExtendedData')) {
                if ($parameterToAdd.Details.ExtendedData.ContainsKey('IsODataParameter') -and $parameterToAdd.Details.ExtendedData.IsODataParameter) {
                    $paramType = "[$($parameterToAdd.Details.Type)]$paramType"
                    $oDataExpression += "    if (`$$parameterName) { `$oDataQuery += `"&```$$parameterName=`$$parameterName`" }" + [Environment]::NewLine
                }
                else {
                    # Assuming you can't group ODataQuery parameters
                    if ($parameterToAdd.Details.ContainsKey('x_ms_parameter_grouping') -and $parameterToAdd.Details.'x_ms_parameter_grouping') {
                        $parameterGroupPropertyName = $parameterToAdd.Details.Name
                        $groupName = $parameterToAdd.Details.'x_ms_parameter_grouping'
                        $fullGroupName = $parameterToAdd.Details.ExtendedData.GroupType
                        if ($parameterGroupsExpressions.ContainsKey($groupName)) {
                            $parameterGroupsExpression = $parameterGroupsExpressions[$groupName]
                        }
                        else {
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
                                }
                                elseif ("System.String" -eq $parameterToAdd.Details.ExtendedData.Type) {
                                    $parameterDefaultValue = "`"$($parameterToAdd.Details.ExtendedData.DefaultValue)`""
                                }
                                else {
                                    $parameterDefaultValue = "$($parameterToAdd.Details.ExtendedData.DefaultValue)"
                                }
                            }
                            else {
                                $parameterDefaultValue = "`$null"
                            }

                            $parameterDefaultValueOption = $executionContext.InvokeCommand.ExpandString($parameterDefaultValueString)
                        }
                    }
                }

                $paramBlock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
                $pDescription = $parameterToAdd.Details.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            }
            elseif ($parameterToAdd.Details.Containskey('Type')) {
                $paramType = "[$($parameterToAdd.Details.Type)]$paramType"

                $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
                $pDescription = $parameterToAdd.Details.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            }
            else {
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
        }
        else {
            $ParamBlockReplaceStr = $AsJobParameterString
        }

        $PathFunctionBody = $executionContext.InvokeCommand.ExpandString($PathFunctionBodyAsJob)
    }
    else {
        $ParamBlockReplaceStr = $paramBlock
        $PathFunctionBody = $executionContext.InvokeCommand.ExpandString($PathFunctionBodySynch)
    }

    $functionBodyParams = @{
        ParameterSetDetails            = $parameterSetDetails
        ODataExpressionBlock           = $oDataExpressionBlock
        ParameterGroupsExpressionBlock = $parameterGroupsExpressionBlock
        SwaggerDict                    = $SwaggerDict
        SwaggerMetaDict                = $SwaggerMetaDict
        FlattenedParametersOnPSCmdlet  = $flattenedParametersOnPSCmdlet
        ParameterAliasMapping          = $ParameterAliasMapping
        FilterBlock                    = $FilterBlock
    }
    if ($AuthenticationCommand) {
        $functionBodyParams['AuthenticationCommand'] = $AuthenticationCommand
        $functionBodyParams['AuthenticationCommandArgumentName'] = $AuthenticationCommandArgumentName
    }
    if ($AddHttpClientHandler) {
        $functionBodyParams['AddHttpClientHandler'] = $AddHttpClientHandler
    }    
    if ($hostOverrideCommand) {
        $functionBodyParams['hostOverrideCommand'] = $hostOverrideCommand
    }
    if ($globalParameters) {
        $functionBodyParams['GlobalParameters'] = $globalParameters
    }
    if ($globalParametersStatic) {
        $functionBodyParams['GlobalParametersStatic'] = $globalParametersStatic
    }
                           
    $pathGenerationPhaseResult = Get-PathFunctionBody @functionBodyParams
    $bodyObject = $pathGenerationPhaseResult.BodyObject

    $body = $bodyObject.Body
    if ($PSCmdletOutputItemType) {
        $fullPathDataType = $PSCmdletOutputItemType
        $outputTypeBlock = $executionContext.InvokeCommand.ExpandString($outputTypeStr)
    }
    else {
        $outputTypeBlock = $bodyObject.OutputTypeBlock        
    }

    if ($UseAzureCsharpGenerator) {
        $dependencyInitFunction = "Initialize-PSSwaggerDependencies -Azure"
    }
    else {
        $dependencyInitFunction = "Initialize-PSSwaggerDependencies"
    }
    
    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignatureForPath)
    $GeneratedCommandsPath = Join-Path -Path (Join-Path -Path $SwaggerMetaDict['outputDirectory'] -ChildPath $GeneratedCommandsName) `
        -ChildPath 'SwaggerPathCommands'

    if (-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$commandName.ps1"
    Out-File -InputObject (Get-FormattedFunctionContent -Content @($PSHeaderComment, $CommandString) -Formatter $Formatter) -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    Write-Verbose -Message ($LocalizedData.GeneratedPathCommand -f $commandName)

    return $commandName
}

function Set-ExtendedCodeMetadata {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $MainClientTypeName,

        [Parameter(Mandatory = $true)]
        [string]
        $CliXmlTmpPath
    )

    $resultRecord = @{
        VerboseMessages = @()
        ErrorMessages   = @()
        WarningMessages = @()
    }
    
    $resultRecord.VerboseMessages += $LocalizedData.ExtractingMetadata
    $parameters = Import-CliXml -Path $CliXmlTmpPath
    $PathFunctionDetails = $parameters['PathFunctionDetails']
    $DefinitionFunctionDetails = $parameters['DefinitionFunctionDetails']
    $ConstructorInfo = @{}
    $parameters['ConstructorInfo'] = $ConstructorInfo
    $Namespace = $parameters['Namespace']
    $Models = $parameters['Models']
    $DefinitionFunctionDetails.GetEnumerator() | ForEach-Object {
        $fullModelTypeName = ('{0}.{1}.{2}' -f ($Namespace, $Models, $_.Name))
        $fullModelType = $fullModelTypeName -as [Type]
        if ($fullModelType) {
            $nonDefaultConstructor = $fullModelType.GetConstructors() | Where-Object { $_.GetParameters().Length -gt 0 } | Select-Object -First 1
            # When available, use the non-default constructor to build objects (for read-only properties)
            if ($nonDefaultConstructor) {
                $nonDefaultConstructorParameters = @{}
                $nonDefaultConstructor.GetParameters() | ForEach-Object {
                    $nonDefaultConstructorParameters[$_.Name] = @{
                        'Name' = $_.Name
                        'Type' = $_.ParameterType
                        'Position' = $_.Position
                    }
                }
                $ConstructorInfo[$_.Name] = $nonDefaultConstructorParameters
            }
        }
    }
    $errorOccurred = $false
    $PathFunctionDetails.GetEnumerator() | ForEach-Object {
        $FunctionDetails = $_.Value
        $ParameterSetDetails = $FunctionDetails['ParameterSetDetails']
        foreach ($parameterSetDetail in $ParameterSetDetails) {
            if ($errorOccurred) {
                return
            }
            
            $operationId = $parameterSetDetail.OperationId
            $methodNames = @()
            $operations = ''
            $operationsWithSuffix = ''
            $opIdValues = $operationId -split '_', 2 
            if (-not $opIdValues -or ($opIdValues.count -ne 2)) {
                $normalizedOperationId = Get-CSharpMethodName -Name $operationId
                $methodNames += $normalizedOperationId + 'WithHttpMessagesAsync'
                $methodNames += $normalizedOperationId + 'Method' + 'WithHttpMessagesAsync'
            }
            else {           
                $operationName = (Get-CSharpModelName -Name $opIdValues[0]).Replace("-","") 
                $operationType = Get-CSharpMethodName -Name $opIdValues[1]
                $operations = ".$operationName"
                if ($parameterSetDetail['UseOperationsSuffix'] -and $parameterSetDetail['UseOperationsSuffix']) { 
                    $operationsWithSuffix = $operations + 'Operations'
                }

                $methodNames += $operationType + 'WithHttpMessagesAsync'
                # When OperationType value conflicts with a definition name, AutoREST generates method name by adding Method to the OperationType.
                $methodNames += $operationType + 'Method' + 'WithHttpMessagesAsync'
            }

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
                        CommandName         = $FunctionDetails['CommandName']
                        Name                = $matchingParamDetail.Value.Name
                        HasDefaultValue     = $false
                        IsGrouped           = $false
                        Type                = $_.PropertyType
                        MatchingParamDetail = $matchingParamDetail.Value
                        ResultRecord        = $resultRecord
                    }
                    if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms)) {
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
                }
                else {
                    $parameterSetDetail['Operations'] = $operationsWithSuffix
                }

                $clientType = $propertyObject.PropertyType
            }
            elseif ($operations) {
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

            $methodInfo = $clientType.GetMethods() | Where-Object {$MethodNames -contains $_.Name} | Select-Object -First 1
            if (-not $methodInfo) {
                $resultRecord.ErrorMessages += $LocalizedData.ExpectedMethodOnTypeNotFound -f (($MethodNames -join ', or '), $clientType)
                Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                $errorOccurred = $true
                return
            }
            $parameterSetDetail['MethodName'] = $methodInfo.Name

            # Process output type
            $returnType = $methodInfo.ReturnType
            if ($returnType.Name -eq 'Task`1') {
                $returnType = $returnType.GenericTypeArguments[0]
            }

            if ($returnType.Name -eq 'AzureOperationResponse`1') {
                $returnType = $returnType.GenericTypeArguments[0]
            }

            # Note: ReturnType and PSCmdletOutputItemType are currently used for Swagger operations which supports x-ms-pageable.
            if (($returnType.Name -eq 'IPage`1') -and $returnType.GenericTypeArguments) {
                $PSCmdletOutputItemTypeString = Convert-GenericTypeToString -Type $returnType.GenericTypeArguments[0]
                $parameterSetDetail['PSCmdletOutputItemType'] = $PSCmdletOutputItemTypeString.Trim('[]')
            }
            $parameterSetDetail['ReturnType'] = Convert-GenericTypeToString -Type $returnType

            $ParamList = @()
            $oDataQueryFound = $false
            $methodInfo.GetParameters() | Sort-Object -Property Position | ForEach-Object {
                $hasDefaultValue = $_.HasDefaultValue
                # All Types should be converted to their string names, otherwise the CLI XML gets too large
                $type = $_.ParameterType.ToString()
                $metadata = @{
                    Name            = Get-PascalCasedString -Name $_.Name
                    HasDefaultValue = $hasDefaultValue
                    Type            = $type
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
                                    CommandName         = $FunctionDetails['CommandName']
                                    Name                = $matchingParamDetail.Name
                                    HasDefaultValue     = $false
                                    IsGrouped           = $true
                                    Type                = $_.PropertyType
                                    MatchingParamDetail = $matchingGroupedParameterDetailEntry.Value
                                    ResultRecord        = $resultRecord
                                }

                                if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms)) {
                                    Export-CliXml -InputObject $ResultRecord -Path $CliXmlTmpPath
                                    $errorOccurred = $true
                                    return
                                }

                                $matchingGroupedParameterDetailEntry.Value.ExtendedData.GroupType = $parameterGroupType.ToString()
                            }
                        }
                    }
                    else {
                        # Single parameter
                        $setSingleParameterMetadataParms = @{
                            CommandName         = $FunctionDetails['CommandName']
                            Name                = $_.Name
                            HasDefaultValue     = $hasDefaultValue
                            IsGrouped           = $false
                            Type                = $_.ParameterType
                            MatchingParamDetail = $matchingParamDetail
                            ResultRecord        = $resultRecord
                        }

                        if ($hasDefaultValue) {
                            $setSingleParameterMetadataParms['DefaultValue'] = $_.DefaultValue
                        }

                        if (-not (Set-SingleParameterMetadata @setSingleParameterMetadataParms)) {
                            Export-CliXml -InputObject $ResultRecord -Path $CliXmlTmpPath
                            $errorOccurred = $true
                            return
                        }

                        $paramToAdd = $matchingParamDetail.ExtendedData.ParamToAdd
                    }
                    
                    $ParamList += $paramToAdd
                }
                else {
                    if ($metadata.Type.StartsWith("Microsoft.Rest.Azure.OData.ODataQuery``1")) {
                        if ($oDataQueryFound) {
                            $resultRecord.ErrorMessages += ($LocalizedData.MultipleODataQueriesOneFunction -f ($operationId))
                            Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
                            return
                        }
                        else {
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

    $resultRecord.Result = $parameters
    Export-CliXml -InputObject $resultRecord -Path $CliXmlTmpPath
}

function Convert-GenericTypeToString {
    param(
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
        [string]
        $CommandName,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [bool]
        $HasDefaultValue,

        [Parameter(Mandatory = $true)]
        [bool]
        $IsGrouped,

        [Parameter(Mandatory = $true)]
        [System.Type]
        $Type,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $MatchingParamDetail,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $ResultRecord,

        [Parameter(Mandatory = $false)]
        [object]
        $DefaultValue
    )
    
    $name = Get-PascalCasedString -Name $_.Name
    $metadata = @{
        Name            = $name
        HasDefaultValue = $HasDefaultValue
        Type            = $Type.ToString()
        ParamToAdd      = "`$$name"
    }

    if ($HasDefaultValue) {
        # Setting this default value actually matter, but we might as well
        if ("System.String" -eq $metadata.Type) {
            if ($DefaultValue -eq $null) {
                $metadata.HasDefaultValue = $false
                # This is the part that works around PS automatic string coercion
                $metadata.ParamToAdd = "`$(if (`$PSBoundParameters.ContainsKey('$($metadata.Name)')) { $($metadata.ParamToAdd) } else { [NullString]::Value })"
            }
        }
        elseif ("System.Nullable``1[System.Boolean]" -eq $metadata.Type) {
            if ($DefaultValue -ne $null) {
                $DefaultValue = "`$$DefaultValue"
            }

            $metadata.Type = "switch"
        }
        else {
            $DefaultValue = $_.DefaultValue
            if (-not ($_.ParameterType.IsValueType) -and $DefaultValue) {
                $ResultRecord.ErrorMessages += $LocalizedData.ReferenceTypeDefaultValueNotSupported -f ($metadata.Name, $metadata.Type, $CommandName)
                return $false
            }
        }

        $metadata['DefaultValue'] = $DefaultValue
    }
    else {
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
        [Parameter(Mandatory = $true)]
        [string]
        $FullClientTypeName
    )

    $random = [Guid]::NewGuid().Guid
    $filePath = Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath "$FullClientTypeName.$random.xml"
    return $filePath
}
<#
.SYNOPSIS
 Convert an object into a string to represents the value in PowerShell

.EXAMPLE
[string]this is a string => 'this is a string'
[bool]true => $true
[int]5 => 5
#>
function Get-ValueText {
    param(
        [Parameter(Mandatory = $true)]
        [object]
        $obj
    )

    if ($obj -is [string]) {
        return "'$obj'"
    }
    elseif ($obj -is [bool]) {
        return "`$$obj"
    }
    else {
        return $obj
    }
}