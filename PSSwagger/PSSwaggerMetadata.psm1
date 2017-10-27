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

$SubScripts = @(
    'PSSwagger.Constants.ps1'
)
$SubScripts | ForEach-Object {. (Join-Path -Path $PSScriptRoot -ChildPath $_) -Force}

$SubModules = @(
    'SwaggerUtils.psm1',
    'Utilities.psm1',
    'Paths.psm1',
    'Definitions.psm1'
)
$SubModules | ForEach-Object {Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $_) -Force -Scope Local -DisableNameChecking}

Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

<#
.SYNOPSIS
    Creates PowerShell Metadata json file with PowerShell Extensions for the specified Swagger document.

.DESCRIPTION
    Creates PowerShell Metadata json file with PowerShell Extensions for the specified Swagger document.
    This file can be used to customize the PowerShell specific metadata like 
    cmdlet name, parameter name, output format views, code generation settings, PowerShell Module metadata and other related metadata.
    PowerShell Metadata file name for <SwaggerSpecFileName>.json is <SwaggerSpecFileName>.psmeta.json.
    This <SwaggerSpecFileName>.psmeta.json file gets created under the same location as the specified swagger document path.

.EXAMPLE
    PS> New-PSSwaggerMetadataFile -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json'
    Generates 'C:\SwaggerSpecs\BatchManagement.psmeta.json' file with PowerShell extensions for customizing the PowerShell related metadata.

.EXAMPLE
    PS> New-PSSwaggerMetadataFile -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json' -Force
    Regenerates 'C:\SwaggerSpecs\BatchManagement.psmeta.json' file with PowerShell extensions for customizing the PowerShell related metadata.
  
.PARAMETER  SpecificationPath
    Full Path to a Swagger based JSON spec.

.PARAMETER  Force
    To replace the existing PowerShell Metadata file.

.INPUTS

.OUTPUTS

.NOTES

.LINK

