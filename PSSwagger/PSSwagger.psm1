#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# PSSwagger Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
. "$PSScriptRoot\PSSwagger.Constants.ps1"
. "$PSScriptRoot\Utils.ps1"
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

<#
.DESCRIPTION
  Decodes the swagger spec and generates PowerShell cmdlets.

.PARAMETER  SwaggerSpecPath
  Full Path to a Swagger based JSON spec.

.PARAMETER  Path
  Full Path to a file where the commands are exported to.

.PARAMETER  SkipAssemblyGeneration
  Switch to skip precompiling the module's binary component for full CLR.

.PARAMETER  PowerShellCorePath
  Path to PowerShell.exe for PowerShell Core.

.PARAMETER  IncludeCoreFxAssembly
  Switch to additionally compile the module's binary component for core CLR.
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
        $UseAzureCsharpGenerator,

        [Parameter()]
        [switch]
        $SkipAssemblyGeneration,

        [Parameter()]
        [String]
        $PowerShellCorePath,

        [Parameter()]
        [switch]
        $IncludeCoreFxAssembly
    )

    if ($SkipAssemblyGeneration -and $PowerShellCorePath) {
        throw $LocalizedData.MustNotSpecifyPsCorePath
    }

    if ($SkipAssemblyGeneration -and $IncludeCoreFxAssembly) {
        throw $LocalizedData.MustNotSpecifyIncludeCoreFx
    }

    if ($PSCmdlet.ParameterSetName -eq 'SwaggerURI')
    {
        # Ensure that if the URI is coming from github, it is getting the raw content
        if($SwaggerSpecUri.Host -eq 'github.com'){
            $SwaggerSpecUri = "https://raw.githubusercontent.com$($SwaggerSpecUri.AbsolutePath)"
            $message = $LocalizedData.ConvertingSwaggerSpecToGithubContent -f ($SwaggerSpecUri)
            Write-Verbose -Message $message -Verbose
        }

        $SwaggerSpecPath = [io.path]::GetTempFileName() + ".json"
        $message = $LocalizedData.SwaggerSpecDownloadedTo -f ($SwaggerSpecURI, $SwaggerSpecPath)
        Write-Verbose -Message $message
        
        $ev = $null
        Invoke-WebRequest -Uri $SwaggerSpecUri -OutFile $SwaggerSpecPath -ErrorVariable ev
        if($ev) {
            return 
        }
    }

    if (-not (Test-path -Path $SwaggerSpecPath))
    {
        throw $LocalizedData.SwaggerSpecPathNotExist -f ($SwaggerSpecPath)
    }

    if ((-not $SkipAssemblyGeneration) -and ($IncludeCoreFxAssembly)) {
        if (('Desktop' -eq $PSEdition) -and (-not $PowerShellCorePath)) {
            $psCore = Get-Package -Name PowerShell* -MaximumVersion 6.0.0.11 -ProviderName msi | Sort-Object -Property Version -Descending
            if ($null -ne $psCore) {
                # PSCore exists via MSI, but the MSI provider doesn't seem to provide an install path
                # First check the default path (for now, just Windows)
                $psCore | ForEach-Object {
                    if (-not $PowerShellCorePath) {
                        $message = $LocalizedData.FoundPowerShellCoreMsi -f ($($_.Version))
                        Write-Verbose -Message $message
                        $possiblePsPath = (Join-Path -Path "$env:ProgramFiles" -ChildPath "PowerShell" | Join-Path -ChildPath "$($_.Version)" | Join-Path -ChildPath "PowerShell.exe")
                        if (Test-Path -Path $possiblePsPath) {
                            $PowerShellCorePath = $possiblePsPath
                        }
                    }
                }
            }
        }

        if (-not $PowerShellCorePath) {
            throw $LocalizedData.SwaggerSpecPathNotExist -f ($SwaggerSpecPath)
        }

        if ((Get-Item $PowerShellCorePath).PSIsContainer) {
            $PowerShellCorePath = Join-Path -Path $PowerShellCorePath -ChildPath "PowerShell.exe"
        }

        if (-not (Test-Path -Path $PowerShellCorePath)) {
            $message = $LocalizedData.FoundPowerShellCoreMsi -f ($PowerShellCorePath)
            throw $message
        }
    }

    $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop

    # Parse the JSON and populate the dictionary
    $swaggerDict = ConvertTo-SwaggerDictionary -SwaggerSpecPath $SwaggerSpecPath -ModuleName $ModuleName
    $nameSpace = $swaggerDict['info'].NameSpace
    $version = $swaggerDict['info'].version
    $moduleName = $swaggerDict['info'].moduleName

    # Populate the metadata, definitions and parameters from the provided Swagger specification
    #$SwaggerSpecDefinitionsAndParameters = Get-SwaggerSpecDefinitionAndParameter -SwaggerSpecJsonObject $jsonObject -ModuleName $ModuleName
    $swaggerMetaDict = @{}
    
    $outputDirectory = $Path.TrimEnd('\').TrimEnd('/')

    if($PSVersionTable.PSVersion -lt '5.0.0') {
        if (-not $outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleName
        }
    } else {
        #$ModuleVersion = $SwaggerSpecDefinitionsAndParameters['Version']
        $ModuleNameandVersionFolder = Join-Path -Path $ModuleName -ChildPath $Version

        if ($outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleVersion
        } elseif (-not $outputDirectory.EndsWith($ModuleNameandVersionFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleNameandVersionFolder
        }
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop

    $swaggerMetaDict.Add("outputDirectory", $outputDirectory);
    $swaggerMetaDict.Add("UseAzureCsharpGenerator", $UseAzureCsharpGenerator)
    $swaggerMetaDict.Add("SwaggerSpecPath", $SwaggerSpecPath);

    #$Namespace = $SwaggerSpecDefinitionsAndParameters['Namespace']
    $generatedCSharpFilePath = ConvertTo-CsharpCode -SwaggerDict $swaggerDict `
                                    -SwaggerMetaDict $swaggerMetaDict `
                                    -SkipAssemblyGeneration:$SkipAssemblyGeneration `
                                    -PowerShellCorePath $PowerShellCorePath `

    # Prepare dynamic compilation
    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Utils.ps1") (Join-Path -Path $outputDirectory -ChildPath "Utils.ps1")

    $allCSharpFiles = Get-ChildItem -Path $generatedCSharpFilePath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    $filesHash = New-CodeFileCatalog -Files $allCSharpFiles
    $fileHashesFileName = "GeneratedCsharpCatalog.json"
    ConvertTo-Json -InputObject $filesHash | Out-File -FilePath (Join-Path -Path "$outputDirectory" -ChildPath "$fileHashesFileName")
    $jsonFileHashAlgorithm = "SHA512"
    $jsonFileHash = (Get-FileHash -Path (Join-Path -Path "$outputDirectory" -ChildPath "$fileHashesFileName") -Algorithm $jsonFileHashAlgorithm).Hash
    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "ref" ) $outputDirectory -Recurse -Force -Container


    # Handle the Definitions
    $DefinitionFunctionsDetails = @{}
    $jsonObject.Definitions.PSObject.Properties | ForEach-Object {
        Get-SwaggerSpecDefinitionInfo -JsonDefinitionItemObject $_ `
                                        -Namespace $Namespace `
                                        -DefinitionFunctionsDetails $DefinitionFunctionsDetails
    }

    # Handle the Paths
    $PathFunctionDetails = @{}
    $jsonObject.Paths.PSObject.Properties | ForEach-Object {
        Get-SwaggerSpecPathInfo -JsonPathItemObject $_ `
                                -PathFunctionDetails $PathFunctionDetails `
                                -Info $swaggerDict['info'] `
                                -DefinitionList $swaggerDict['definitions'] `
                                -SwaggerMetaDict $swaggerMetaDict `
                                -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                -SwaggerSpecDefinitionsAndParameters $swaggerDict
    }

    $FunctionsToExport = @()
    $FunctionsToExport += New-SwaggerSpecPathCommand -PathFunctionDetails $PathFunctionDetails `
                                                     -SwaggerMetaDict $swaggerMetaDict

    $FunctionsToExport += New-SwaggerDefinitionCommand -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                                        -SwaggerMetaDict $swaggerMetaDict `
                                                        -NameSpace $nameSpace

    $RootModuleFilePath = Join-Path $outputDirectory "$ModuleName.psm1"
    Out-File -FilePath $RootModuleFilePath `
             -InputObject $ExecutionContext.InvokeCommand.ExpandString($RootModuleContents)`
             -Encoding ascii `
             -Force

    New-ModuleManifestUtility -Path $outputDirectory `
                              -FunctionsToExport $FunctionsToExport `
							  -Info $swaggerDict['info']
                              #-SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters

    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Generated.Resources.psd1") (Join-Path -Path "$outputDirectory" -ChildPath "$ModuleName.Resources.psd1") -Force
}

#region Cmdlet Generation Helpers
<#
function New-SwaggerPathCommands
{
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]
        $CommandsObject,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashTable]
        $DefinitionList,

        [Parameter(Mandatory = $true)]
        [hashTable]
        $Info
    )

    $functionsToExport = @()
    $CommandsObject.Keys | ForEach-Object {
        $CommandsObject[$_].value.PSObject.Properties | ForEach-Object {
            $functionsToExport += New-SwaggerPathCommand -SwaggerMetaDict $SwaggerMetaDict `
                                                            -PathObject $_.Value `
                                                            -DefinitionList $DefinitionList `
                                                            -Info $Info
        }
    }

    return $functionsToExport
}

function New-SwaggerPathCommand
{
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [PSObject]
        $PathObject,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionList,

        [Parameter(Mandatory = $true)]
        [hashTable]
        $Info
    )

    $commandHelp = Get-CommandHelp -PathObject $PathObject
    
    $commandName = Get-SwaggerPathCommandName -JsonPathItemObject $PathObject

    $paramObject = Get-ParamInfo -PathObject $PathObject 

    $paramHelp = $paramObject['ParamHelp']
    $paramblock = $paramObject['ParamBlock']
    $requiredParamList = $paramObject['RequiredParamList']
    $optionalParamList = $paramObject['OptionalParamList']

    $bodyObject = Get-FunctionBody -PathObject $PathObject `
                                        -SwaggerMetaDict $SwaggerMetaDict `
                                        -DefinitionList $DefinitionList `
                                        -RequiredParamList $requiredParamList `
                                        -OptionalParamList $optionalParamList `
                                        -Info $Info

    $outputTypeBlock = $bodyObject['outputTypeBlock']
    $body = $bodyObject['body']

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignature)

    $GeneratedCommandsPath = Join-Path -Path (Join-Path -Path $SwaggerMetaDict['outputDirectory'] -ChildPath $GeneratedCommandsName) -ChildPath 'SwaggerPathCommands'

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    return $CommandName
}
#>

