#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# SwaggerUtils Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1)
. "$PSScriptRoot\PSSwagger.Constants.ps1" -Force
. "$PSScriptRoot\Trie.ps1" -Force
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1
$script:CmdVerbTrie = $null

function ConvertTo-SwaggerDictionary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $SwaggerSpecPath,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [Version]
        $ModuleVersion
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $swaggerObject = ConvertFrom-Json ((Get-Content $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
    $swaggerDict = @{}

    if(-not (Get-Member -InputObject $swaggerObject -Name 'info')) {
        Throw $LocalizedData.InvalidSwaggerSpecification
    }
    $swaggerDict['Info'] = Get-SwaggerInfo -Info $swaggerObject.info -ModuleName $ModuleName -ModuleVersion $ModuleVersion

    $swaggerParameters = $null
    if(Get-Member -InputObject $swaggerObject -Name 'parameters') {
        $swaggerParameters = Get-SwaggerParameters -Parameters $swaggerObject.parameters -Info $swaggerDict['Info']
    }
    $swaggerDict['Parameters'] = $swaggerParameters

    $swaggerDefinitions = $null
    if(Get-Member -InputObject $swaggerObject -Name 'definitions') {
        $swaggerDefinitions = Get-SwaggerMultiItemObject -Object $swaggerObject.definitions
    }
    $swaggerDict['Definitions'] = $swaggerDefinitions

    if(-not (Get-Member -InputObject $swaggerObject -Name 'paths')) {
        Throw $LocalizedData.SwaggerPathsMissing
    }

    $swaggerPaths = Get-SwaggerMultiItemObject -Object $swaggerObject.paths
    $swaggerDict['Paths'] = $swaggerPaths

    return $swaggerDict
}

function Get-SwaggerInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Info,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [Version]
        $ModuleVersion
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $infoVersion = '1-0-0'
    if((Get-Member -InputObject $Info -Name 'Version') -and $Info.Version) { 
        $infoVersion = $Info.Version
    }

    $infoTitle = $Info.title
    $infoName = $infoTitle
    if((Get-Member -InputObject $Info -Name 'x-ms-code-generation-settings') -and 
       $Info.'x-ms-code-generation-settings'.Name)
    { 
        $infoName = $Info.'x-ms-code-generation-settings'.Name
    }

    $NamespaceVersionSuffix = "v$("$ModuleVersion" -replace '\.','')"

    return @{
        InfoVersion = $infoVersion
        InfoTitle = $infoTitle
        InfoName = $infoName
        Version = $ModuleVersion
        NameSpace = "Microsoft.PowerShell.$ModuleName.$NamespaceVersionSuffix"
        ModuleName = $ModuleName
    }
}

function Get-SwaggerParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Parameters,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Info
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $SwaggerParameters = @{}
    $Parameters.PSObject.Properties | ForEach-Object {
        $GlobalParameterName = $_.Name
        $GPJsonValueObject = $_.Value

        $IsParamMandatory = '$false'
        $ParameterDescription = ''
        $x_ms_parameter_location = ''

        if((Get-Member -InputObject $GPJsonValueObject -Name 'Name') -and $GPJsonValueObject.Name)
        {
            $parameterName = Get-PascalCasedString -Name $GPJsonValueObject.Name
        }

        if(Get-Member -InputObject $GPJsonValueObject -Name 'x-ms-parameter-location')
        {
            $x_ms_parameter_location = $GPJsonValueObject.'x-ms-parameter-location'
        }

        if((Get-Member -InputObject $GPJsonValueObject -Name 'Required') -and
            $GPJsonValueObject.Required)
        {
            $IsParamMandatory = '$true'
        }

        if ((Get-Member -InputObject $GPJsonValueObject -Name 'Description') -and
            $GPJsonValueObject.Description)
        {
            $ParameterDescription = $GPJsonValueObject.Description
        }

        $paramTypeObject = Get-ParamType -ParameterJsonObject $GPJsonValueObject `
                                         -NameSpace $Info.NameSpace `
                                         -ParameterName $parameterName

        $SwaggerParameters[$GlobalParameterName] = @{
            Name = $parameterName
            Type = $paramTypeObject.ParamType
            ValidateSet = $paramTypeObject.ValidateSetString
            Mandatory = $IsParamMandatory
            Description = $ParameterDescription
            IsParameter = $paramTypeObject.IsParameter
            x_ms_parameter_location = $x_ms_parameter_location
        }
    }

    return $SwaggerParameters
}