#>
function New-PSSwaggerMetadataFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true)]
        [string] 
        $SpecificationPath,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    # Validate swagger path
    if (-not (Test-path -Path $SpecificationPath -PathType Leaf)) {
        throw $LocalizedData.SwaggerSpecPathNotExist -f ($SpecificationPath)
        return
    }

    $PSMetaFilePath = [regex]::replace($SpecificationPath, ".json$", ".psmeta.json")
    if ((-not $Force) -and (Test-Path -Path $PSMetaFilePath -PathType Leaf)) {
        Throw $LocalizedData.PSMetaFileExists -f ($PSMetaFilePath, $SpecificationPath)
    }

    $SwaggerSpecFilePaths = @()
    $AutoRestModeler = 'Swagger'    
    $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SpecificationPath) -join [Environment]::NewLine) -ErrorAction Stop
    $SwaggerBaseDir = Split-Path -Path $SpecificationPath -Parent
    if ((Get-Member -InputObject $jsonObject -Name 'Documents') -and ($jsonObject.Documents.Count)) {
        $AutoRestModeler = 'CompositeSwagger'
        foreach ($document in $jsonObject.Documents) {
            if (Test-Path -Path $document -PathType Leaf) {
                $SwaggerSpecFilePaths += $document
            }
            elseif (Test-Path -Path (Join-Path -Path $SwaggerBaseDir -ChildPath $document) -PathType Leaf) {
                $SwaggerSpecFilePaths += Join-Path -Path $SwaggerBaseDir -ChildPath $document
            }
            else {
                throw $LocalizedData.PathNotFound -f ($document)
                return
            }
        }
    }
    else {
        $SwaggerSpecFilePaths += $SpecificationPath
    }

    $DefinitionFunctionsDetails = @{}
    $ParameterGroupCache = @{}
    $PathFunctionDetails = @{}
    $x_ms_path_FunctionDetails = @{}
    
    # Parse the JSON and populate the dictionary
    $ConvertToSwaggerDictionary_params = @{
        SwaggerSpecPath            = $SpecificationPath
        SwaggerSpecFilePaths       = $SwaggerSpecFilePaths
        DefinitionFunctionsDetails = $DefinitionFunctionsDetails
    }
    $swaggerDict = ConvertTo-SwaggerDictionary @ConvertToSwaggerDictionary_params

    $nameSpace = $swaggerDict['info'].NameSpace
    $models = $swaggerDict['info'].Models
    $swaggerMetaDict = @{
        SwaggerSpecPath      = $SpecificationPath
        SwaggerSpecFilePaths = $SwaggerSpecFilePaths
        AutoRestModeler      = $AutoRestModeler
    }

    foreach ($FilePath in $SwaggerSpecFilePaths) {
        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $FilePath) -join [Environment]::NewLine) -ErrorAction Stop

        if (Get-Member -InputObject $jsonObject -Name 'Definitions') {
            # Handle the Definitions
            $jsonObject.Definitions.PSObject.Properties | ForEach-Object {
                $GetSwaggerSpecDefinitionInfo_params = @{
                    JsonDefinitionItemObject   = $_
                    Namespace                  = $Namespace
                    DefinitionFunctionsDetails = $DefinitionFunctionsDetails
                    Models                     = $models
                }
                Get-SwaggerSpecDefinitionInfo @GetSwaggerSpecDefinitionInfo_params
            }
        }

        if (Get-Member -InputObject $jsonObject -Name 'Paths') {
            # Handle the Paths
            $jsonObject.Paths.PSObject.Properties | ForEach-Object {
                $GetSwaggerSpecPathInfo_params = @{
                    JsonPathItemObject         = $_
                    PathFunctionDetails        = $PathFunctionDetails
                    SwaggerDict                = $swaggerDict
                    SwaggerMetaDict            = $swaggerMetaDict
                    DefinitionFunctionsDetails = $DefinitionFunctionsDetails
                    ParameterGroupCache        = $ParameterGroupCache
                }
                Get-SwaggerSpecPathInfo @GetSwaggerSpecPathInfo_params
            }
        }

        if (Get-Member -InputObject $jsonObject -Name 'x-ms-paths') {
            # Handle extended paths
            $jsonObject.'x-ms-paths'.PSObject.Properties | ForEach-Object {
                $GetSwaggerSpecPathInfo_params = @{
                    JsonPathItemObject         = $_
                    PathFunctionDetails        = $x_ms_path_FunctionDetails
                    SwaggerDict                = $swaggerDict
                    SwaggerMetaDict            = $swaggerMetaDict
                    DefinitionFunctionsDetails = $DefinitionFunctionsDetails
                    ParameterGroupCache        = $ParameterGroupCache
                }
                Get-SwaggerSpecPathInfo @GetSwaggerSpecPathInfo_params
            }
        }
    }

    $infoMetadata = Get-InfoPSMetadata -SwaggerDict $swaggerDict
    $definitionsMetadata = Get-DefinitionsPSMetadata -DefinitionFunctionsDetails $DefinitionFunctionsDetails -SwaggerDict $swaggerDict
    $pathsMetadata = Get-PathsPSMetadata -PathFunctionDetails $PathFunctionDetails    
    $globalParametersMetadata = Get-GlobalParametersPSMetadata -SwaggerDict $swaggerDict

    $psMetadata = [ordered]@{
        info  = $infoMetadata
        paths = $pathsMetadata
    }

    # Add x-ms-paths key if there are any swagger operations are specified under x-ms-paths.
    if (Get-HashtableKeyCount -Hashtable $x_ms_path_FunctionDetails) {
        $x_ms_pathsMetadata = Get-PathsPSMetadata -PathFunctionDetails $x_ms_path_FunctionDetails
        $psMetadata['x-ms-paths'] = $x_ms_pathsMetadata
    }
    
    $psMetadata['definitions'] = $definitionsMetadata
    $psMetadata['parameters'] = $globalParametersMetadata

    $psmetaJson = ConvertTo-Json -InputObject $psMetadata -Depth 100 | Format-JsonUtility

    if ($psmetaJson -and ($Force -or $pscmdlet.ShouldProcess($PSMetaFilePath, $LocalizedData.NewPSSwaggerMetadataFileOperationMessage))) {
        $OutFile_Params = @{
            InputObject = $psmetaJson
            FilePath    = $PSMetaFilePath
            Encoding    = 'ascii'
            Force       = $true
            Confirm     = $false
            WhatIf      = $false
        }
        Out-File @OutFile_Params

        Write-Verbose -Message ($LocalizedData.SuccessfullyGeneratedMetadataFile -f $PSMetaFilePath, $SpecificationPath)
    }
}

#region PSSwaggerMetadata Utilities

<#
    Helper function for getting the code generation settings and module info metadata.
#>
function Get-InfoPSMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $SwaggerDict
    )

    $PSCodeGenerationSettings = [ordered]@{
        codeGenerator         = 'CSharp'
        nameSpacePrefix       = 'Microsoft.PowerShell.'
        noAssembly            = $false
        powerShellCorePath    = ''
        includeCoreFxAssembly = $false
        testBuild             = $false
        confirmBootstrap      = $false
        path                  = '.'
        symbolPath            = '.'
        serviceType           = ''
        customAuthCommand     = ''
        hostOverrideCommand   = ''
        noAuthChallenge       = ''
    }

    $PSModuleInfo = [ordered]@{
        name                 = $swaggerDict['Info'].ModuleName
        moduleVersion        = $swaggerDict['Info'].Version.ToString()
        guid                 = [guid]::NewGuid()
        description          = $swaggerDict['Info'].Description
        author               = $swaggerDict['Info'].ContactEmail
        companyName          = ''
        CopyRight            = $swaggerDict['Info'].LicenseName
        licenseUri           = $swaggerDict['Info'].LicenseUri
        projectUri           = $swaggerDict['Info'].ProjectUri
        helpInfoUri          = ''
        iconUri              = ''
        releaseNotes         = ''
        defaultCommandPrefix = ''
        tags                 = @()
    }

    return [ordered]@{
        'x-ps-code-generation-settings' = $PSCodeGenerationSettings
        'x-ps-module-info'              = $PSModuleInfo
    }
}

