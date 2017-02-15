#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# SwaggerUtils Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1)
. "$PSScriptRoot\PSSwagger.Constants.ps1"
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

function ConvertTo-SwaggerDictionary {
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $SwaggerSpecPath,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName
    )

    $swaggerObject = ConvertFrom-Json ((Get-Content $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
    $swaggerDict = @{}

    if(-not (Get-Member -InputObject $swaggerObject -Name 'info')) {
        Throw $LocalizedData.InvalidSwaggerSpecification
    }

    $swaggerInfo = Get-SwaggerInfo -Info $swaggerObject.info
    $swaggerDict.Add("info", $swaggerInfo)

    $swaggerParameters = $null
    if(Get-Member -InputObject $swaggerObject -Name 'parameters') {
        $swaggerParameters = Get-SwaggerParameters -Parameters $swaggerObject.parameters
    }
    $swaggerDict.Add("parameters", $swaggerParameters)

    $swaggerDefinitions = $null
    if(Get-Member -InputObject $swaggerObject -Name 'definitions') {
        $swaggerDefinitions = Get-SwaggerMultiItemObject -Object $swaggerObject.definitions
    }
    $swaggerDict.Add("definitions", $swaggerDefinitions)

    if(-not (Get-Member -InputObject $swaggerObject -Name 'paths')) {
        $message = $LocalizedData.SwaggerPathsMissing
        Throw $message
    }

    $swaggerPaths = Get-SwaggerMultiItemObject -Object $swaggerObject.paths
    $swaggerDict.Add("paths", $swaggerPaths)

    return $swaggerDict
}

function Get-SwaggerInfo {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Info
    )

    $infoVersion = '1-0-0'
    if((Get-Member -InputObject $Info -Name 'Version') -and $Info.Version) { 
        $infoVersion = $Info.Version
    }

    $infoTitle = $Info.title
    $infoName = ''
    if((Get-Member -InputObject $Info -Name 'x-ms-code-generation-settings') -and $Info.'x-ms-code-generation-settings'.Name) { 
        $infoName = $Info.'x-ms-code-generation-settings'.Name
    }

    if (-not $infoName) {
        $infoName = $infoTitle
    }

    $version = [Version](($infoVersion -split "-",4) -join '.')

    $NamespaceVersionSuffix = "v$(($infoVersion -split '-',4) -join '')"
    $Namespace = "Microsoft.PowerShell.$ModuleName.$NamespaceVersionSuffix"
    $ModuleName = $ModuleName

    $swaggerInfo = @{}
    $swaggerInfo.Add('InfoVersion',$infoVersion);
    $swaggerInfo.Add('InfoTitle',$infoTitle);
    $swaggerInfo.Add('InfoName',$infoName);
    $swaggerInfo.Add('Version',$version);
    $swaggerInfo.Add('NameSpace', $Namespace);
    $swaggerInfo.Add('ModuleName', $ModuleName);

    return $swaggerInfo
}