function Get-SwaggerMultiItemObject {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Object
    )

    $swaggerMultiItemObject = @{}

    $Object.PSObject.Properties | ForEach-Object {
        $swaggerMultiItemObject[$_.name] = $_
    }

    return $swaggerMultiItemObject
}

function Get-PathParamInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $SwaggerDict,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $DefinitionFunctionsDetails
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $ParametersTable = @{}
    $index = 0
    
    $JsonPathItemObject.parameters | ForEach-Object {
        $ParameterDetails = Get-ParameterDetails -ParameterJsonObject $_ `
                                                 -SwaggerDict $SwaggerDict `
                                                 -DefinitionFunctionsDetails $DefinitionFunctionsDetails

        if($ParameterDetails -and $ParameterDetails.Type)
        {
            $ParametersTable[$index] = $ParameterDetails
            $index = $index + 1            
        }
    }

    return $ParametersTable
}

function Get-ParameterDetails
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $ParameterJsonObject,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $SwaggerDict,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $DefinitionFunctionsDetails
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $NameSpace = $SwaggerDict['Info'].NameSpace

    $parameterName = ''        
    if((Get-Member -InputObject $ParameterJsonObject -Name 'Name') -and $ParameterJsonObject.Name)
    {
        $parameterName = Get-PascalCasedString -Name $ParameterJsonObject.Name
    }
   
    $GetParamTypeParameters = @{
        ParameterJsonObject = $ParameterJsonObject
        NameSpace = $NameSpace
        ParameterName = $parameterName
        DefinitionFunctionsDetails = $DefinitionFunctionsDetails
        SwaggerDict = $SwaggerDict
    }
    $paramTypeObject = Get-ParamType @GetParamTypeParameters

    # Swagger Path Operations can be defined with reference to the global method based parameters.
    # Add the method based global parameters as a function parameter.
    if($paramTypeObject.GlobalParameterDetails)
    {
        $ParameterDetails = $paramTypeObject.GlobalParameterDetails
    }
    else
    {
        $IsParamMandatory = '$false'
        $ParameterDescription = ''
        $x_ms_parameter_location = ''
        
        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Required') -and 
            $ParameterJsonObject.Required)
        {
            $IsParamMandatory = '$true'
        }

        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Description') -and 
            $ParameterJsonObject.Description)
        {
            $ParameterDescription = $ParameterJsonObject.Description
        }

        $ParameterDetails = @{
            Name = $parameterName
            Type = $paramTypeObject.ParamType
            ValidateSet = $paramTypeObject.ValidateSetString
            Mandatory = $IsParamMandatory
            Description = $ParameterDescription
            IsParameter = $paramTypeObject.IsParameter
            x_ms_parameter_location = $x_ms_parameter_location
        }
    }

    return $ParameterDetails
}

