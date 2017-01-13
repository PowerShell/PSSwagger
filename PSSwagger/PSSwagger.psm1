
#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# PSSwagger Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
  Decodes the swagger spec and generates PowerShell cmdlets.

.PARAMETER  SwaggerSpecPath
  Full Path to a Swagger based JSON spec.

.PARAMETER  Path
  Full Path to a file where the commands are exported to.
#>
function Export-CommandFromSwagger
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerPath')]
        [String] 
        $SwaggerSpecPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerURI')]
        [Uri]
        $SwaggerSpecUri,

        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleName,

        [Parameter()]
        [switch]
        $UseAzureCsharpGenerator
    )

    if ($PSCmdlet.ParameterSetName -eq 'SwaggerURI')
    {
        # Ensure that if the URI is coming from github, it is getting the raw content
        if($SwaggerSpecUri.Host -eq 'github.com'){
            $SwaggerSpecUri = "https://raw.githubusercontent.com$($SwaggerSpecUri.AbsolutePath)"
            Write-Verbose "Converting SwaggerSpecUri to raw github content $SwaggerSpecUri" -Verbose
        }

        $SwaggerSpecPath = [io.path]::GetTempFileName() + ".json"
        Write-Verbose "Swagger spec from $SwaggerSpecURI is downloaded to $SwaggerSpecPath"
        
        $ev = $null
        Invoke-WebRequest -Uri $SwaggerSpecUri -OutFile $SwaggerSpecPath -ErrorVariable ev
        if($ev) {
            return 
        }
    }

    if (-not (Test-path $SwaggerSpecPath))
    {
        throw "Swagger file $SwaggerSpecPath does not exist. Check the path"
    }

    $jsonObject = ConvertFrom-Json ((Get-Content $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop

    # Populate the metadata, definitions and parameters from the provided Swagger specification
    $SwaggerSpecDefinitionsAndParameters = Get-SwaggerSpecDefinitionAndParameter -SwaggerSpecJsonObject $jsonObject -ModuleName $ModuleName
    
    $outputDirectory = $Path.TrimEnd('\').TrimEnd('/')

    if($PSVersionTable.PSVersion -lt '5.0.0') {
        if (-not $outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleName
        }
    } else {
        $ModuleVersion = $SwaggerSpecDefinitionsAndParameters['Version']
        $ModuleNameandVersionFolder = Join-Path -Path $ModuleName -ChildPath $ModuleVersion

        if ($outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleVersion
        } elseif (-not $outputDirectory.EndsWith($ModuleNameandVersionFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleNameandVersionFolder
        }
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop

    $Namespace = $SwaggerSpecDefinitionsAndParameters['Namespace']
    ConvertTo-CsharpCode -SwaggerSpecPath $SwaggerSpecPath `
                         -Path $outputDirectory `
                         -ModuleName $ModuleName `
                         -NameSpace $Namespace `
                         -UseAzureCsharpGenerator:$UseAzureCsharpGenerator

    $FunctionsToExport = @()
    $GeneratedCommandsName = 'Generated.PowerShell.Commands'
    $SwaggerPathCommandsPath = Join-Path -Path (Join-Path -Path $outputDirectory -ChildPath $GeneratedCommandsName) -ChildPath 'SwaggerPathCommands'

    # Handle the Paths
    $jsonObject.Paths.PSObject.Properties | ForEach-Object {
        $jsonPathObject = $_.Value
        $jsonPathObject.psobject.Properties | ForEach-Object {
               $FunctionsToExport += New-SwaggerSpecPathCommand -JsonPathItemObject $_.Value `
                                                                -GeneratedCommandsPath $SwaggerPathCommandsPath `
                                                                -UseAzureCsharpGenerator:$UseAzureCsharpGenerator `
                                                                -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters
            } # jsonPathObject
    } # jsonObject

    $SwaggerDefinitionCommandsPath = Join-Path -Path (Join-Path -Path $outputDirectory -ChildPath $GeneratedCommandsName) -ChildPath 'SwaggerDefinitionCommands'

    # Handle the Definitions
    $DefinitionFunctionsDetails = @{}
    $jsonObject.Definitions.PSObject.Properties | ForEach-Object {
        Get-SwaggerSpecDefinitionInfo -JsonDefinitionItemObject $_ -Namespace $Namespace -DefinitionFunctionsDetails $DefinitionFunctionsDetails
    }

    # Expand the definition parameters from 'AllOf' definitions and x_ms_client-flatten declarations.
    $ExpandedAllDefinitions = $false

    while(-not $ExpandedAllDefinitions)
    {
        $ExpandedAllDefinitions = $true

        $DefinitionFunctionsDetails.Keys | ForEach-Object {
            
            $FunctionDetails = $DefinitionFunctionsDetails[$_]

            if(-not $FunctionDetails.ExpandedParameters)
            {
                Write-Verbose -Message "Trying to expand the $($FunctionDetails.Name) defnition."

                $Unexpanded_AllOf_DefinitionNames = $FunctionDetails.Unexpanded_AllOf_DefinitionNames | ForEach-Object {
                                                        $ReferencedDefinitionName = $_
                                                        if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                           $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                        {
                                                            $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                
                                                            $RefFunctionDetails.ParametersTable.Keys | ForEach-Object {
                                                                $RefParameterName = $_
                                                                if($FunctionDetails.ParametersTable.ContainsKey($RefParameterName))
                                                                {
                                                                    Throw "Same property name should not be defined in a definition with AllOf inheritance."
                                                                }
                                                                else
                                                                {
                                                                    $FunctionDetails.ParametersTable[$RefParameterName] = $RefFunctionDetails.ParametersTable[$RefParameterName]
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
                                                                        if($DefinitionFunctionsDetails.ContainsKey($ReferencedDefinitionName) -and
                                                                           $DefinitionFunctionsDetails[$ReferencedDefinitionName].ExpandedParameters)
                                                                        {
                                                                            $RefFunctionDetails = $DefinitionFunctionsDetails[$ReferencedDefinitionName]
                                                
                                                                            $RefFunctionDetails.ParametersTable.Keys | ForEach-Object {
                                                                                $RefParameterName = $_
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
                                                                        else
                                                                        {
                                                                            $_
                                                                        }
                                                                    }


                $FunctionDetails.ExpandedParameters = (-not $Unexpanded_AllOf_DefinitionNames -and -not $Unexpanded_x_ms_client_flatten_DefinitionNames)
                $FunctionDetails.Unexpanded_AllOf_DefinitionNames = $Unexpanded_AllOf_DefinitionNames
                $FunctionDetails.Unexpanded_x_ms_client_flatten_DefinitionNames = $Unexpanded_x_ms_client_flatten_DefinitionNames

                if(-not $FunctionDetails.ExpandedParameters)
                {
                    Write-Verbose -Message "Unable to expand the $($FunctionDetails.Name) definition in current iteration."
                    $ExpandedAllDefinitions = $false
                }
            } # ExpandedParameters
        } # Foeach-Object
    } # while()

    $DefinitionFunctionsDetails.Keys | ForEach-Object {
        
        $FunctionDetails = $DefinitionFunctionsDetails[$_]

        # Denifitions defined as x_ms_client_flatten are not used as an object anywhere. 
        # Also AutoRest doesn't generate a Model class for the definitions declared as x_ms_client_flatten for other definitions.
        if(-not $FunctionDetails.IsUsedAs_x_ms_client_flatten) {
            $FunctionsToExport += New-SwaggerSpecDefinitionCommand -FunctionDetails $FunctionDetails `
                                                                   -GeneratedCommandsPath $SwaggerDefinitionCommandsPath `
                                                                   -Namespace $Namespace
        }
    }

    $RootModuleContents = @'
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName" -Recurse -Filter *.ps1 -File | ForEach-Object { . `$_.FullName}
'@
    $RootModuleFilePath = Join-Path $outputDirectory "$ModuleName.psm1"
    Out-File -FilePath $RootModuleFilePath `
             -InputObject $ExecutionContext.InvokeCommand.ExpandString($RootModuleContents)`
             -Encoding ascii `
             -Force

    New-ModuleManifestUtility -Path $outputDirectory `
                              -FunctionsToExport $FunctionsToExport `
                              -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters
}

#region Cmdlet Generation Helpers

<#
.DESCRIPTION
  Generates a cmdlet given a JSON custom object (from paths)
#>
function New-SwaggerSpecPathCommand
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject,

        [Parameter(Mandatory=$true)]
        [string] 
        $GeneratedCommandsPath,

        [Parameter(Mandatory=$false)]
        [switch]
        $UseAzureCsharpGenerator,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $SwaggerSpecDefinitionsAndParameters 
    )

    $helpDescStr = @'
.DESCRIPTION
    $description
'@

    $advFnSignature = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
   [CmdletBinding()]
   param($paramblock
   )

   $body
}
'@

    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)]
    [$paramType]
    $paramName,

'@

    $helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

    $functionBodyStr = @'

    `$serviceCredentials =  Get-AzServiceCredential
    `$subscriptionId = Get-AzSubscriptionId
    `$delegatingHandler = Get-AzDelegatingHandler

    $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler
    $apiVersion
    $clientName.SubscriptionId = `$subscriptionId
    
    Write-Verbose 'Performing operation $methodName on $clientName.'
    `$taskResult = $clientName$operations.$methodName($requiredParamList)
    Write-Verbose "Waiting for the operation to complete."
    `$null = `$taskResult.AsyncWaitHandle.WaitOne()
    Write-Debug "`$(`$taskResult | Out-String)"

    if(`$taskResult.IsFaulted) {
       Write-Verbose 'Operation failed.'
       Throw "`$(`$taskResult.Exception.InnerExceptions | Out-String)"
    } elseif (`$taskResult.IsCanceled) {
       Write-Verbose 'Operation got cancelled.'
       Throw 'Operation got cancelled.'
    } else {
        Write-Verbose 'Operation completed successfully.'

        if(`$taskResult.Result -and 
           (Get-Member -InputObject `$taskResult.Result -Name 'Body') -and
           `$taskResult.Result.Body) 
        {
            `$result = `$taskResult.Result.Body
            Write-Verbose -Message "`$result | Out-String)"
            `$result
        }
    }
   
'@
 
    $commandName = Get-SwaggerPathCommandName $JsonPathItemObject
    $description = ""
    if((Get-Member -InputObject $JsonPathItemObject -Name 'Description') -and $JsonPathItemObject.Description) {
        $description = $JsonPathItemObject.Description
    }
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    [string]$paramHelp = ""
    $paramblock = ""
    $requiredParamList = @()
    $optionalParamList = @()
    $body = ""
    $Namespace = $SwaggerSpecDefinitionsAndParameters['namespace']

    # Handle the function parameters
    #region Function Parameters

    $JsonPathItemObject.parameters | ForEach-Object {
        if((Get-Member -InputObject $_ -Name 'Name') -and $_.Name)
        {
            $isParamMandatory = '$false'
            $parameterName = Get-PascalCasedString -Name $_.Name
            $paramName = "`$$parameterName" 
            $paramType = if ( (Get-Member -InputObject $_ -Name 'Type') -and $_.Type)
                         {
                            # Use the format as parameter type if that is available as a type in PowerShell
                            if ( (Get-Member -InputObject $_ -Name 'Format') -and $_.Format -and ($null -ne ($_.Format -as [Type])) ) 
                            {
                                $_.Format
                            }
                            else {
                                $_.Type
                            }
                         } elseif ( (Get-Member -InputObject $_ -Name 'Schema') -and ($_.Schema) -and
                             (Get-Member -InputObject $_.Schema -Name '$ref') -and ($_.Schema.'$ref') )
                         {
                            $ReferenceParameterValue = $_.Schema.'$ref'
                            $Namespace + '.Models.' + $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
                         }
                         else {
                             'object'
                         }
            if ($_.Required)
            { 
                $isParamMandatory = '$true'
                $requiredParamList += $paramName
            }
            else
            {
                $optionalParamList += $paramName
            }

            $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)

            if ((Get-Member -InputObject $_ -Name 'Description') -and $_.Description)
            {
                $pDescription = $_.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            }
        }
        elseif((Get-Member -InputObject $_ -Name '$ref') -and ($_.'$ref'))
        {
        }
    }# $parametersSpec

    $paramblock = $paramBlock.TrimEnd().TrimEnd(",")
    $requiredParamList = $requiredParamList -join ', '
    $optionalParamList = $optionalParamList -join ', '

    #endregion Function Parameters

    # Handle the function body
    #region Function Body
    $infoVersion = $SwaggerSpecDefinitionsAndParameters['infoVersion']
    $modulePostfix = $SwaggerSpecDefinitionsAndParameters['infoName']
    $fullModuleName = $Namespace + '.' + $modulePostfix
    $clientName = '$' + $modulePostfix
    $apiVersion = ''
    if (-not $UseAzureCsharpGenerator)
    {
        $apiVersion = '{0}.ApiVersion = "{1}"' -f $clientName,$infoVersion
    }

    $operationId = $JsonPathItemObject.operationId
    $opIdValues = $operationId -split '_',2 
    if(-not $opIdValues -or ($opIdValues.count -ne 2)) {
        $methodName = $operationId + 'WithHttpMessagesAsync'
        $operations = ''
    } else {            
        $operationName = $JsonPathItemObject.operationId.Split('_')[0]
        $operationType = $JsonPathItemObject.operationId.Split('_')[1]
        $operations = ".$operationName"
        if ((-not $UseAzureCsharpGenerator) -and 
            (Test-OperationNameInDefinitionList -Name $operationName -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters))
        { 
            $operations = $operations + 'Operations'
        }
        $methodName = $operationType + 'WithHttpMessagesAsync'
    }

    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    #endregion Function Body

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignature)
    Write-Verbose $CommandString

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    return $CommandName
}

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

    $Name = $JsonDefinitionItemObject.Name -split "\[",2 | Select-Object -First 1 -ErrorAction Ignore
    
    $FunctionDescription = ""
    if((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'Description') -and 
       $JsonDefinitionItemObject.Value.Description)
    {
        $FunctionDescription = $JsonDefinitionItemObject.Value.Description
    }

    $DefinitionTypeNamePrefix = "$Namespace.Models."

    $x_ms_Client_flatten_DefinitionNames = @()
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

    $JsonDefinitionItemObject.Value.properties.PSObject.Properties | ForEach-Object {

        if((Get-Member -InputObject $_ -Name 'Name') -and $_.Name)
        {
            $ParameterJsonObject = $_.Value

            $ParameterDetails = @{}

            $IsParamMandatory = '$false'
            $ValidateSetString = $null
            $ParameterDescription = ''
            $parameterName = Get-PascalCasedString -Name $_.Name
            
            $paramType = if ( (Get-Member -InputObject $ParameterJsonObject -Name 'Type') -and $ParameterJsonObject.Type)
                         {
                            # Use the format as parameter type if that is available as a type in PowerShell
                            if ( (Get-Member -InputObject $ParameterJsonObject -Name 'Format') -and 
                                 $ParameterJsonObject.Format -and 
                                 ($null -ne ($ParameterJsonObject.Format -as [Type])) ) 
                            {
                                $ParameterJsonObject.Format
                            }
                            elseif ( ($ParameterJsonObject.Type -eq 'array') -and
                                     (Get-Member -InputObject $ParameterJsonObject -Name 'Items') -and 
                                     $ParameterJsonObject.Items)
                            {
                                if((Get-Member -InputObject $ParameterJsonObject.Items -Name '$ref') -and 
                                   $ParameterJsonObject.Items.'$ref')
                                {
                                    $ReferenceTypeValue = $ParameterJsonObject.Items.'$ref'
                                    $ReferenceTypeName = $ReferenceTypeValue.Substring( $( $ReferenceTypeValue.LastIndexOf('/') ) + 1 )
                                    $DefinitionTypeNamePrefix + "$ReferenceTypeName[]"
                                }
                                elseif((Get-Member -InputObject $ParameterJsonObject.Items -Name 'Type') -and $ParameterJsonObject.Items.Type)
                                {
                                    "$($ParameterJsonObject.Items.Type)[]"
                                }
                                else
                                {
                                    $ParameterJsonObject.Type
                                }                             
                            }
                            elseif ( ($ParameterJsonObject.Type -eq 'object') -and
                                     (Get-Member -InputObject $ParameterJsonObject -Name 'AdditionalProperties') -and 
                                     $ParameterJsonObject.AdditionalProperties)
                            {
                                $AdditionalPropertiesType = $ParameterJsonObject.AdditionalProperties.Type
                                "System.Collections.Generic.Dictionary[[$AdditionalPropertiesType],[$AdditionalPropertiesType]]"
                            }
                            else
                            {
                                $ParameterJsonObject.Type
                            }
                         }
                         elseif ( $parameterName -eq 'Properties' -and
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
                             $DefinitionFunctionsDetails[$ReferenceDefinitionName] = $ReferencedFunctionDetails
                         }
                         elseif ( (Get-Member -InputObject $ParameterJsonObject -Name '$ref') -and ($ParameterJsonObject.'$ref') )
                         {
                            $ReferenceParameterValue = $ParameterJsonObject.'$ref'
                            $DefinitionTypeNamePrefix + $ReferenceParameterValue.Substring( $( $ReferenceParameterValue.LastIndexOf('/') ) + 1 )
                         }
                         else 
                         {
                             'object'
                         }

            if($paramType -eq 'Boolean')
            {
                $paramType = 'switch'
            }

            if ((Get-Member -InputObject $JsonDefinitionItemObject.Value -Name 'Required') -and 
                $JsonDefinitionItemObject.Value.Required -and
                ($JsonDefinitionItemObject.Value.Required -contains $parameterName) )
            {
                $IsParamMandatory = '$true'
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

            if ((Get-Member -InputObject $ParameterJsonObject -Name 'Description') -and $ParameterJsonObject.Description)
            {
                $ParameterDescription = $ParameterJsonObject.Description
            }

            $ParameterDetails['Name'] = $parameterName
            $ParameterDetails['Type'] = $paramType
            $ParameterDetails['ValidateSet'] = $ValidateSetString
            $ParameterDetails['Mandatory'] = $IsParamMandatory
            $ParameterDetails['Description'] = $ParameterDescription

            if($paramType)
            {
                $ParametersTable[$parameterName] = $ParameterDetails
            }
        }
    }# $parametersSpec

    $Unexpanded_AllOf_DefinitionNames = $AllOf_DefinitionNames
    $Unexpanded_x_ms_client_flatten_DefinitionNames = $x_ms_Client_flatten_DefinitionNames
    $ExpandedParameters = (-not $Unexpanded_AllOf_DefinitionNames -and -not $Unexpanded_x_ms_client_flatten_DefinitionNames)

    $FunctionDetails = @{}
    if($DefinitionFunctionsDetails.ContainsKey($Name))
    {
        $FunctionDetails = $DefinitionFunctionsDetails[$Name]
    }

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

    $helpDescStr = @'
.DESCRIPTION
    $description
'@

    $advFnSignature = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
   param($paramblock
   )
   $body
}
'@

    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)] $ValidateSetDefinition    
    [$paramType]
    $paramName,