<#
    Helper function for getting the definitions metadata with 
    cmdlet infos, parameter info and output format info.
#>
function Get-DefinitionsPSMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $DefinitionFunctionsDetails,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $SwaggerDict
    )

    $definitionsMetadata = [ordered]@{}
    $DefinitionFunctionsDetails.GetEnumerator() | Foreach-Object {
        $definitionName = $_.Name
        $FunctionDetails = $_.Value

        $generateCommand = $false
        $generateOutputFormat = $false
        if ($FunctionDetails.IsModel) {
            $generateCommand = $true
            $generateOutputFormat = $true            
        }

        $x_ps_cmdlet_info = [ordered]@{
            name                 = "New-$($definitionName)Object"
            description          = $FunctionDetails.Description
            defaultParameterSet  = $definitionName
            generateCommand      = $generateCommand
            generateOutputFormat = $generateOutputFormat
        }

        $propertiesPSMetadata = [ordered]@{}
        $defaultFormatViewWidth = 10

        $TableColumnItemCount = 0
        $ParametersCount = Get-HashtableKeyCount -Hashtable $FunctionDetails.ParametersTable
        $SkipParameterList = @('id', 'tags')
        $Namespace = $SwaggerDict['info'].NameSpace

        $FunctionDetails.ParametersTable.GetEnumerator() | Foreach-Object {
            $parameterName = $_.Name
            $parameterDetails = $_.Value

            $x_ps_parameter_info = [ordered]@{
                name        = $parameterName
                description = $parameterDetails.Description
            }

            # Enable output format view for all properties when definition has 4 or less properties.
            # Otherwise add the first 4 properties with basic types by skipping the complex types, id and tags.
            if ($FunctionDetails.IsModel -and 
                (($ParametersCount -le 4) -or 
                    (($TableColumnItemCount -le 4) -and 
                        ($SkipParameterList -notcontains $parameterDetails.Name) -and 
                        (-not $ParameterDetails.Type.StartsWith($Namespace, [System.StringComparison]::OrdinalIgnoreCase))))) {
                $includeInOutputFormat = $true
                $formatViewPosition = $TableColumnItemCount
                $TableColumnItemCount = $TableColumnItemCount + 1
            }
            else {
                $includeInOutputFormat = $false
                # Position is specified as -1 so that module owner can edit this value with proper position number 
                # if he/she decides to enable the output format for the specific property.
                $formatViewPosition = -1
            }

            $x_ps_output_format_info = [ordered]@{
                include  = $includeInOutputFormat
                position = $formatViewPosition
                width    = $defaultFormatViewWidth
            }

            $propertiesPSMetadata[$parameterDetails.OriginalParameterName] = [ordered]@{
                'x-ps-parameter-info'     = $x_ps_parameter_info
                'x-ps-output-format-info' = $x_ps_output_format_info
            }
        }
        
        $definitionsMetadata[$definitionName] = [ordered]@{
            'x-ps-cmdlet-infos' = @($x_ps_cmdlet_info)
            properties          = $propertiesPSMetadata
        }
    }

    return $definitionsMetadata
}

<#
    Helper function for getting the paths metadata with 
    cmdlet infos and parameter info.