function Get-ParamType
{
    [CmdletBinding()]
	param
	(
        [Parameter(Mandatory=$true)]
        [PSObject]
        $ParameterJsonObject,

        [Parameter(Mandatory=$true)]
        [String]
        $NameSpace,

        [Parameter(Mandatory=$true)]
        [String]
        [AllowEmptyString()]
        $ParameterName,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $SwaggerDict,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $DefinitionFunctionsDetails
	)

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $DefinitionTypeNamePrefix = "$Namespace.Models."
    $paramType = ""
    $ValidateSetString = $null
    $isParameter = $true
    $GlobalParameterDetails = $null

    if((Get-Member -InputObject $ParameterJsonObject -Name 'Type') -and $ParameterJsonObject.Type)
    {
        $paramType = $ParameterJsonObject.Type

        # Use the format as parameter type if that is available as a type in PowerShell
        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Format') -and 
            $ParameterJsonObject.Format -and 
            ($null -ne ($ParameterJsonObject.Format -as [Type]))) 
        {
            $paramType = $ParameterJsonObject.Format
        }
        elseif (($ParameterJsonObject.Type -eq 'array') -and
                (Get-Member -InputObject $ParameterJsonObject -Name 'Items') -and 
                $ParameterJsonObject.Items)
        {
            if((Get-Member -InputObject $ParameterJsonObject.Items -Name '$ref') -and 
                $ParameterJsonObject.Items.'$ref')
            {
                $ReferenceTypeValue = $ParameterJsonObject.Items.'$ref'
                $ReferenceTypeName = $ReferenceTypeValue.Substring( $( $ReferenceTypeValue.LastIndexOf('/') ) + 1 )
                $paramType = $DefinitionTypeNamePrefix + "$ReferenceTypeName[]"
            }
            elseif((Get-Member -InputObject $ParameterJsonObject.Items -Name 'Type') -and $ParameterJsonObject.Items.Type)
            {
                $paramType = "$($ParameterJsonObject.Items.Type)[]"
            }
        }
        elseif (($ParameterJsonObject.Type -eq 'object') -and
                (Get-Member -InputObject $ParameterJsonObject -Name 'AdditionalProperties') -and 
                $ParameterJsonObject.AdditionalProperties)
        {
            $AdditionalPropertiesType = $ParameterJsonObject.AdditionalProperties.Type
            $paramType = "System.Collections.Generic.Dictionary[[$AdditionalPropertiesType],[$AdditionalPropertiesType]]"
        }
    }
    elseif($parameterName -eq 'Properties' -and
           (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-client-flatten') -and 
           ($ParameterJsonObject.'x-ms-client-flatten') )
    {
        # 'x-ms-client-flatten' extension allows to flatten deeply nested properties into the current definition.
        # Users often provide feedback that they don't want to create multiple levels of properties to be able to use an operation. 
        # By applying the x-ms-client-flatten extension, you move the inner properties to the top level of your definition.

        $ReferenceParameterValue = $ParameterJsonObject.'$ref'
        $ReferenceDefinitionName = $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )

        $ReferencedFunctionDetails = @{}
        if($DefinitionFunctionsDetails.ContainsKey($ReferenceDefinitionName))
        {
            $ReferencedFunctionDetails = $DefinitionFunctionsDetails[$ReferenceDefinitionName]
        }

        $ReferencedFunctionDetails['Name'] = $ReferenceDefinitionName
        $ReferencedFunctionDetails['IsUsedAs_x_ms_client_flatten'] = $true

        $DefinitionFunctionsDetails[$ReferenceDefinitionName] = $ReferencedFunctionDetails
    }
    elseif ( (Get-Member -InputObject $ParameterJsonObject -Name '$ref') -and ($ParameterJsonObject.'$ref') )
    {
        <#
            Currently supported reference parameter types:
                #/parameters/<PARAMNAME>
                #/parameters/<DEFINITIONNAME>
        #>
        $ReferenceParameterValue = $ParameterJsonObject.'$ref'
        $ReferenceParts = $ReferenceParameterValue -split '/' | ForEach-Object { if($_.Trim()){ $_.Trim() } }
        if($ReferenceParts.Count -eq 3)
        {                
            if($ReferenceParts[1] -eq 'Parameters')
            {
                #/parameters/
                $GlobalParameters = $SwaggerDict['Parameters']
                $GlobalParamDetails = $GlobalParameters[$ReferenceParts[2]]

                # Valid values for this extension are: "client", "method".
                if($GlobalParamDetails.x_ms_parameter_location -eq 'method')
                {
                    $GlobalParameterDetails = $GlobalParamDetails
                }
                else
                {
                    $isParameter = $false
                }
            }
            elseif($ReferenceParts[1] -eq 'Definitions')
            {
                #/definitions/
                $paramType = $DefinitionTypeNamePrefix + $ReferenceParts[2]
            }
        }
    }
    elseif ((Get-Member -InputObject $ParameterJsonObject -Name 'Schema') -and ($ParameterJsonObject.Schema) -and
            (Get-Member -InputObject $ParameterJsonObject.Schema -Name '$ref') -and ($ParameterJsonObject.Schema.'$ref') )
    {
        $ReferenceParameterValue = $ParameterJsonObject.Schema.'$ref'
        $paramType = $DefinitionTypeNamePrefix + $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
    }
    else 
    {
        $paramType = 'object'
    }

    if($paramType -and ($paramType -eq 'Boolean'))
    {
        $paramType = 'switch'
    }

    if ((Get-Member -InputObject $ParameterJsonObject -Name 'Enum') -and $ParameterJsonObject.Enum)
    {
        if((Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-enum') -and 
            $ParameterJsonObject.'x-ms-enum' -and 
            ($ParameterJsonObject.'x-ms-enum'.modelAsString -eq $false))
        {
            $paramType = $DefinitionTypeNamePrefix + $ParameterJsonObject.'x-ms-enum'.Name
        }
        else
        {
            $ValidateSet = $ParameterJsonObject.Enum
            $ValidateSetString = "'$($ValidateSet -join "', '")'"
        }
    }

    return @{
        ParamType = $paramType
        ValidateSetString = $ValidateSetString
        IsParameter = $isParameter
        GlobalParameterDetails = $GlobalParameterDetails
    }
}