'@

    $ValidateSetDefinitionString = @'

    [ValidateSet($ValidateSetString)]
'@

    $helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

    $functionBodyStr = @'

   `$Object = New-Object -TypeName $DefinitionTypeName

   `$PSBoundParameters.Keys | ForEach-Object { 
       `$Object.`$_ = `$PSBoundParameters[`$_]
   }

   if(Get-Member -InputObject `$Object -Name Validate -MemberType Method)
   {
       `$Object.Validate()
   }

   return `$Object
'@
 
    $commandName = "New-$($FunctionDetails.Name)Object"

    $description = $FunctionDetails.description
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    [string]$paramHelp = ""
    $paramblock = ""
    $body = ""
    $DefinitionTypeNamePrefix = "$Namespace.Models."

    $FunctionDetails.ParametersTable.Keys | ForEach-Object {
        $ParameterDetails = $FunctionDetails.ParametersTable[$_]

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
        $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)

        $pDescription = $ParameterDetails.Description
        $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
    }

    $paramblock = $paramBlock.TrimEnd().TrimEnd(",")

    $DefinitionTypeName = $DefinitionTypeNamePrefix + $FunctionDetails.Name
    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignature)
    Write-Verbose $CommandString

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    return $CommandName
}

<#
.DESCRIPTION
  Converts an operation id to a reasonably good cmdlet name
#>
function Get-SwaggerPathCommandName
{
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject    
    )

    if((Get-Member -InputObject $JsonPathItemObject -Name 'x-ms-cmdlet-name') -and $JsonPathItemObject.'x-ms-cmdlet-name') { 
        return $JsonPathItemObject.'x-ms-cmdlet-name'
    }

    $opId = $JsonPathItemObject.OperationId
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
        Write-Verbose "Verb $cmdVerb not an approved verb."
        if ($cmdNounMap.ContainsKey($cmdVerb))
        {
            Write-Verbose "Using Verb $($cmdNounMap[$cmdVerb]) in place of $cmdVerb."
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

            Write-Verbose "Using Noun $cmdNoun. Using Verb $cmdVerb"
        }
    }

    return "$cmdVerb-$cmdNoun"
}

function Get-SwaggerSpecDefinitionAndParameter
{
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecJsonObject,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName
    )

    if(-not (Get-Member -InputObject $jsonObject -Name 'info')) {
        Throw "Invalid Swagger specification file. Info section doesn't exists."
    }

    $SwaggerSpecificationDetails = @{}    

    # Get info entries
    $info = $SwaggerSpecJsonObject.info 
    
    $infoVersion = '1-0-0'
    if((Get-Member -InputObject $info -Name 'Version') -and $info.Version) { 
        $infoVersion = $info.Version
    }

    $infoTitle = $info.title
    $infoName = ''
    if((Get-Member -InputObject $info -Name 'x-ms-code-generation-settings') -and $info.'x-ms-code-generation-settings'.Name) { 
        $infoName = $info.'x-ms-code-generation-settings'.Name
    }

    if (-not $infoName) {
         $infoName = $infoTitle
    }

    $SwaggerSpecificationDetails['infoVersion'] = $infoVersion
    $SwaggerSpecificationDetails['infoTitle'] = $infoTitle
    $SwaggerSpecificationDetails['infoName'] = $infoName
    $SwaggerSpecificationDetails['Version'] = [Version](($infoVersion -split "-",4) -join '.')
    $NamespaceVersionSuffix = "v$(($infoVersion -split '-',4) -join '')"
    $SwaggerSpecificationDetails['Namespace'] = "Microsoft.PowerShell.$ModuleName.$NamespaceVersionSuffix"
    $SwaggerSpecificationDetails['ModuleName'] = $ModuleName

    if(Get-Member -InputObject $jsonObject -Name 'parameters') {    
        # Get global parameters
        $globalParams = $SwaggerSpecJsonObject.parameters
        $globalParams.PSObject.Properties | ForEach-Object {
            $name = Get-PascalCasedString -Name $_.name
            $SwaggerSpecificationDetails[$name] = $globalParams.$name
        }
    }

    $definitionList = @{}
    if(Get-Member -InputObject $jsonObject -Name 'definitions') {
        # Get definitions list
        $definitions = $SwaggerSpecJsonObject.definitions
        $definitions.PSObject.Properties | ForEach-Object {
            $name = $_.name
            $definitionList.Add($name, $_)
        }
    }
    $SwaggerSpecificationDetails['definitionList'] = $definitionList

    return $SwaggerSpecificationDetails
}

function Get-PascalCasedString {
    param([string] $Name)

    if($Name) {
        $Name = Remove-SpecialCharecter -Name $Name
        $startIndex = 0
        $subStringLength = 1

        # Convert the two letter abbreviations to upper case.
        # Example: vmName --> VMName
        if($Name.Length -gt 2) {
            $thirdCharString = $Name.substring(2, 1)
            if($thirdCharString.ToUpper() -ceq $thirdCharString) {
                $subStringLength = 2
            }
        }

        return $($Name.substring($startIndex, $subStringLength)).ToUpper() + $Name.substring($subStringLength)
    }

}

function Remove-SpecialCharecter
{
    param([string] $Name)

    $pattern = '[^a-zA-Z]'
    return ($Name -replace $pattern, '')
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

    $definitionList = $SwaggerSpecDefinitionsAndParameters['definitionList']
    if ($definitionList.ContainsKey($Name))
    {
        return $true
    }
    return $false
}

#endregion

#region Module Generation Helpers

function ConvertTo-CsharpCode
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $SwaggerSpecPath,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $ModuleName,

        [Parameter(Mandatory = $true)]
        [string] $Namespace,

        [Parameter()]
        [switch] $UseAzureCsharpGenerator        
        )

    Write-Verbose "Generating CSharp Code using AutoRest"

    $autoRestExePath = get-command autorest.exe | ForEach-Object source
    if (-not $autoRestExePath)
    {
        throw "Unable to find AutoRest.exe in PATH environment. Ensure the PATH is updated."
    }

    $outputDirectory = $Path
    $outAssembly = join-path $outputDirectory "$Namespace.dll"
    $net45Dir = join-path $outputDirectory "Net45"
    $generatedCSharpPath = Join-Path $outputDirectory "Generated.Csharp"

    if (Test-Path $outAssembly)
    {
        Remove-Item -Path $outAssembly -Force
    }

    if (Test-Path $net45Dir)
    {
        Remove-Item -Path $net45Dir -Force -Recurse
    }

    $codeGenerator = "CSharp"
    
    $refassemlbiles = @("System.dll",
                        "System.Core.dll",
                        "System.Net.Http.dll",
                        "System.Net.Http.WebRequest",
                        "System.Runtime.Serialization.dll",
                        "System.Xml.dll",
                        "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Microsoft.Rest.ClientRuntime.dll",
                        "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Newtonsoft.Json.dll")

    if ($UseAzureCsharpGenerator) 
    { 
        $codeGenerator = "Azure.CSharp"
        $refassemlbiles += "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Microsoft.Rest.ClientRuntime.Azure.dll"
    }

    $null = & $autoRestExePath -AddCredentials -input $SwaggerSpecPath -CodeGenerator $codeGenerator -OutputDirectory $generatedCSharpPath -NameSpace $Namespace
    if ($LastExitCode)
    {
        throw "AutoRest resulted in an error"
    }

    Write-Verbose "Generating assembly from the CSharp code"

    $srcContent = Get-ChildItem -Path $generatedCSharpPath  -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*' | ForEach-Object { "// File $($_.FullName)"; get-content $_.FullName }
    $oneSrc = $srcContent -join "`n"

    Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies $refassemlbiles -OutputAssembly $outAssembly

    if(Test-Path -Path $outAssembly -PathType Leaf){
        Write-Verbose -Message "Generated $outAssembly assembly"
    } else {
        Throw "Unable to generated $outAssembly assembly"
    }
}

function New-ModuleManifestUtility
{
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string[]]
        $FunctionsToExport,

        [Parameter(Mandatory = $true)]        
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    New-ModuleManifest -Path "$(Join-Path -Path $Path -ChildPath $SwaggerSpecDefinitionsAndParameters['ModuleName']).psd1" `
                       -ModuleVersion $SwaggerSpecDefinitionsAndParameters['Version'] `
                       -RequiredModules @('Generated.Azure.Common.Helpers') `
                       -RequiredAssemblies @("$($SwaggerSpecDefinitionsAndParameters['Namespace']).dll") `
                       -RootModule "$($SwaggerSpecDefinitionsAndParameters['ModuleName']).psm1" `
                       -FunctionsToExport $FunctionsToExport
}

# Utility to throw an errorrecord
function Write-TerminatingError
{
    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,
        
        [System.Object]
        $ExceptionObject,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
        
    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject    
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}

#endregion

Export-ModuleMember -Function Export-CommandFromSwagger