<#
.DESCRIPTION
  Generates a cmdlet given a JSON custom object (from paths)

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

    # TODO: remove as part of issue 21: Unify Functions
    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)]
    [$paramType]
    $paramName,

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
    $apiVersion = $null
    $SubscriptionId = $null
    $BaseUri = $null

    if (-not $UseAzureCsharpGenerator)
    {
        $apiVersion = $executionContext.InvokeCommand.ExpandString($ApiVersionStr)
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

    $responseBodyParams = @{
                                responses = $jsonPathItemObject.responses.PSObject.Properties
                                namespace = $Namespace
                                definitionList = $SwaggerSpecDefinitionsAndParameters['definitionList']
    
    }

    $responseBody, $outputTypeBlock = Get-Response @responseBodyParams
    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    #endregion Function Body

    $CommandString = $executionContext.InvokeCommand.ExpandString($advFnSignature)
    Write-Verbose -Message $CommandString

    if(-not (Test-Path -Path $GeneratedCommandsPath -PathType Container)) {
        $null = New-Item -Path $GeneratedCommandsPath -ItemType Directory
    }

    $CommandFilePath = Join-Path -Path $GeneratedCommandsPath -ChildPath "$CommandName.ps1"
    Out-File -InputObject $CommandString -FilePath $CommandFilePath -Encoding ascii -Force -Confirm:$false -WhatIf:$false

    return $CommandName
}
#>