function Get-PathCommandName
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $OperationId
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $opId = $OperationId
    
    $cmdNounMap = @{
                        Create = 'New'
                        Activate = 'Enable'
                        Delete = 'Remove'
                        List   = 'Get'
                        CreateOrUpdate = 'New,Set'
                   }

    if ($script:CmdVerbTrie -eq $null) {
        $script:CmdVerbTrie = New-Trie
        foreach ($verb in $cmdNounMap) {
            $script:CmdVerbTrie = Add-WordToTrie -Word $verb -Trie $script:CmdVerbTrie
        }
    }

    $currentTriePtr = $script:CmdVerbTrie
    
    $opIdValues = $opId  -split "_",2
    
    # OperationId can be specified without '_' (Underscore), return the OperationId as command name
    if(-not $opIdValues -or ($opIdValues.Count -ne 2)) {
        return $opId
    }

    $cmdNoun = $opIdValues[0]
    $cmdVerb = $opIdValues[1]
    if (-not (get-verb $cmdVerb))
    {
        $message = $LocalizedData.UnapprovedVerb -f ($cmdVerb)
        Write-Verbose $message
        
        if ($cmdNounMap.ContainsKey($cmdVerb))
        {
            # This condition happens when there aren't any suffixes
            $cmdVerb = $cmdNounMap[$cmdVerb] -Split ',' | ForEach-Object { if($_.Trim()){ $_.Trim() } }
            $cmdVerb | ForEach-Object {
                $message = $LocalizedData.ReplacedVerb -f ($_, $cmdVerb)
                Write-Verbose -Message $message
            }
        }
        else
        {
            # This condition happens in cases like: CreateSuffix, CreateOrUpdateSuffix
            $longestVerbMatch = $null
            $currentVerbCandidate = ''
            $firstWord = ''
            $firstWordStarted = $false
            $buildFirstWord = $false
            $firstWordEnd = -1
            $verbMatchEnd = -1
            for($i = 0; $i -lt $opIdValues[1].Length; $i++) {
                # Add the start condition of the first word so that the end condition is easier
                if ((-not $firstWordStarted) -and ([int]$opIdValues[1][$i] -ge 65) -and ([int]$opIdValues[1][$i] -le 90)) {
                    $firstWordStarted = $true
                    $buildFirstWord = $true
                } elseif ($buildFirstWord -and ([int]$opIdValues[1][$i] -ge 65) -and ([int]$opIdValues[1][$i] -le 90)) {
                    # Stop building the first word when we encounter another capital letter
                    $buildFirstWord = $false
                    $firstWordEnd = $i
                }

                if ($buildFirstWord) {
                    $firstWord += $opIdValues[1][$i]
                }

                if ($currentTriePtr) {
                    # If we're still running along the trie just fine, keep checking the next letter
                    $currentVerbCandidate += $opIdValues[1][$i]
                    $currentTriePtr = Test-Trie -Trie $currentTriePtr -Letter $opIdValues[1][$i]
                    if ($currentTriePtr -and (Test-TrieLeaf -Trie $currentTriePtr)) {
                        # The latest verb match is also the longest verb match
                        $longestVerbMatch = $currentVerbCandidate
                        $verbMatchEnd = $i+1
                    }
                }
            }

            if ($longestVerbMatch) {
                $beginningOfSuffix = $verbMatchEnd
                $cmdVerb = $longestVerbMatch
            } else {
                $beginningOfSuffix = $firstWordEnd
                $cmdVerb = $firstWord
            }

            if ($cmdNounMap.ContainsKey($cmdVerb)) { 
                $cmdVerb = $cmdNounMap[$cmdVerb] -Split ',' | ForEach-Object { if($_.Trim()){ $_.Trim() } }
            }

            if (-1 -ne $beginningOfSuffix) {
                # This is still empty when a verb match is found that is the entire string, but it might not be worth checking for that case and skipping the below operation
                $cmdNounSuffix = $opIdValues[1].Substring($beginningOfSuffix)
                # Add command noun suffix only when the current noun is not ending with the same suffix. 
                if(-not $cmdNoun.EndsWith($cmdNounSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $cmdNoun = $cmdNoun + $opIdValues[1].Substring($firstWordEnd)
                }
            }

            $cmdVerb | ForEach-Object {
                $message = $LocalizedData.UsingNounVerb -f ($cmdNoun, $_)
                Write-Verbose -Message $message
            }
        }
    }

    $cmdletNames = $cmdVerb | ForEach-Object {
        "$_-$cmdNoun"
    }

    return $cmdletNames
}

