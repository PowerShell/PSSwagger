#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Definitions Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath Utilities.psm1)
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath SwaggerUtils.psm1)
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
        $Namespace 
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Name = $JsonDefinitionItemObject.Name.Replace('[','').Replace(']','')
    
    $FunctionDescription = ""
    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'Description') -and 
       $JsonDefinitionItemObject.Value.Description)
    {
        $FunctionDescription = $JsonDefinitionItemObject.Value.Description
    }

    $DefinitionTypeNamePrefix = "$Namespace.Models."

    $AllOf_DefinitionNames = @()
    $ParametersTable = @{}

    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'AllOf') -and 
       $JsonDefinitionItemObject.Value.'AllOf')
    {
       $JsonDefinitionItemObject.Value.'AllOf' | ForEach-Object {
           $AllOfRefFullName = $_.'$ref'
           $AllOfRefName = $AllOfRefFullName.Substring( $( $AllOfRefFullName.LastIndexOf('/') ) + 1 )
           $AllOf_DefinitionNames += $AllOfRefName
                      
           $ReferencedFunctionDetails = @{}
           if($DefinitionFunctionsDetails.ContainsKey($AllOfRefName))
           {
               $ReferencedFunctionDetails = $DefinitionFunctionsDetails[$AllOfRefName]
           }

           $ReferencedFunctionDetails['Name'] = $AllOfRefName
           $ReferencedFunctionDetails['IsUsedAs_AllOf'] = $true

           $DefinitionFunctionsDetails[$AllOfRefName] = $ReferencedFunctionDetails
       }
    }

    Get-DefinitionParameters -JsonDefinitionItemObject $JsonDefinitionItemObject `
                             -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                             -DefinitionName $Name `
                             -Namespace $Namespace `
                             -ParametersTable $ParametersTable

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

    if(-not $FunctionDetails.ContainsKey('IsUsedAs_x_ms_client_flatten'))
    {
        $FunctionDetails['IsUsedAs_x_ms_client_flatten'] = $false
    }

    if(-not $FunctionDetails.ContainsKey('IsUsedAs_AllOf'))
    {
        $FunctionDetails['IsUsedAs_AllOf'] = $false
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
                $ParameterName = Get-PascalCasedString -Name $_.Name

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
                                                     -ParametersTable $ParametersTable
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
                                                                 -Namespace $NameSpace `
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
                                 ($ParameterJsonObject.'x-ms-enum'.modelAsString -eq $false)))
                        {
                            $ValidateSetString = "'$($ParameterJsonObject.Enum -join "', '")'"
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

        [Parameter(Mandatory=$true)]
        [string]
        $ParameterName,

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory=$true)]
        [string] 
        $Namespace,

        [Parameter(Mandatory=$false)]
        [PSCustomObject] 
        $ParametersTable = @{}
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $ParameterType = $null

    if ((Get-Member -InputObject $ParameterJsonObject -Name 'Type') -and $ParameterJsonObject.Type)
    {
        $ParameterType = $ParameterJsonObject.Type

        if ((Get-Member -InputObject $ParameterJsonObject -Name 'Enum') -and 
            (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-enum') -and 
            $ParameterJsonObject.'x-ms-enum' -and 
            ($ParameterJsonObject.'x-ms-enum'.modelAsString -eq $false))
        {
            $ParameterType = $DefinitionTypeNamePrefix + $ParameterJsonObject.'x-ms-enum'.Name
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
                $ReferenceTypeName = $ReferenceTypeValue.Substring( $( $ReferenceTypeValue.LastIndexOf('/') ) + 1 )
                $ParameterType = $DefinitionTypeNamePrefix + "$ReferenceTypeName[]"
            }
            elseif((Get-Member -InputObject $ParameterJsonObject.Items -Name 'Type') -and $ParameterJsonObject.Items.Type)
            {
                $ParameterType = "$($ParameterJsonObject.Items.Type)[]"
            }
        }
        elseif (($ParameterJsonObject.Type -eq 'object') -and
                (Get-Member -InputObject $ParameterJsonObject -Name 'AdditionalProperties') -and 
                $ParameterJsonObject.AdditionalProperties)
        {
            $AdditionalPropertiesType = $ParameterJsonObject.AdditionalProperties.Type
            $ParameterType = "System.Collections.Generic.Dictionary[[$AdditionalPropertiesType],[$AdditionalPropertiesType]]"
        }
    }
    elseif ($ParameterName -eq 'Properties' -and
            (Get-Member -InputObject $ParameterJsonObject -Name 'x-ms-client-flatten') -and 
            ($ParameterJsonObject.'x-ms-client-flatten') )
    {                         
        # 'x-ms-client-flatten' extension allows to flatten deeply nested properties into the current definition.
        # Users often provide feedback that they don't want to create multiple levels of properties to be able to use an operation. 
        # By applying the x-ms-client-flatten extension, you move the inner properties to the top level of your definition.

        $ReferenceParameterValue = $ParameterJsonObject.'$ref'
        $ReferenceDefinitionName = $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )

        $x_ms_Client_flatten_DefinitionNames = @($ReferenceDefinitionName)

        $ReferencedFunctionDetails = @{}
        if($DefinitionFunctionsDetails.ContainsKey($ReferenceDefinitionName))
        {
            $ReferencedFunctionDetails = $DefinitionFunctionsDetails[$ReferenceDefinitionName]
        }

        $ReferencedFunctionDetails['Name'] = $ReferenceDefinitionName
        $ReferencedFunctionDetails['IsUsedAs_x_ms_client_flatten'] = $true

        $DefinitionFunctionsDetails[$ReferenceDefinitionName] = $ReferencedFunctionDetails

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
        $ParameterType = $DefinitionTypeNamePrefix + $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
    }
    else
    {
        $ParameterType = 'object'
    }

    if($ParameterType -and ($ParameterType -eq 'Boolean'))
    {
        $ParameterType = 'switch'
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
        [String]
        $NameSpace
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

        $DefinitionFunctionsDetails.Keys | ForEach-Object {
            
            $FunctionDetails = $DefinitionFunctionsDetails[$_]

            if(-not $FunctionDetails.ExpandedParameters)
            {
                $message = $LocalizedData.ExpandDefinition -f ($FunctionDetails.Name)
                Write-Verbose -Message $message

                $Unexpanded_AllOf_DefinitionNames = $FunctionDetails.Unexpanded_AllOf_DefinitionNames | ForEach-Object {
                                                        $ReferencedDefinitionName = $_
                                                        if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                           $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                        {
                                                            $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                
                                                            $RefFunctionDetails.ParametersTable.Keys | ForEach-Object {
                                                                $RefParameterName = $_
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

                $Unexpanded_x_ms_client_flatten_DefinitionNames = $FunctionDetails.Unexpanded_x_ms_client_flatten_DefinitionNames | ForEach-Object {
                                                                        $ReferencedDefinitionName = $_
                                                                        if($ReferencedDefinitionName)
                                                                        {
                                                                            if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                                               $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                                            {
                                                                                $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                
                                                                                $RefFunctionDetails.ParametersTable.Keys | ForEach-Object {
                                                                                    $RefParameterName = $_
                                                                                    if($RefParameterName)
                                                                                    {
                                                                                        if($FunctionDetails.ParametersTable.ContainsKey($RefParameterName))
                                                                                        {
                                                                                            $ParameterName = $FunctionDetails.Name + $RefParameterName

                                                                                            $FunctionDetails.ParametersTable[$ParameterName] = $RefFunctionDetails.ParametersTable[$RefParameterName]
                                                                                            $FunctionDetails.ParametersTable[$ParameterName].Name = $ParameterName
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
                                                                    }


                $FunctionDetails.ExpandedParameters = (-not $Unexpanded_AllOf_DefinitionNames -and -not $Unexpanded_x_ms_client_flatten_DefinitionNames)
                $FunctionDetails.Unexpanded_AllOf_DefinitionNames = $Unexpanded_AllOf_DefinitionNames
                $FunctionDetails.Unexpanded_x_ms_client_flatten_DefinitionNames = $Unexpanded_x_ms_client_flatten_DefinitionNames

                if(-not $FunctionDetails.ExpandedParameters)
                {
                    $message = $LocalizedData.UnableToExpandDefinition -f ($($FunctionDetails.Name))
                    Write-Verbose -Message $message
                    $ExpandedAllDefinitions = $false
                }
            } # ExpandedParameters
        } # Foeach-Object
    } # while()

    $DefinitionFunctionsDetails.Keys | ForEach-Object {
        
        $FunctionDetails = $DefinitionFunctionsDetails[$_]

        # Denifitions defined as x_ms_client_flatten are not used as an object anywhere. 
        # Also AutoRest doesn't generate a Model class for the definitions declared as x_ms_client_flatten for other definitions.
        if(-not $FunctionDetails.IsUsedAs_x_ms_client_flatten -and $FunctionDetails.ParametersTable.Count)
        {
            $FunctionsToExport += New-SwaggerSpecDefinitionCommand -FunctionDetails $FunctionDetails `
                                                                   -GeneratedCommandsPath $SwaggerDefinitionCommandsPath `
                                                                   -Namespace $Namespace

            New-SwaggerDefinitionFormatFile -FunctionDetails $FunctionDetails `
                                            -FormatFilesPath $FormatFilesPath `
                                            -Namespace $NameSpace
        }
    }

    return $FunctionsToExport
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
        $Namespace 
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $commandName = "New-$($FunctionDetails.Name)Object"

    $description = $FunctionDetails.description
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    [string]$paramHelp = ""
    $paramblock = ""
    $body = ""
    $DefinitionTypeNamePrefix = "$Namespace.Models."
    $ParameterSetPropertyString = ""
    
    $FunctionDetails.ParametersTable.Keys | ForEach-Object {
        $ParameterDetails = $FunctionDetails.ParametersTable[$_]

        $isParamMandatory = $ParameterDetails.Mandatory
        $parameterName = $ParameterDetails.Name
        $paramName = "`$$parameterName" 
        $paramType = $ParameterDetails.Type
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

    $paramblock = $paramBlock.TrimEnd().TrimEnd(",")

    $DefinitionTypeName = $DefinitionTypeNamePrefix + $FunctionDetails.Name
    $body = $executionContext.InvokeCommand.ExpandString($createObjectStr)

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignatureForDefintion)
    Write-Verbose -Message $CommandString

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

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
        $Namespace
    )
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $ViewName = "$Namespace.Models.$($FunctionDetails.Name)"
    $ViewTypeName = $ViewName
    $TableColumnItemsList = @()
    $TableColumnItemCount = 0
    $ParametersCount = $FunctionDetails.ParametersTable.Keys.Count
    $SkipParameterList = @('id', 'tags')

    $FunctionDetails.ParametersTable.Keys | ForEach-Object {
        $ParameterDetails = $FunctionDetails.ParametersTable[$_]

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
    Write-Verbose -Message $FormatViewDefinition

    if(-not (Test-Path -Path $FormatFilesPath -PathType Container))
    {
        $null = New-Item -Path $FormatFilesPath -ItemType Directory
    }
    $FormatFilePath = Join-Path -Path $FormatFilesPath -ChildPath "$($FunctionDetails.Name).ps1xml"
    Out-File -InputObject $FormatViewDefinition -FilePath $FormatFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false
}