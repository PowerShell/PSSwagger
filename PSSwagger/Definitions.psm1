#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Definitions Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1) -DisableNameChecking
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath SwaggerUtils.psm1) -DisableNameChecking
. "$PSScriptRoot\PSSwagger.Constants.ps1" -Force
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

<#
.DESCRIPTION
  Gets Definition function details.
#>
function Get-SwaggerSpecDefinitionInfo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonDefinitionItemObject,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $Namespace,

        [Parameter(Mandatory=$true)]
        [string] 
        $Models
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Name = Get-CSharpModelName -Name $JsonDefinitionItemObject.Name
    $FunctionDescription = ""
    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'Description') -and 
       $JsonDefinitionItemObject.Value.Description)
    {
        $FunctionDescription = $JsonDefinitionItemObject.Value.Description
    }

    $AllOf_DefinitionNames = @()
    $ParametersTable = @{}
    $isModel = $false
    $AllOf_InlineObjects = @()
    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'AllOf') -and 
       $JsonDefinitionItemObject.Value.'AllOf')
    {
       $JsonDefinitionItemObject.Value.'AllOf' | ForEach-Object {
            if(Get-Member -InputObject $_ -Name '$ref')
            {
                $AllOfRefFullName = $_.'$ref'
                $AllOfRefName = Get-CSharpModelName -Name $AllOfRefFullName.Substring( $( $AllOfRefFullName.LastIndexOf('/') ) + 1 )
                $AllOf_DefinitionNames += $AllOfRefName
                            
                $ReferencedFunctionDetails = @{}
                if($DefinitionFunctionsDetails.ContainsKey($AllOfRefName))
                {
                    $ReferencedFunctionDetails = $DefinitionFunctionsDetails[$AllOfRefName]
                }

                $ReferencedFunctionDetails['Name'] = $AllOfRefName
                $ReferencedFunctionDetails['IsUsedAs_AllOf'] = $true

                $DefinitionFunctionsDetails[$AllOfRefName] = $ReferencedFunctionDetails
            } elseif ((Get-Member -InputObject $_ -Name 'type') -and $_.type -eq 'object') {
                # Create an anonymous type for objects defined inline
                $anonObjName = Get-CSharpModelName -Name ([Guid]::NewGuid().Guid)
                [PSCustomObject]$obj = New-Object -TypeName PsObject
                Add-Member -InputObject $obj -MemberType NoteProperty -Name 'Name' -Value $anonObjName
                Add-Member -InputObject $obj -MemberType NoteProperty -Name 'Value' -Value $_
                Get-SwaggerSpecDefinitionInfo -JsonDefinitionItemObject $obj -DefinitionFunctionsDetails $DefinitionFunctionsDetails -Namespace $Namespace -Models $Models
                $DefinitionFunctionsDetails[$anonObjName]['IsUsedAs_AllOf'] = $true
                $DefinitionFunctionsDetails[$anonObjName]['IsModel'] = $false
                $AllOf_InlineObjects += $DefinitionFunctionsDetails[$anonObjName]
                $isModel = $true
            }
            else {
                $Message = $LocalizedData.UnsupportedSwaggerProperties -f ('JsonDefinitionItemObject', $($_ | Out-String))
                Write-Warning -Message $Message
            }
       }
    }

    Get-DefinitionParameters -JsonDefinitionItemObject $JsonDefinitionItemObject `
                             -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                             -DefinitionName $Name `
                             -Namespace $Namespace `
                             -ParametersTable $ParametersTable `
                             -Models $Models

    # AutoRest doesn't generate a property for a discriminator property
    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'discriminator') -and 
       $JsonDefinitionItemObject.Value.'discriminator')
    {
        $discriminator = $JsonDefinitionItemObject.Value.'discriminator'
        if ($ParametersTable.ContainsKey($discriminator)) {
            $ParametersTable[$discriminator]['Discriminator'] = $true
        }
    }

    $FunctionDetails = @{}
    $x_ms_Client_flatten_DefinitionNames = @()
    if($DefinitionFunctionsDetails.ContainsKey($Name))
    {
        $FunctionDetails = $DefinitionFunctionsDetails[$Name]

        if($FunctionDetails.ContainsKey('x_ms_Client_flatten_DefinitionNames'))
        {
            $x_ms_Client_flatten_DefinitionNames = $FunctionDetails.x_ms_Client_flatten_DefinitionNames
        }
    }

    $Unexpanded_AllOf_DefinitionNames = $AllOf_DefinitionNames
    $Unexpanded_x_ms_client_flatten_DefinitionNames = $x_ms_Client_flatten_DefinitionNames
    $ExpandedParameters = (-not $Unexpanded_AllOf_DefinitionNames -and -not $Unexpanded_x_ms_client_flatten_DefinitionNames)

    $FunctionDetails['Name'] = $Name
    $FunctionDetails['Description'] = $FunctionDescription
    $FunctionDetails['ParametersTable'] = $ParametersTable
    $FunctionDetails['x_ms_Client_flatten_DefinitionNames'] = $x_ms_Client_flatten_DefinitionNames
    $FunctionDetails['AllOf_DefinitionNames'] = $AllOf_DefinitionNames
    $FunctionDetails['Unexpanded_x_ms_client_flatten_DefinitionNames'] = $Unexpanded_x_ms_client_flatten_DefinitionNames
    $FunctionDetails['Unexpanded_AllOf_DefinitionNames'] = $Unexpanded_AllOf_DefinitionNames
    $FunctionDetails['ExpandedParameters'] = $ExpandedParameters

    $DefinitionType = ""
    if ((Get-HashtableKeyCount -Hashtable $ParametersTable) -lt 1)
    {
        $GetDefinitionParameterType_params = @{
            ParameterJsonObject = $JsonDefinitionItemObject.value
            DefinitionName = $Name
            ModelsNamespace = "$NameSpace.$Models"
            DefinitionFunctionsDetails = $DefinitionFunctionsDetails
        }
        $DefinitionType = Get-DefinitionParameterType @GetDefinitionParameterType_params
    }
    $FunctionDetails['Type'] = $DefinitionType

    if(-not $FunctionDetails.ContainsKey('IsUsedAs_x_ms_client_flatten'))
    {
        $FunctionDetails['IsUsedAs_x_ms_client_flatten'] = $false
    }

    if(-not $FunctionDetails.ContainsKey('IsUsedAs_AllOf'))
    {
        $FunctionDetails['IsUsedAs_AllOf'] = $false
    }

    if((Get-Member -InputObject $JsonDefinitionItemObject -Name Value) -and
       (Get-Member -InputObject $JsonDefinitionItemObject.Value -Name properties) -and
       ((Get-HashtableKeyCount -Hashtable $JsonDefinitionItemObject.Value.Properties.PSObject.Properties) -ge 1))
    {
        $isModel = $true
    }

    $FunctionDetails['IsModel'] = $isModel
    $AllOf_InlineObjects | ForEach-Object {
        Copy-FunctionDetailsParameters -RefFunctionDetails $_ -FunctionDetails $FunctionDetails
    }
    
    $DefinitionFunctionsDetails[$Name] = $FunctionDetails
}