function Convert-ParamTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ParamTable,

        [Parameter(Mandatory=$true)]
        [String]
        $ParameterSetName
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $requiredParamList = @()
    $optionalParamList = @()
    $keyCount = $ParamTable.Keys.Count
    if($keyCount)
    {
        # This foreach is required to get the parameters in sequential/expected order 
        # to call the AutoRest generated client API.
        foreach($key in 0..($keyCount - 1))
        {
            $ParameterDetails = $ParamTable[$key]

            if($ParameterDetails.IsParameter) {
                $isParamMandatory = $ParameterDetails.Mandatory
                $parameterName = $ParameterDetails.Name
                $paramName = "`$$parameterName" 

                if ($isParamMandatory -eq '$true')
                {
                    $requiredParamList += $paramName
                }
                else
                {
                    $optionalParamList += $paramName
                }
            }
        }
    }

    $requiredParamList = $requiredParamList -join ', '
    $optionalParamList = $optionalParamList -join ', '

    $paramObject = @{ 
                      RequiredParamList = $requiredParamList
                      OptionalParamList = $optionalParamList
                    }

    return $paramObject
}

function Get-PathFunctionBody
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]
        $ParameterSetDetails,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerDict,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerMetaDict
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $outputTypeBlock = $null
    $Info = $swaggerDict['Info']
    $DefinitionList = $swaggerDict['Definitions']
    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    $infoVersion = $Info['infoVersion']
    $modulePostfix = $Info['infoName']
    $clientName = '$' + $modulePostfix
    $NameSpace = $info.namespace
    $fullModuleName = $Namespace + '.' + $modulePostfix
    $apiVersion = $null
    $SubscriptionId = $null
    $BaseUri = $null
    $GetServiceCredentialStr = ''
    $AdvancedFunctionEndCodeBlock = ''
    $GetServiceCredentialStr = 'Get-AzServiceCredential'

    if (-not $UseAzureCsharpGenerator)
    {
        $apiVersion = $executionContext.InvokeCommand.ExpandString($ApiVersionStr)
    }

    $parameterSetBasedMethodStr = ''
    foreach ($parameterSetDetail in $ParameterSetDetails) {
        $RequiredParamList = $parameterSetDetail.RequiredParamList
        # Responses isn't actually used right now, but keeping this when we need to handle responses per parameter set
        $Responses = $parameterSetDetail.Responses
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
            if ((-not $UseAzureCsharpGenerator) -and 
                (Test-OperationNameInDefinitionList -Name $operationName -SwaggerDict $SwaggerDict))
            { 
                $operations = $operations + 'Operations'
            }
            $methodName = $operationType + 'WithHttpMessagesAsync'
        }

        $responseBodyParams = @{
                                responses = $Responses.PSObject.Properties
                                namespace = $Namespace
                                definitionList = $DefinitionList
                            }

        $responseBody, $currentOutputTypeBlock = Get-Response @responseBodyParams

        # For now, use the first non-empty output type
        if ((-not $outputTypeBlock) -and $currentOutputTypeBlock) {
            $outputTypeBlock = $currentOutputTypeBlock
        }

        if ($parameterSetBasedMethodStr) {
            # Add the elseif condition
            $parameterSetBasedMethodStr += $executionContext.InvokeCommand.ExpandString($parameterSetBasedMethodStrElseIfCase)
        } else {
            # Add the beginning if condition
             $parameterSetBasedMethodStr += $executionContext.InvokeCommand.ExpandString($parameterSetBasedMethodStrIfCase)
        }
    }

    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    $bodyObject = @{ OutputTypeBlock = $outputTypeBlock;
                     Body = $body;
                    }

    return $bodyObject
}