<#
.DESCRIPTION
  Converts an operation id to a reasonably good cmdlet name
#>
function Get-SwaggerPathCommandName
{
    param
    (
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
        $message = $LocalizedData.UnapprovedVerb -f ($cmdVerb)
        Write-Verbose "Verb $cmdVerb not an approved verb."
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
        Throw $LocalizedData.InvalidSwaggerSpecification
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
<#
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

function Get-CommandHelp
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $PathObject
    )

    $description = $null
    if((Get-Member -InputObject $PathObject -Name 'Description') -and $PathObject.Description) {
        $description = $PathObject.Description
    }

    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    return $commandHelp
}

function Get-ParamInfo
{
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $PathObject
    )

    $paramblock = ""
    $paramHelp = ""
    $requiredParamList = @()
    $optionalParamList = @()

    $PathObject.parameters | ForEach-Object {
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

            $ValidateSetDefinition = $null
            if ((Get-Member -InputObject $_ -Name 'ValidateSet') -and $_.ValidateSet)
            {
                $ValidateSetString = $_.ValidateSet
                $ValidateSetDefinition = $executionContext.InvokeCommand.ExpandString($ValidateSetDefinitionString)
            }

            $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)

            if ((Get-Member -InputObject $_ -Name 'Description') -and $_.Description)
            {
                $pDescription = $_.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            }            
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