#>
function Get-PathsPSMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $PathFunctionDetails
    )

    $pathsMetadata = [ordered]@{}
    $PathFunctionDetails.GetEnumerator() | Foreach-Object {
        $CommandName = $_.Name
        $FunctionDetails = $_.Value
        $defaultParameterSetName = ''
        $FunctionDetails.ParameterSetDetails | Foreach-Object {
            $ParameterSetDetail = $_
            # When multiple operations are combined into single cmdlet,
            # adding first parameterset as the default parameterset name.
            if (-not $defaultParameterSetName) {
                $defaultParameterSetName = $ParameterSetDetail.ParameterSetName
            }

            $EndpointRelativePath = $ParameterSetDetail.EndpointRelativePath
            if ($pathsMetadata.Contains($EndpointRelativePath)) {
                $operationsPSMetadata = $pathsMetadata[$EndpointRelativePath]
            }
            else {
                $operationsPSMetadata = [ordered]@{}
            }

            $operationType = $ParameterSetDetail.OperationType
            if ($operationsPSMetadata.Contains($operationType)) {
                $opPSMetadata = $operationsPSMetadata[$operationType]
            }
            else {
                $opPSMetadata = [ordered]@{}
            }

            if ($opPSMetadata.Contains('x-ps-cmdlet-infos')) {
                $x_ps_cmdlet_infos = $opPSMetadata['x-ps-cmdlet-infos']
            }
            else {
                $x_ps_cmdlet_infos = @()
            }

            $x_ps_cmdlet_infos += [ordered]@{
                name                = $CommandName
                description         = $ParameterSetDetail.Description
                defaultParameterSet = $defaultParameterSetName
                generateCommand     = $true
            }
            $opPSMetadata['x-ps-cmdlet-infos'] = $x_ps_cmdlet_infos

            # For multiple cmdlet scenario like CreateAndUpdate, 
            # if parameters are already populated for one cmdlet, 
            # it is not required to process the parameters for other cmdlet for same operationId.
            if (-not $opPSMetadata.Contains('parameters')) {
                $parametersPSMetadata = [ordered]@{}
                $ParameterSetDetail.ParameterDetails.GetEnumerator() | Foreach-Object {
                    $paramDetails = $_.Value
                    $parameterName = $paramDetails.Name
                    if ($paramDetails.ContainsKey('OriginalParameterName') -and $paramDetails.OriginalParameterName) {
                        $x_ps_parameter_info = [ordered]@{
                            name        = $parameterName
                            description = $paramDetails.Description
                            flatten     = $false
                        }
                        $parametersPSMetadata[$paramDetails.OriginalParameterName] = [ordered]@{
                            'x-ps-parameter-info' = $x_ps_parameter_info
                        }
                    }
                }
                $opPSMetadata['parameters'] = $parametersPSMetadata
            }

            # Handle path level common parameters, if any
            $PathCommonParameters = $ParameterSetDetail.PathCommonParameters
            if (Get-HashtableKeyCount -Hashtable $PathCommonParameters) {
                $pathItemFieldName = 'parameters'
                if (-not $operationsPSMetadata.Contains($pathItemFieldName)) {
                    $pathItemFieldPSMetadata = [ordered]@{}
                    $PathCommonParameters.GetEnumerator() | Foreach-Object {
                        $paramDetails = $_.Value
                        $parameterName = $paramDetails.Name
                        if ($paramDetails.ContainsKey('OriginalParameterName') -and $paramDetails.OriginalParameterName) {
                            $x_ps_parameter_info = [ordered]@{
                                name        = $parameterName
                                description = $paramDetails.Description
                                flatten     = $false
                            }
                            $pathItemFieldPSMetadata[$paramDetails.OriginalParameterName] = [ordered]@{
                                'x-ps-parameter-info' = $x_ps_parameter_info
                            }
                        }
                    }
                    $operationsPSMetadata[$pathItemFieldName] = $pathItemFieldPSMetadata
                }                
            }
            
            $operationsPSMetadata[$operationType] = $opPSMetadata
            $pathsMetadata[$EndpointRelativePath] = $operationsPSMetadata
        }
    }
    return $pathsMetadata
}

<#
    Helper function for getting the parameter infos for the global parameters.
#>
function Get-GlobalParametersPSMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $SwaggerDict
    )

    $globalParametersMetadata = [ordered]@{}
    $SwaggerDict.Parameters.GetEnumerator() | Foreach-Object {        
        $commonParameterKeyName = $_.Name
        $parameterDetails = $_.Value
        
        $x_ps_parameter_info = [ordered]@{
            name        = $parameterDetails.Name
            description = $parameterDetails.Description
            flatten     = $false
        }
        $parameterPSMetadata = [ordered]@{
            'x-ps-parameter-info' = $x_ps_parameter_info
        }
        $globalParametersMetadata[$commonParameterKeyName] = $parameterPSMetadata
    }
    
    return $globalParametersMetadata
}

<#
.DESCRIPTION
    Utility for formatting the json content.
    ConvertTo-Json cmdlet doesn't format the json content properly on Windows PowerShell.
  
.PARAMETER  Json
  Json string value.
#>
function Format-JsonUtility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Json
    )

    $indent = 0;
    ($json -Split '\n' | ForEach-Object {
            if (($_ -match ' [\}\]]') -or ($_ -match '[\}\]]$')) {
                # This line contains  ] or }, decrement the indentation level
                if ($indent -gt 0) {
                    $indent--
                }
            }
            $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')

            if (($_ -match ' [\{\[]') -or ($_ -match '^[\{\[]')) {
                # This line contains [ or {, increment the indentation level
                $indent++
            }

            $line
        }) -Join "`n"
}

#endregion PSSwaggerMetadata Utilities

Export-ModuleMember -Function New-PSSwaggerMetadataFile