function Test-OperationNameInDefinitionList
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerDict
    )

    return $SwaggerDict['Definitions'].ContainsKey($Name)
}

function Get-OutputType
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Schema,

        [Parameter(Mandatory=$true)]
        [String]
        $NameSpace, 

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DefinitionList
    )

    $outputType = ""
    if(Get-member -inputobject $schema -name '$ref')
    {
        $ref = $schema.'$ref'
        if($ref.StartsWith("#/definitions"))
        {
            $key = $ref.split("/")[-1]
            if ($definitionList.ContainsKey($key))
            {
                $definition = ($definitionList[$key]).Value
                if(Get-Member -InputObject $definition -name 'properties')
                {
                    $defProperties = $definition.properties
                    $fullPathDataType = ""

                    # If this data type is actually a collection of another $ref 
                    if(Get-member -InputObject $defProperties -Name 'value')
                    {
                        $defValue = $defProperties.value
                        $outputValueType = ""
                        
                        # Iff the value has items with $ref nested properties,
                        # this is a collection and hence we need to find the type of collection

                        if((Get-Member -InputObject $defValue -Name 'items') -and 
                            (Get-Member -InputObject $defValue.items -Name '$ref'))
                        {
                            $defRef = $defValue.items.'$ref'
                            if($ref.StartsWith("#/definitions")) 
                            {
                                $defKey = $defRef.split("/")[-1]
                                $fullPathDataType = $NameSpace + ".Models.$defKey"
                            }

                            if(Get-member -InputObject $defValue -Name 'type') 
                            {
                                $defType = $defValue.type
                                switch ($defType) 
                                {
                                    "array" { $outputValueType = '[]' }
                                    Default {
                                        $exceptionMessage = $LocalizedData.DataTypeNotImplemented -f ($defType, $ref)
                                        throw ([System.NotImplementedException] $exceptionMessage)
                                    }
                                }
                            }

                            if($outputValueType -and $fullPathDataType) {$fullPathDataType = $fullPathDataType + " " + $outputValueType}
                        }
                        else
                        { # if this datatype has value, but no $ref and items
                            $fullPathDataType = $NameSpace + ".Models.$key"
                        }
                    }
                    else
                    { # if this datatype is not a collection of another $ref
                        $fullPathDataType = $NameSpace + ".Models.$key"
                    }

                    $fullPathDataType = $fullPathDataType.Replace('[','').Replace(']','').Trim()
                    $outputType += $executionContext.InvokeCommand.ExpandString($outputTypeStr)
                }
            }
        }
    }

    return $outputType
}

function Get-Response
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Responses,
        
        [Parameter(Mandatory=$true)]
        [String]
        $NameSpace, 

        [Parameter(Mandatory=$true)]        
        [hashtable]
        $DefinitionList
    )

    $outputTypeFlag = $false
    $responseBody = ""
    $outputType = ""
    $failWithDesc = ""

    $failWithDesc = ""
    $responses | ForEach-Object {
        $responseStatusValue = "'" + $_.Name + "'"
        $value = $_.Value

        switch($_.Name) {
            # Handle Success
            {200..299 -contains $_} {
                if(-not $outputTypeFlag -and (Get-member -inputobject $value -name "schema"))
                {
                    # Add the [OutputType] for the function
                    $OutputTypeParams = @{
                        "schema"  = $value.schema
                        "namespace" = $NameSpace 
                        "definitionList" = $definitionList
                    }

                    $outputType = Get-OutputType @OutputTypeParams
                    $outputTypeFlag = $true
                }
            }
            # Handle Client Error
            {400..499 -contains $_} {
                if($Value.description)
                {
                    $failureDescription = "Write-Error 'CLIENT ERROR: " + $value.description + "'"
                    $failWithDesc += $executionContext.InvokeCommand.ExpandString($failCase)
                }
            }
            # Handle Server Error
            {500..599 -contains $_} {
                if($Value.description)
                {
                    $failureDescription = "Write-Error 'SERVER ERROR: " + $value.description + "'"
                    $failWithDesc += $executionContext.InvokeCommand.ExpandString($failCase)
                }
            }
        }
    }

    $responseBody += $executionContext.InvokeCommand.ExpandString($responseBodySwitchCase)
    
    return $responseBody, $outputType
}