function Get-DefinitionParameters
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonDefinitionItemObject,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $DefinitionName,

        [Parameter(Mandatory=$true)]
        [string] 
        $Namespace,

        [Parameter(Mandatory=$true)]
        [string] 
        $Models,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $ParametersTable
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    if((Get-Member -InputObject $JsonDefinitionItemObject -Name Value) -and
       (Get-Member -InputObject $JsonDefinitionItemObject.Value -Name properties))
    {
        $JsonDefinitionItemObject.Value.properties.PSObject.Properties | ForEach-Object {

            if((Get-Member -InputObject $_ -Name 'Name') -and $_.Name)
            {                
                $ParameterJsonObject = $_.Value
                if ((Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-client-name') -and $ParameterJsonObject.'x-ms-client-name') {
                    $parameterName = Get-PascalCasedString -Name $ParameterJsonObject.'x-ms-client-name'
                } else {
                    $ParameterName = Get-PascalCasedString -Name $_.Name
                }

                if(($ParameterName -eq 'Properties') -and
                   (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-client-flatten') -and
                   ($ParameterJsonObject.'x-ms-client-flatten') -and
                   (Get-Member -InputObject $ParameterJsonObject -Name 'properties'))
                {
                    # Flatten the properties with x-ms-client-flatten
                    $null = Get-DefinitionParameters -JsonDefinitionItemObject $_ `
                                                     -DefinitionName $DefinitionName `
                                                     -Namespace $Namespace `
                                                     -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                                     -ParametersTable $ParametersTable `
                                                     -Models $Models
                }
                else
                {
                    $ParameterDetails = @{}
                    $IsParamMandatory = '$false'
                    $ValidateSetString = $null
                    $ParameterDescription = ''
                    
                    $ParameterType = Get-DefinitionParameterType -ParameterJsonObject $ParameterJsonObject `
                                                                 -DefinitionName $DefinitionName `
                                                                 -ParameterName $ParameterName `
                                                                 -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                                                 -ModelsNamespace "$NameSpace.Models" `
                                                                 -ParametersTable $ParametersTable
            
                    if ((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'Required') -and 
                        $JsonDefinitionItemObject.Value.Required -and
                        ($JsonDefinitionItemObject.Value.Required -contains $ParameterName) )
                    {
                        $IsParamMandatory = '$true'
                    }

                    if ((Get-Member -InputObject $ParameterJsonObject -Name 'Enum') -and $ParameterJsonObject.Enum)
                    {
                        if(-not ((Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-enum') -and 
                                 $ParameterJsonObject.'x-ms-enum' -and 
                                 (-not (Get-Member -InputObject $ParameterJsonObject.'x-ms-enum' -Name 'modelAsString') -or
                                 ($ParameterJsonObject.'x-ms-enum'.modelAsString -eq $false))))
                        {
                            $EnumValues = $ParameterJsonObject.Enum | ForEach-Object {$_ -replace "'","''"}
                            $ValidateSetString = "'$($EnumValues -join "', '")'"
                        }
                    }

                    if ((Get-Member -InputObject $ParameterJsonObject -Name 'Description') -and $ParameterJsonObject.Description)
                    {
                        $ParameterDescription = $ParameterJsonObject.Description
                    }

                    $ParameterDetails['Name'] = $ParameterName
                    $ParameterDetails['Type'] = $ParameterType
                    $ParameterDetails['ValidateSet'] = $ValidateSetString
                    $ParameterDetails['Mandatory'] = $IsParamMandatory
                    $ParameterDetails['Description'] = $ParameterDescription
                    $ParameterDetails['OriginalParameterName'] = $_.Name

                    if($ParameterType)
                    {
                        $ParametersTable[$ParameterName] = $ParameterDetails
                    }
                }
            }
        } #Properties
    }
}

function Get-DefinitionParameterType
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $ParameterJsonObject,

        [Parameter(Mandatory=$true)]
        [string]
        $DefinitionName,

        [Parameter(Mandatory=$false)]
        [string]
        $ParameterName,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $ModelsNamespace,

        [Parameter(Mandatory=$false)]
        [PSCustomObject] 
        $ParametersTable = @{}
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $DefinitionTypeNamePrefix = "$ModelsNamespace."

    $ParameterType = $null

    if ((Get-Member -InputObject $ParameterJsonObject -Name 'Type') -and $ParameterJsonObject.Type)
    {
        $ParameterType = $ParameterJsonObject.Type

        # When a definition property has single enum value, AutoRest doesn't generate an enum type.
        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Enum') -and 
            ($ParameterJsonObject.Enum.Count -gt 1) -and 
            (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-enum') -and 
            $ParameterJsonObject.'x-ms-enum' -and             
            (-not (Get-Member -InputObject $ParameterJsonObject.'x-ms-enum' -Name 'modelAsString') -or
             ($ParameterJsonObject.'x-ms-enum'.modelAsString -eq $false)))
        {
            $ParameterType = $DefinitionTypeNamePrefix + (Get-CSharpModelName -Name $ParameterJsonObject.'x-ms-enum'.Name)
        }
        # Use the format as parameter type if that is available as a type in PowerShell
        elseif ((Get-Member -InputObject $ParameterJsonObject -Name 'Format') -and 
                $ParameterJsonObject.Format -and 
                ($null -ne ($ParameterJsonObject.Format -as [Type])) ) 
        {
            $ParameterType = $ParameterJsonObject.Format
        }
        elseif (($ParameterJsonObject.Type -eq 'array') -and
                (Get-Member -InputObject $ParameterJsonObject -Name 'Items') -and 
                $ParameterJsonObject.Items)
        {
            if((Get-Member -InputObject $ParameterJsonObject.Items -Name '$ref') -and 
                $ParameterJsonObject.Items.'$ref')
            {
                $ReferenceTypeValue = $ParameterJsonObject.Items.'$ref'
                $ReferenceTypeName = Get-CSharpModelName -Name $ReferenceTypeValue.Substring( $( $ReferenceTypeValue.LastIndexOf('/') ) + 1 )
                $ParameterType = $DefinitionTypeNamePrefix + "$ReferenceTypeName[]"
            }
            elseif((Get-Member -InputObject $ParameterJsonObject.Items -Name 'Type') -and $ParameterJsonObject.Items.Type)
            {
                $ReferenceTypeName = Get-PSTypeFromSwaggerObject -JsonObject $ParameterJsonObject.Items
                $ParameterType = "$($ReferenceTypeName)[]"
            }
        }
        elseif ((Get-Member -InputObject $ParameterJsonObject -Name 'AdditionalProperties') -and 
                $ParameterJsonObject.AdditionalProperties)
        {
            if($ParameterJsonObject.Type -eq 'object') {                
                if((Get-Member -InputObject $ParameterJsonObject.AdditionalProperties -Name 'Type') -and
                $ParameterJsonObject.AdditionalProperties.Type) {
                    $AdditionalPropertiesType = Get-PSTypeFromSwaggerObject -JsonObject $ParameterJsonObject.AdditionalProperties
                    # Dictionary
                    $ParameterType = "System.Collections.Generic.Dictionary[[$AdditionalPropertiesType],[$AdditionalPropertiesType]]"
                }
                elseif((Get-Member -InputObject $ParameterJsonObject.AdditionalProperties -Name '$ref') -and
                    $ParameterJsonObject.AdditionalProperties.'$ref')
                {
                    $ReferenceTypeValue = $ParameterJsonObject.AdditionalProperties.'$ref'
                    $ReferenceTypeName = Get-CSharpModelName -Name $ReferenceTypeValue.Substring( $( $ReferenceTypeValue.LastIndexOf('/') ) + 1 )
                    $AdditionalPropertiesType = $DefinitionTypeNamePrefix + "$ReferenceTypeName"
                    # Dictionary
                    $ParameterType = "System.Collections.Generic.Dictionary[[string],[$AdditionalPropertiesType]]"
                }
                else {
                    $Message = $LocalizedData.UnsupportedSwaggerProperties -f ('ParameterJsonObject', $($ParameterJsonObject | Out-String))
                    Write-Warning -Message $Message
                }
            }
            else {
                $Message = $LocalizedData.UnsupportedSwaggerProperties -f ('ParameterJsonObject', $($ParameterJsonObject | Out-String))
                Write-Warning -Message $Message
            }
        }
    }
    elseif ($ParameterName -and ($ParameterName -eq 'Properties') -and
            (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-client-flatten') -and 
            ($ParameterJsonObject.'x-ms-client-flatten') )
    {                         
        # 'x-ms-client-flatten' extension allows to flatten deeply nested properties into the current definition.
        # Users often provide feedback that they don't want to create multiple levels of properties to be able to use an operation. 
        # By applying the x-ms-client-flatten extension, you move the inner properties to the top level of your definition.

        $ReferenceParameterValue = $ParameterJsonObject.'$ref'
        $ReferenceDefinitionName = Get-CSharpModelName -Name $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )

        $x_ms_Client_flatten_DefinitionNames = @($ReferenceDefinitionName)

        Set-TypeUsedAsClientFlatten -ReferenceTypeName $ReferenceDefinitionName -DefinitionFunctionsDetails $DefinitionFunctionsDetails

        # Add/Update FunctionDetails to $DefinitionFunctionsDetails
        $FunctionDetails = @{}
        if($DefinitionFunctionsDetails.ContainsKey($DefinitionName))
        {
            $FunctionDetails = $DefinitionFunctionsDetails[$DefinitionName]
            $FunctionDetails['x_ms_Client_flatten_DefinitionNames'] += $x_ms_Client_flatten_DefinitionNames
        }
        else
        {
            $FunctionDetails['Name'] = $DefinitionName
            $FunctionDetails['x_ms_Client_flatten_DefinitionNames'] = $x_ms_Client_flatten_DefinitionNames
        }

        $DefinitionFunctionsDetails[$DefinitionName] = $FunctionDetails
    }
    elseif ( (Get-Member -InputObject $ParameterJsonObject -Name '$ref') -and ($ParameterJsonObject.'$ref') )
    {
        $ReferenceParameterValue = $ParameterJsonObject.'$ref'        
        $ReferenceTypeName = Get-CSharpModelName -Name $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
        $ParameterType = $DefinitionTypeNamePrefix + $ReferenceTypeName
    }
    else
    {
        $ParameterType = 'object'
    }

    $ParameterType = Get-PSTypeFromSwaggerObject -ParameterType $ParameterType

    if($ParameterType -and 
       (-not $ParameterType.Contains($DefinitionTypeNamePrefix)) -and
       ($null -eq ($ParameterType -as [Type])))
    {
        Write-Warning -Message ($LocalizedData.InvalidDefinitionParameterType -f $ParameterType, $ParameterName, $DefinitionName)
    }

    return $ParameterType
}

function New-SwaggerDefinitionCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [string]
        $NameSpace,

        [Parameter(Mandatory = $true)]
        [string]
        $Models
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $FunctionsToExport = @()
    $GeneratedCommandsPath = Join-Path -Path $SwaggerMetaDict['outputDirectory'] -ChildPath $GeneratedCommandsName
    $SwaggerDefinitionCommandsPath = Join-Path -Path $GeneratedCommandsPath -ChildPath 'SwaggerDefinitionCommands'
    $FormatFilesPath = Join-Path -Path $GeneratedCommandsPath -ChildPath 'FormatFiles'

    # Expand the definition parameters from 'AllOf' definitions and x_ms_client-flatten declarations.
    $ExpandedAllDefinitions = $false

    while(-not $ExpandedAllDefinitions)
    {
        $ExpandedAllDefinitions = $true

        $DefinitionFunctionsDetails.GetEnumerator() | ForEach-Object {
            
            $FunctionDetails = $_.Value

            if(-not $FunctionDetails.ExpandedParameters)
            {
                $message = $LocalizedData.ExpandDefinition -f ($FunctionDetails.Name)
                Write-Verbose -Message $message

                $Unexpanded_AllOf_DefinitionNames = @()
                $Unexpanded_AllOf_DefinitionNames += $FunctionDetails.Unexpanded_AllOf_DefinitionNames | ForEach-Object {
                                                        $ReferencedDefinitionName = $_
                                                        if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                           $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                        {
                                                            $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                            $RefFunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
                                                                $RefParameterName = $_.Name
                                                                if($RefParameterName)
                                                                {
                                                                    if($FunctionDetails.ParametersTable.ContainsKey($RefParameterName))
                                                                    {
                                                                        Write-Verbose -Message ($LocalizedData.SamePropertyName -f ($RefParameterName, $FunctionDetails.Name))
                                                                    }
                                                                    else
                                                                    {
                                                                        $FunctionDetails.ParametersTable[$RefParameterName] = $RefFunctionDetails.ParametersTable[$RefParameterName]
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        else
                                                        {
                                                            $_
                                                        }
                                                    }
                $Unexpanded_x_ms_client_flatten_DefinitionNames = @()
                $Unexpanded_x_ms_client_flatten_DefinitionNames += $FunctionDetails.Unexpanded_x_ms_client_flatten_DefinitionNames | ForEach-Object {
                                                                        $ReferencedDefinitionName = $_
                                                                        if($ReferencedDefinitionName)
                                                                        {
                                                                            if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                                               $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                                            {
                                                                                $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                                                Copy-FunctionDetailsParameters -RefFunctionDetails $RefFunctionDetails -FunctionDetails $FunctionDetails
                                                                            }
                                                                            else
                                                                            {
                                                                                $_
                                                                            }
                                                                        }
                                                                    }


                $FunctionDetails.ExpandedParameters = (-not $Unexpanded_AllOf_DefinitionNames -and -not $Unexpanded_x_ms_client_flatten_DefinitionNames)
                $FunctionDetails.Unexpanded_AllOf_DefinitionNames = $Unexpanded_AllOf_DefinitionNames
                $FunctionDetails.Unexpanded_x_ms_client_flatten_DefinitionNames = $Unexpanded_x_ms_client_flatten_DefinitionNames

                if(-not $FunctionDetails.ExpandedParameters)
                {
                    $message = $LocalizedData.UnableToExpandDefinition -f ($FunctionDetails.Name)
                    Write-Verbose -Message $message
                    $ExpandedAllDefinitions = $false
                }
            } # ExpandedParameters
        } # Foeach-Object
    } # while()

    Expand-NonModelDefinition -DefinitionFunctionsDetails $DefinitionFunctionsDetails -NameSpace $NameSpace -Models $Models

    $DefinitionFunctionsDetails.GetEnumerator() | ForEach-Object {
        $FunctionDetails = $_.Value
        if ($FunctionDetails.ContainsKey('UsedAsPathOperationInputType') -and $FunctionDetails.UsedAsPathOperationInputType) {
            Set-GenerateDefinitionCmdlet -DefinitionFunctionsDetails $DefinitionFunctionsDetails -FunctionDetails $FunctionDetails -ModelsNamespaceWithDot "$Namespace.$Models."
        }
    }

    $DefinitionFunctionsDetails.GetEnumerator() | ForEach-Object {        
        $FunctionDetails = $_.Value
        # Denifitions defined as x_ms_client_flatten are not used as an object anywhere. 
        # Also AutoRest doesn't generate a Model class for the definitions declared as x_ms_client_flatten for other definitions.
        if((-not $FunctionDetails.IsUsedAs_x_ms_client_flatten) -and $FunctionDetails.IsModel)
        {
            if ($FunctionDetails.ContainsKey('GenerateDefinitionCmdlet') -and ($FunctionDetails['GenerateDefinitionCmdlet'] -eq $true)) {
                $FunctionsToExport += New-SwaggerSpecDefinitionCommand -FunctionDetails $FunctionDetails `
                                                                    -GeneratedCommandsPath $SwaggerDefinitionCommandsPath `
                                                                    -ModelsNamespace "$Namespace.$Models"
            }

            New-SwaggerDefinitionFormatFile -FunctionDetails $FunctionDetails `
                                            -FormatFilesPath $FormatFilesPath `
                                            -Namespace $NameSpace `
                                            -Models $Models
        }
    }

    return $FunctionsToExport
}

function Set-GenerateDefinitionCmdlet
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $FunctionDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $ModelsNamespaceWithDot
    )

    if($FunctionDetails.ContainsKey('GenerateDefinitionCmdlet') -or -not $FunctionDetails.IsModel)
    {
        return
    }
    $FunctionDetails['GenerateDefinitionCmdlet'] = $true
    
    if($FunctionDetails.ContainsKey('ParametersTable') -and (Get-HashtableKeyCount -Hashtable $FunctionDetails.ParametersTable)) {
        $FunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
            Set-GenerateDefinitionCmdletUtility -ParameterType $_.Value.Type -DefinitionFunctionsDetails $DefinitionFunctionsDetails -ModelsNamespaceWithDot $ModelsNamespaceWithDot
        }
    } elseif ($FunctionDetails.ContainsKey('Type') -and $FunctionDetails.Type) {
        Set-GenerateDefinitionCmdletUtility -ParameterType $FunctionDetails.Type -DefinitionFunctionsDetails $DefinitionFunctionsDetails -ModelsNamespaceWithDot $ModelsNamespaceWithDot
    }
}

function Set-GenerateDefinitionCmdletUtility
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterType,

        [Parameter(Mandatory = $true)]
        [string]
        $ModelsNamespaceWithDot
    )

    $RefDefName = $null
    if ($ParameterType.StartsWith($ModelsNamespaceWithDot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $RefDefName = $ParameterType.Replace($ModelsNamespaceWithDot, '').Replace('[]','')
    } elseif ($ParameterType.StartsWith("System.Collections.Generic.Dictionary[[string],[$ModelsNamespaceWithDot", [System.StringComparison]::OrdinalIgnoreCase)) {
        $RefDefName = $ParameterType.Replace("System.Collections.Generic.Dictionary[[string],[$ModelsNamespaceWithDot", '').Replace(']]','')
    }

    if($RefDefName -and $DefinitionFunctionsDetails.ContainsKey($RefDefName)) {
        $RefDefFunctionDetails = $DefinitionFunctionsDetails[$RefDefName]
        if($RefDefFunctionDetails) {
            Set-GenerateDefinitionCmdlet -FunctionDetails $RefDefFunctionDetails -DefinitionFunctionsDetails $DefinitionFunctionsDetails -ModelsNamespaceWithDot $ModelsNamespaceWithDot
        }
    }
}

function Copy-FunctionDetailsParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $RefFunctionDetails,

        [Parameter(Mandatory = $true)]
        $FunctionDetails
    )

    $RefFunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
                                                                $RefParameterName = $_.Name
                                                                if($RefParameterName)
                                                                {
                                                                    if($FunctionDetails.ParametersTable.ContainsKey($RefParameterName))
                                                                    {
                                                                        Write-Verbose -Message ($LocalizedData.SamePropertyName -f ($RefParameterName, $FunctionDetails.Name))
                                                                    }
                                                                    else
                                                                    {
                                                                        $FunctionDetails.ParametersTable[$RefParameterName] = $RefFunctionDetails.ParametersTable[$RefParameterName]
                                                                    }
                                                                }
                                                            }
}
function Expand-NonModelDefinition
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $NameSpace,

        [Parameter(Mandatory = $true)]
        [string]
        $Models
    )

    $DefinitionFunctionsDetails.GetEnumerator() | ForEach-Object {
        $DefFunctionDetails = $_.Value 

        if(-not $DefFunctionDetails.IsModel) {
            # Replace parameter details from referenced definition details.
            $DefinitionFunctionsDetails.GetEnumerator() | ForEach-Object {
                $FunctionDetails = $_.Value
                $ParamsToBeReplaced = @{}
                if($DefFunctionDetails.ContainsKey('ParametersTable') -and 
                    ((Get-HashtableKeyCount -Hashtable $DefFunctionDetails.ParametersTable) -eq 1)) {
                    $DefFunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object { $SourceDetails = $_.Value }
                } else {
                    $SourceDetails = $DefFunctionDetails
                }

                if(Get-HashtableKeyCount -Hashtable $FunctionDetails.ParametersTable)
                {
                    $FunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
                        $ParameterDetails = $_.Value
                        if ($ParameterDetails.Type -eq "$Namespace.$Models.$($DefFunctionDetails.Name)") {
                            if($SourceDetails.ContainsKey('Type')) {
                                $ParameterDetails['Type'] = $SourceDetails.Type
                            }

                            if($SourceDetails.ContainsKey('ValidateSet')) {
                                $ParameterDetails['ValidateSet'] = $SourceDetails.ValidateSet
                            }

                            if((-not $ParameterDetails.Description) -and 
                               $SourceDetails.ContainsKey('Description') -and $SourceDetails.Description)
                            {
                                $ParameterDetails['Description'] = $SourceDetails.Description
                            }

                            $ParamsToBeReplaced[$ParameterDetails.Name] = $ParameterDetails 
                        }
                    }

                    $ParamsToBeReplaced.GetEnumerator() | ForEach-Object {
                        $FunctionDetails.ParametersTable[$_.Key] = $_.Value
                    }
                }
                elseif (($FunctionDetails.Type -eq "$Namespace.$Models.$($DefFunctionDetails.Name)") -and 
                        $SourceDetails.ContainsKey('Type'))
                {
                    $FunctionDetails.Type = $SourceDetails.Type
                }
            }
        }
    }
}

<#
.DESCRIPTION
  Generates a cmdlet for the definition
#>
function New-SwaggerSpecDefinitionCommand
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $FunctionDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $GeneratedCommandsPath,

        [Parameter(Mandatory=$true)]
        [string] 
        $ModelsNamespace
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $commandName = "New-$($FunctionDetails.Name)Object"

    $description = $FunctionDetails.description
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    [string]$paramHelp = ""
    $paramblock = ""
    $body = ""
    $DefinitionTypeNamePrefix = "$ModelsNamespace."
    $ParameterSetPropertyString = ""
    $parameterDefaultValueOption = ""

    $FunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {
        $ParameterDetails = $_.Value
        if (-not ($ParameterDetails.ContainsKey('Discriminator')) -or (-not $ParameterDetails.Discriminator)) {
            $isParamMandatory = $ParameterDetails.Mandatory
            $parameterName = $ParameterDetails.Name
            $paramName = "`$$parameterName" 
            $paramType = "[$($ParameterDetails.Type)]$([Environment]::NewLine)        "
            $AllParameterSetsString = $executionContext.InvokeCommand.ExpandString($parameterAttributeString)
            $ValidateSetDefinition = $null
            if ($ParameterDetails.ValidateSet)
            {
                $ValidateSetString = $ParameterDetails.ValidateSet
                $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
            }
            $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)

            $pDescription = $ParameterDetails.Description
            $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
        }
    }

    $paramblock = $paramBlock.TrimEnd().TrimEnd(",")

    $DefinitionTypeName = $DefinitionTypeNamePrefix + $FunctionDetails.Name
    $body = $executionContext.InvokeCommand.ExpandString($createObjectStr)

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignatureForDefintion)

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    Write-Verbose -Message ($LocalizedData.GeneratedDefinitionCommand -f ($commandName, $FunctionDetails.Name))

    return $CommandName
}

<#
.DESCRIPTION
  Creates a format file for the given definition details
#>
function New-SwaggerDefinitionFormatFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $FunctionDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $FormatFilesPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Namespace,

        [Parameter(Mandatory=$true)]
        [string]
        $Models
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $ViewName = "$Namespace.$Models.$($FunctionDetails.Name)"
    $ViewTypeName = $ViewName
    $TableColumnItemsList = @()
    $TableColumnItemCount = 0
    $ParametersCount = Get-HashtableKeyCount -Hashtable $FunctionDetails.ParametersTable
    $SkipParameterList = @('id', 'tags')

    $FunctionDetails.ParametersTable.GetEnumerator() | ForEach-Object {        
        
        $ParameterDetails = $_.Value

        # Add all properties when definition has 4 or less properties.
        # Otherwise add the first 4 properties with basic types by skipping the complex types, id and tags.
        if(($ParametersCount -le 4) -or
           (($TableColumnItemCount -le 4) -and
            ($SkipParameterList -notcontains $ParameterDetails.Name) -and
            (-not $ParameterDetails.Type.StartsWith($Namespace, [System.StringComparison]::OrdinalIgnoreCase))))
        {
            $TableColumnItemsList += $TableColumnItemStr -f ($ParameterDetails.Name)
            $TableColumnItemCount += 1
        }
    }

    $TableColumnHeaders = $null
    $TableColumnItems = $TableColumnItemsList -join "`r`n"
    $FormatViewDefinition = $FormatViewDefinitionStr -f ($ViewName, $ViewTypeName, $TableColumnHeaders, $TableColumnItems)

    if(-not (Test-Path -Path $FormatFilesPath -PathType Container))
    {
        $null = New-Item -Path $FormatFilesPath -ItemType Directory
    }
    $FormatFilePath = Join-Path -Path $FormatFilesPath -ChildPath "$($FunctionDetails.Name).ps1xml"
    Out-File -InputObject $FormatViewDefinition -FilePath $FormatFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false
    Write-Verbose -Message ($LocalizedData.GeneratedFormatFile -f $FunctionDetails.Name)
}