function Get-FunctionBody
{
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $PathObject,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DefinitionList,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $RequiredParamList,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $OptionalParamList,

        [Parameter(Mandatory = $true)]
        [hashTable]
        $Info
    )

    $infoVersion = $Info['infoVersion']
    $modulePostfix = $Info['infoName']
    $fullModuleName = $Namespace + '.' + $modulePostfix
    $clientName = '$' + $modulePostfix
    $apiVersion = $null
    $SubscriptionId = $null
    $BaseUri = $null
    
    if (-not $UseAzureCsharpGenerator)
    {
        $apiVersion = $executionContext.InvokeCommand.ExpandString($ApiVersionStr)
    }

    $operationId = $PathObject.operationId
    $opIdValues = $operationId -split '_',2

    if(-not $opIdValues -or ($opIdValues.count -ne 2)) {
        $methodName = $operationId + 'WithHttpMessagesAsync'
        $operations = ''
    } else {            
        $operationName = $PathObject.operationId.Split('_')[0]
        $operationType = $PathObject.operationId.Split('_')[1]
        $operations = ".$operationName"
        if ((-not $SwaggerMetaDict['UseAzureCsharpGenerator']) -and 
                ($DefinitionList.containsKey($operationName)))
        { 
            $operations = $operations + 'Operations'
        }
        $methodName = $operationType + 'WithHttpMessagesAsync'
    }

    $responseBodyParams = @{
                            responses = $PathObject.responses.PSObject.Properties
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
#>
#endregion

#region Module Generation Helpers

function ConvertTo-CsharpCode
{
    param
    (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $SwaggerDict,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter()]
        [bool]
        $SkipAssemblyGeneration,

        [Parameter()]
        [String]
        $PowerShellCorePath
    )

    $message = $LocalizedData.GenerateCodeUsingAutoRest
    Write-Verbose -Message $message

    $autoRestExePath = get-command -name autorest.exe | ForEach-Object source
    if (-not $autoRestExePath)
    {
        throw $LocalizedData.AutoRestNotInPath
    }

    $outputDirectory = $SwaggerMetaDict['outputDirectory']
    $nameSpace = $SwaggerDict['info'].NameSpace
    $generatedCSharpPath = Join-Path -Path $outputDirectory -ChildPath "Generated.Csharp"
    $codeGenerator = "CSharp"

    if ($SwaggerMetaDict['UseAzureCsharpGenerator'])
    { 
        $codeGenerator = "Azure.CSharp"
    }

    $null = & $autoRestExePath -AddCredentials -input $swaggerMetaDict['SwaggerSpecPath'] -CodeGenerator $codeGenerator -OutputDirectory $generatedCSharpPath -NameSpace $Namespace
    if ($LastExitCode)
    {
        throw $LocalizedData.AutoRestError
    }

    if (-not $SkipAssemblyGeneration) {
        $message = $LocalizedData.GenerateAssemblyFromCode
        Write-Verbose -Message $message

        $allCSharpFilesArrayString = '@('
        Get-ChildItem -Path $generatedCSharpPath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*' | ForEach-Object {
            $allCSharpFilesArrayString += "'$_',"
        }
        $allCSharpFilesArrayString = $allCSharpFilesArrayString.Substring(0, $allCSharpFilesArrayString.Length-1)
        $allCSharpFilesArrayString += ')'

        # Compile full CLR (PSSwagger requires to be invoked from full PowerShell)
        $outAssembly = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'fullclr' | Join-Path -ChildPath "$NameSpace.dll"
        if (Test-Path -Path $outAssembly)
        {
            $null = Remove-Item -Path $outAssembly -Force
        }

        if (-not (Test-Path -Path (Split-Path -Path $outAssembly -Parent))) {
            $null = New-Item -Path (Split-Path -Path $outAssembly -Parent) -ItemType Directory
        }
        
        $codeCreatedByAzureGenerator = [bool]$SwaggerMetaDict['UseAzureCsharpGenerator']
        $command = "Import-Module '$PSScriptRoot\Utils.ps1';Invoke-AssemblyCompilation -OutputAssembly '$outAssembly' -CSharpFiles $allCSharpFilesArrayString -CopyExtraReferences -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator"
        $success = powershell -command "& {$command}"
        if($success){
            $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
            Write-Verbose -Message $message
        } else {
            $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
            Throw $message
        }

        if ($PowerShellCorePath) {
            # Compile core CLR
            $outAssembly = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'coreclr' | Join-Path -ChildPath "$NameSpace.dll"
            if (Test-Path $outAssembly)
            {
                $null = Remove-Item -Path $outAssembly -Force
            }

            if (-not (Test-Path (Split-Path $outAssembly -Parent))) {
                $null = New-Item (Split-Path $outAssembly -Parent) -ItemType Directory
            }

            $command = "Import-Module '$PSScriptRoot\Utils.ps1';Invoke-AssemblyCompilation -OutputAssembly '$outAssembly' -CSharpFiles $allCSharpFilesArrayString -CopyExtraReferences -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator"
            $success = & "$PowerShellCorePath" -command "& {$command}"
            if($success -eq $true){
                $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
                Write-Verbose -Message $message
            } else {
                $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
                Throw $message
            }
        }
    }

    return $generatedCSharpPath
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

        <#
        [Parameter(Mandatory = $true)]        
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
        #>

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Info
    )

    $FormatsToProcess = Get-ChildItem -Path "$Path\$GeneratedCommandsName\FormatFiles\*.ps1xml" -File | Foreach-Object { $_.FullName.Replace($Path, '.') }

    New-ModuleManifest -Path "$(Join-Path -Path $Path -ChildPath $Info.ModuleName).psd1" `
                       -ModuleVersion $Info.Version `
                       -RequiredModules @('Generated.Azure.Common.Helpers') `
                       -RootModule "$($Info.ModuleName).psm1" `
                       -FormatsToProcess $FormatsToProcess `
                       -FunctionsToExport $FunctionsToExport
}

#endregion

function New-CodeFileCatalog {
    param(
        [string[]]$Files
    )

    $hashAlgorithm = "SHA512"
    $filesTable = @{"Algorithm" = $hashAlgorithm}
    $Files | ForEach-Object {
        $fileName = "$_".Replace("$generatedCSharpFilePath","").Trim("\").Trim("/") 
        $hash = (Get-FileHash $_ -Algorithm $hashAlgorithm).Hash
        $message = $LocalizedData.FoundFileWithHash -f ($fileName, $hash)
        $filesTable.Add("$fileName", $hash) 
    }

    return $filesTable
}

Export-ModuleMember -Function Export-CommandFromSwagger