function Get-SwaggerParameters {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Parameters
    )

    $swaggerParameters = @{}

    $Parameters.PSObject.Properties | ForEach-Object {
        $name = Get-PascalCasedString -Name $_.name
        $swaggerParameters[$name] = $Parameters.$name
    }

    return $swaggerParameters
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
    param
    (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Info,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $DefinitionFunctionsDetails
    )

    $ParametersTable = @{}
    $index = 0
    
    $JsonPathItemObject.parameters | ForEach-Object {

        $ParameterJsonObject = $_
        $ParameterDetails = @{}
        $IsParamMandatory = '$false'
        $ParameterDescription = ''
        $parameterName = ''
        $NameSpace = $Info.namespace
            
        if((Get-Member -InputObject $_ -Name 'Name') -and $_.Name)
        {
            $parameterName = Get-PascalCasedString -Name $_.Name
        }

        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Required') -and $ParameterJsonObject.Required)
        {
            $IsParamMandatory = '$true'
        }

        $paramTypeObject = Get-ParamType -ParameterJsonObject $ParameterJsonObject `
                                        -NameSpace $NameSpace `
                                        -parameterName $parameterName `
                                        -DefinitionFunctionsDetails $DefinitionFunctionsDetails

        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Description') -and $ParameterJsonObject.Description)
        {
            $ParameterDescription = $ParameterJsonObject.Description
        }

        $ParameterDetails['Name'] = $parameterName
        $ParameterDetails['Type'] = $paramTypeObject.ParamType
        $ParameterDetails['ValidateSet'] = $paramTypeObject.ValidateSetString
        $ParameterDetails['Mandatory'] = $IsParamMandatory
        $ParameterDetails['Description'] = $ParameterDescription
        $ParameterDetails['isParameter'] = $paramTypeObject.isParameter

        if($paramTypeObject.ParamType)
        {
            $ParametersTable[$index] = $ParameterDetails
            $index = $index + 1
        }
    }

    return $ParametersTable
}

function Get-ParamType
{
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
		$parameterName,
		
		[Parameter(Mandatory=$true)]
        [hashtable]
		$DefinitionFunctionsDetails
	)

	$DefinitionTypeNamePrefix = "$Namespace.Models."
    $paramType = ""
    $ValidateSetString = $null
    $isParameter = $true

	if((Get-Member -InputObject $ParameterJsonObject -Name 'Type') -and $ParameterJsonObject.Type)
	{
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
			else
			{
				$paramType = $ParameterJsonObject.Type
			}                             
		}
		elseif (($ParameterJsonObject.Type -eq 'object') -and
				(Get-Member -InputObject $ParameterJsonObject -Name 'AdditionalProperties') -and 
				$ParameterJsonObject.AdditionalProperties)
		{
			$AdditionalPropertiesType = $ParameterJsonObject.AdditionalProperties.Type
			$paramType = "System.Collections.Generic.Dictionary[[$AdditionalPropertiesType],[$AdditionalPropertiesType]]"
		}
		else
		{
			$paramType = $ParameterJsonObject.Type
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

			$x_ms_Client_flatten_DefinitionNames += $ReferenceDefinitionName

			$ReferencedFunctionDetails = @{}
			if($DefinitionFunctionsDetails.ContainsKey($ReferenceDefinitionName))
			{
				$ReferencedFunctionDetails = $DefinitionFunctionsDetails[$ReferenceDefinitionName]
			}

			$ReferencedFunctionDetails['Name'] = $ReferenceDefinitionName
			$ReferencedFunctionDetails['IsUsedAs_x_ms_client_flatten'] = $true
			$paramType = $DefinitionFunctionsDetails[$ReferenceDefinitionName] = $ReferencedFunctionDetails
		}
	elseif ( (Get-Member -InputObject $ParameterJsonObject -Name '$ref') -and ($ParameterJsonObject.'$ref') )
	{
		$ReferenceParameterValue = $ParameterJsonObject.'$ref'
		$isParameter = $false
		$paramType = $DefinitionTypeNamePrefix + $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
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

	if($paramType -eq 'Boolean')
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

	$paramTypeObject = @{ ParamType = $paramType;
						 ValidateSetString = $ValidateSetString;
                         isParameter = $isParameter
					}

	return $paramTypeObject

}

function Get-PathCommandName
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $OperationId
    )

    $opId = $OperationId
    $cmdNounMap = @{
                    Create = 'New'
                    Activate = 'Enable'
                    Delete = 'Remove'
                    List   = 'GetAll'
                }
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
            $message = $LocalizedData.ReplacedVerb -f ($($cmdNounMap[$cmdVerb]), $cmdVerb)
            Write-Verbose -Message $message
            $cmdVerb = $cmdNounMap[$cmdVerb]
        }
        else
        {
            $idx=1
            for(; $idx -lt $opIdValues[1].Length; $idx++)
            { 
                if (([int]$opIdValues[1][$idx] -ge 65) -and ([int]$opIdValues[1][$idx] -le 90)) {
                    break
                }
            }
            
            $cmdNounSuffix = $opIdValues[1].Substring($idx)
            # Add command noun suffix only when the current noun is not ending with the same suffix. 
            if(-not $cmdNoun.EndsWith($cmdNounSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $cmdNoun = $cmdNoun + $opIdValues[1].Substring($idx)
            }
            
            $cmdVerb = $opIdValues[1].Substring(0,$idx)            
            if ($cmdNounMap.ContainsKey($cmdVerb)) { 
                $cmdVerb = $cmdNounMap[$cmdVerb]
            }          

            $message = $LocalizedData.UsingNounVerb -f ($cmdNoun, $cmdVerb)
            Write-Verbose -Message $message
        }
    }

    return "$cmdVerb-$cmdNoun"
}

function Convert-ParamTable
{
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ParamTable
    )

    $paramblock = ""
    $paramHelp = ""
    $requiredParamList = @()
    $optionalParamList = @()

    $keyCount = $ParamTable.Keys.Count
    foreach($key in 0..($keyCount - 1)){
        $ParameterDetails = $ParamTable[$key]

        if($ParameterDetails.isParameter) {
            $isParamMandatory = $ParameterDetails.Mandatory
            $parameterName = $ParameterDetails.Name
            $paramName = "`$$parameterName" 
            $paramType = $ParameterDetails.Type

            $ValidateSetDefinition = $null
            if ($ParameterDetails.ValidateSet)
            {
                $ValidateSetString = $ParameterDetails.ValidateSet
                $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
            }

            if ($isParamMandatory -eq '$true')
            {
                $requiredParamList += $paramName
            }
            else
            {
                $optionalParamList += $paramName
            }

            $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)
            $pDescription = $ParameterDetails.Description
            $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
        }
    }

    $paramblock = $paramBlock.TrimEnd().TrimEnd(",")
    $requiredParamList = $requiredParamList -join ', '
    $optionalParamList = $optionalParamList -join ', '

    $paramObject = @{ ParamHelp = $paramhelp;
                      ParamBlock = $paramBlock;
                      RequiredParamList = $requiredParamList;
                      OptionalParamList = $optionalParamList;
                    }

    return $paramObject
}

function Get-PathFunctionBody
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Responses,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Info,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $DefinitionList,

        [Parameter(Mandatory=$true)]
        [String]
        $operationId,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String]
        $RequiredParamList,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String]
        $OptionalParamList,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    $UseAzureCsharpGenerator = $SwaggerMetaDict['UseAzureCsharpGenerator']
    $infoVersion = $Info['infoVersion']
    $modulePostfix = $Info['infoName']
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
            (Test-OperationNameInDefinitionList -Name $operationName -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters))
        { 
            $operations = $operations + 'Operations'
        }
        $methodName = $operationType + 'WithHttpMessagesAsync'
    }

    $NameSpace = $info.namespace
    $fullModuleName = $Namespace + '.' + $modulePostfix
    $clientName = '$' + $modulePostfix
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

    $responseBodyParams = @{
                            responses = $Responses.PSObject.Properties
                            namespace = $Namespace
                            definitionList = $DefinitionList
                        }

    $responseBody, $outputTypeBlock = Get-Response @responseBodyParams

    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    $bodyObject = @{ OutputTypeBlock = $outputTypeBlock;
                     Body = $body;
                    }

    return $bodyObject
}

function Test-OperationNameInDefinitionList
{
    param(
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    $definitionList = $SwaggerSpecDefinitionsAndParameters['definitions']
    if ($definitionList.ContainsKey($Name))
    {
        return $true
    }
    return $false
}

function Get-OutputType
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject] $schema,

        [Parameter(Mandatory=$true)]
        [String] $NameSpace, 

        [Parameter(Mandatory=$true)]
        [hashtable] $definitionList
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
                                        $exception = $LocalizedData.DataTypeNotImplemented -f ($defType, $ref)
                                        throw [System.NotImplementedException] "Please get an implementation of $defType for $ref"
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

                    $fullPathDataType = $fullPathDataType.Replace('[','').Replace(']','')
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