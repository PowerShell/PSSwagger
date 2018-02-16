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
    PowerShell command to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

.DESCRIPTION
    PowerShell command to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

.EXAMPLE
    PS> New-PSSwaggerModule -SpecificationUri 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json' -Path 'C:\GeneratedModules\' -Name 'AzBatchManagement' -UseAzureCsharpGenerator
    Generates a PS Module for the specified SpecificationUri.

.EXAMPLE
    PS> New-PSSwaggerModule -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json' -Path 'C:\GeneratedModules\' -Name 'AzBatchManagement' -UseAzureCsharpGenerator
    Generates a PS Module for the specified SpecificationPath.

.PARAMETER  SpecificationPath
    Full Path to a Swagger based JSON spec.

.PARAMETER  SpecificationUri
    Uri to a Swagger based JSON spec.

.PARAMETER Credential
    Credential to use when the SpecificationUri requires authentication.
    It will override -UseDefaultCredential when both are specified at the same time.

.PARAMETER UseDefaultCredential
    Use default credentials to download the SpecificationUri. Overridden by -Credential when both are specified at the same time.

.PARAMETER  AssemblyFileName
    File name of the pre-compiled SDK assembly.
    This assembly along with its dependencies should be available in '.\ref\fullclr\' folder under the target module version base path ($Path\$Name\$Version\).
    If your generated module needs to work on PowerShell Core, place the coreclr assembly along with its dependencies under '.\ref\coreclr\' folder under the target module version base path ($Path\$Name\$Version\).
    For FullClr, the specified assembly should be available at "$Path\$Name\$Version\ref\fullclr\$AssemblyFileName".
    For CoreClr, the specified assembly should be available at "$Path\$Name\$Version\ref\coreclr\$AssemblyFileName".

.PARAMETER  ClientTypeName
    Client type name in the pre-compiled SDK assembly.
    Specify if client type name is different from the value of 'Title' field from the input specification, or
    if client type namespace is different from the specified namespace in the specification.
    It is recommended to specify the fully qualified client type name.

.PARAMETER  ModelsName
    Models name if it is different from default value 'Models'.
    It is recommended to specify the custom models name in using x-ms-code-generation-settings extension in specification.

.PARAMETER  Path
    Full Path to a file where the commands are exported to.

.PARAMETER  Name
    Name of the module to be generated. A folder with this name will be created in the location specified by Path parameter.

.PARAMETER  Version
    Version of the generated PowerShell module.

.PARAMETER  NoVersionFolder
    Switch to not create the version folder under the generated module folder.

.PARAMETER  DefaultCommandPrefix
    Prefix value to be prepended to cmdlet noun or to cmdlet name without verb.

.PARAMETER  Header
    Text to include as a header comment in the PSSwagger generated files.
    It also can be a path to a .txt file with the content to be added as header in the PSSwagger generated files.

    Supported predefined license header values:
    - NONE: Suppresses the default header.
    - MICROSOFT_MIT: Adds predefined Microsoft MIT license text with default PSSwagger code generation header content.
    - MICROSOFT_MIT_NO_VERSION: Adds predefined Microsoft MIT license text with default PSSwagger code generation header content without version.
    - MICROSOFT_MIT_NO_CODEGEN: Adds predefined Microsoft MIT license text without default PSSwagger code generation header content.
    - MICROSOFT_APACHE: Adds predefined Microsoft Apache license text with default PSSwagger code generation header content.
    - MICROSOFT_APACHE_NO_VERSION: Adds predefined Microsoft Apache license text with default PSSwagger code generation header content without version.
    - MICROSOFT_APACHE_NO_CODEGEN: Adds predefined Microsoft Apache license text without default PSSwagger code generation header content.

.PARAMETER  NoAssembly
    Switch to disable saving the precompiled module assembly and instead enable dynamic compilation.

.PARAMETER  PowerShellCorePath
    Path to PowerShell.exe for PowerShell Core.
    Only required if PowerShell Core not installed via MSI in the default path.

.PARAMETER  IncludeCoreFxAssembly
    Switch to additionally compile the module's binary component for Core CLR.

.PARAMETER  InstallToolsForAllUsers
    User wants to install local tools for all users.
  
.PARAMETER  TestBuild
    Switch to disable optimizations during build of full CLR binary component.
  
.PARAMETER  SymbolPath
    Path to save the generated C# code and PDB file. Defaults to $Path\symbols.

.PARAMETER  ConfirmBootstrap
    Automatically consent to downloading nuget.exe or NuGet packages as required.

.PARAMETER  UseAzureCsharpGenerator
    Switch to specify whether AzureCsharp code generator is required.
    By default, this command uses CSharp code generator.

    When this switch is specified and the resource id follows the guidelines of Azure Resource operations
    - The following additional parameter sets will be generated
      - InputObject parameter set with the same object type returned by Get. Supports piping from Get operarion to action cmdlets.
      - ResourceId parameter set which splits the resource id into component parts (supports piping from generic cmdlets).
    - Parameter name of Azure resource name parameter will be generated as 'Name' and the actual resource name parameter from the resource id will be added as an alias.
    
.PARAMETER  Formatter
    Specify a formatter to use. 

.PARAMETER  CopyUtilityModuleToOutput
    Copy the utility module to the output generated module. This has the effect of hardcoding the version of the utility module used by the generated module. The copied utility module must be re-signed if it was originally signed.

.PARAMETER  AddUtilityDependencies
    Ensure any external assemblies required by the utility module are included somewhere in the module. This has the effect of making the utility module offline-compatible.


.INPUTS

.OUTPUTS

.NOTES

.LINK

#>
function New-PSSwaggerModule {
    [CmdletBinding(DefaultParameterSetName = 'SpecificationPath')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [string] 
        $SpecificationPath,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [Uri]
        $SpecificationUri,
                
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [PSCredential]
        $Credential = $null,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [switch]
        $UseDefaultCredential,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [string]
        $AssemblyFileName,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [string]
        $ClientTypeName,

        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [string]
        $ModelsName,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [Version]
        $Version = '0.0.1',

        [Parameter(Mandatory = $false)]
        [switch]
        $NoVersionFolder,

        [Parameter(Mandatory = $false)]
        [string]
        $DefaultCommandPrefix,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Header,

        [Parameter()]
        [switch]
        $UseAzureCsharpGenerator,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [switch]
        $NoAssembly,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [string]
        $PowerShellCorePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [switch]
        $IncludeCoreFxAssembly,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [switch]
        $InstallToolsForAllUsers,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [switch]
        $TestBuild,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [string]
        $SymbolPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [switch]
        $ConfirmBootstrap,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [string]
        [ValidateSet('None', 'PSScriptAnalyzer')]
        $Formatter,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [switch]
        $CopyUtilityModuleToOutput,

        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificationUri')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SdkAssemblyWithSpecificationUri')]
        [switch]
        $AddUtilityDependencies
    )

    if ($NoAssembly -and $IncludeCoreFxAssembly) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('IncludeCoreFxAssembly', 'NoAssembly')
        throw $message
        return
    }

    if ($NoAssembly -and $TestBuild) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('TestBuild', 'NoAssembly')
        throw $message
        return
    }

    if ($NoAssembly -and $PowerShellCorePath) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('PowerShellCorePath', 'NoAssembly')
        throw $message
        return
    }

    if ($NoAssembly -and $SymbolPath) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('SymbolPath', 'NoAssembly')
        throw $message
        return
    }
    
    $SwaggerSpecFilePaths = @()
    $AutoRestModeler = 'Swagger'
    
    if (($PSCmdlet.ParameterSetName -eq 'SpecificationUri') -or 
        ($PSCmdlet.ParameterSetName -eq 'SdkAssemblyWithSpecificationUri')) {
        # Ensure that if the URI is coming from github, it is getting the raw content
        if ($SpecificationUri.Host -eq 'github.com') {
            $SpecificationUri = "https://raw.githubusercontent.com$($SpecificationUri.AbsolutePath.Replace('/blob/','/'))"
            $message = $LocalizedData.ConvertingSwaggerSpecToGithubContent -f ($SpecificationUri)
            Write-Verbose -Message $message -Verbose
        }

        $TempPath = Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath (Get-Random)
        $null = New-Item -Path $TempPath -ItemType Directory -Force -Confirm:$false -WhatIf:$false

        $SwaggerFileName = Split-Path -Path $SpecificationUri -Leaf
        $SpecificationPath = Join-Path -Path $TempPath -ChildPath $SwaggerFileName

        $message = $LocalizedData.SwaggerSpecDownloadedTo -f ($SpecificationUri, $SpecificationPath)
        Write-Verbose -Message $message
        
        $ev = $null

        $webRequestParams = @{
            'Uri'     = $SpecificationUri
            'OutFile' = $SpecificationPath
        }

        if ($Credential -ne $null) {
            $webRequestParams['Credential'] = $Credential
        }
        elseif ($UseDefaultCredential) {
            $webRequestParams['UseDefaultCredential'] = $true
        }

        Invoke-WebRequest @webRequestParams -ErrorVariable ev 
        if ($ev) {
            return 
        }

        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SpecificationPath) -join [Environment]::NewLine) -ErrorAction Stop
        if ((Get-Member -InputObject $jsonObject -Name 'Documents') -and ($jsonObject.Documents.Count)) {
            $AutoRestModeler = 'CompositeSwagger'
            $BaseSwaggerUri = "$SpecificationUri".Substring(0, "$SpecificationUri".LastIndexOf('/'))
            foreach ($document in $jsonObject.Documents) {
                $FileName = Split-Path -Path $document -Leaf
                $DocumentFolderPrefix = (Split-Path -Path $document -Parent).Replace('/', [System.IO.Path]::DirectorySeparatorChar).TrimStart('.')
                
                $DocumentFolderPath = Join-Path -Path $TempPath -ChildPath $DocumentFolderPrefix

                if (-not (Test-Path -LiteralPath $DocumentFolderPath -PathType Container)) {
                    $null = New-Item -Path $DocumentFolderPath -ItemType Container -Force -Confirm:$false -WhatIf:$false
                }
                $SwaggerDocumentPath = Join-Path -Path $DocumentFolderPath -ChildPath $FileName

                $ev = $null
                $webRequestParams['Uri'] = $($BaseSwaggerUri + $($document.replace('\', '/').TrimStart('.')))
                $webRequestParams['OutFile'] = $SwaggerDocumentPath

                Invoke-WebRequest @webRequestParams -ErrorVariable ev
                if ($ev) {
                    return 
                }
                $SwaggerSpecFilePaths += $SwaggerDocumentPath
            }
        }
        else {
            $SwaggerSpecFilePaths += $SpecificationPath
        }
    }    

    $outputDirectory = Microsoft.PowerShell.Management\Resolve-Path -Path $Path | Select-Object -First 1 -ErrorAction Ignore
    $outputDirectory = "$outputDirectory".TrimEnd('\').TrimEnd('/')
    if (-not $SymbolPath) {
        $SymbolPath = Join-Path -Path $Path -ChildPath "symbols"
    }

    if (-not $outputDirectory -or (-not (Test-path -Path $outputDirectory -PathType Container))) {
        throw $LocalizedData.PathNotFound -f ($Path)
        return
    }
  
    # Validate swagger path and composite swagger paths
    if (-not (Test-path -Path $SpecificationPath)) {
        throw $LocalizedData.SwaggerSpecPathNotExist -f ($SpecificationPath)
        return
    }

    # Get the PowerShell Metadata if .psmeta.json file is available.
    $PSMetaJsonObject = $null
    $PSMetaFilePath = [regex]::replace($SpecificationPath, ".json$", ".psmeta.json")
    if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
        $PSMetaJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $PSMetaFilePath) -join [Environment]::NewLine) -ErrorAction Stop
    }

    if (($PSCmdlet.ParameterSetName -eq 'SpecificationPath') -or 
        ($PSCmdlet.ParameterSetName -eq 'SdkAssemblyWithSpecificationPath')) {
        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SpecificationPath) -join [Environment]::NewLine) -ErrorAction Stop
        if ((Get-Member -InputObject $jsonObject -Name 'Documents') -and ($jsonObject.Documents.Count)) {
            $AutoRestModeler = 'CompositeSwagger'
            $SwaggerBaseDir = Split-Path -Path $SpecificationPath -Parent
            foreach ($document in $jsonObject.Documents) {
                $FileName = Split-Path -Path $document -Leaf
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
    }

    if (($PSCmdlet.ParameterSetName -eq 'SpecificationPath') -or 
        ($PSCmdlet.ParameterSetName -eq 'SpecificationUri')) {
        $frameworksToCheckDependencies = @('net4')
        if ($IncludeCoreFxAssembly) {
            if ((-not (Get-OperatingSystemInfo).IsCore) -and (-not $PowerShellCorePath)) {
                $psCore = Get-PSSwaggerMsi -Name "PowerShell*" -MaximumVersion "6.0.0.11" | Sort-Object -Property Version -Descending
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
                throw $LocalizedData.MustSpecifyPsCorePath
            }

            if ((Get-Item $PowerShellCorePath).PSIsContainer) {
                $PowerShellCorePath = Join-Path -Path $PowerShellCorePath -ChildPath "PowerShell.exe"
            }

            if (-not (Test-Path -Path $PowerShellCorePath)) {
                $message = $LocalizedData.PsCorePathNotFound -f ($PowerShellCorePath)
                throw $message
            }

            $frameworksToCheckDependencies += 'netstandard1'
        }

        $userConsent = Initialize-PSSwaggerLocalTool -AllUsers:$InstallToolsForAllUsers -Azure:$UseAzureCsharpGenerator -Framework $frameworksToCheckDependencies -AcceptBootstrap:$ConfirmBootstrap
    }

    $DefinitionFunctionsDetails = @{}
    $PowerShellCodeGen = @{
        CodeGenerator         = ""
        Path                  = ""
        NoAssembly            = ""
        PowerShellCorePath    = ""
        IncludeCoreFxAssembly = ""
        TestBuild             = ""
        SymbolPath            = ""
        ConfirmBootstrap      = ""
        AdditionalFilesPath   = ""
        ServiceType           = ""
        CustomAuthCommand     = ""
        HostOverrideCommand   = ""
        NoAuthChallenge       = $false
        NameSpacePrefix       = ''
        Header                = ''
        Formatter             = 'PSScriptAnalyzer'
        DefaultWildcardChar   = '%'
        AzureDefaults         = $null
    }

    # Parse the JSON and populate the dictionary
    $ConvertToSwaggerDictionary_params = @{
        SwaggerSpecPath            = $SpecificationPath
        ModuleName                 = $Name
        ModuleVersion              = $Version
        DefaultCommandPrefix       = $DefaultCommandPrefix
        Header                     = $($Header -join "`r`n")
        SwaggerSpecFilePaths       = $SwaggerSpecFilePaths
        DefinitionFunctionsDetails = $DefinitionFunctionsDetails
        AzureSpec                  = $UseAzureCsharpGenerator
        PowerShellCodeGen          = $PowerShellCodeGen
        PSMetaJsonObject           = $PSMetaJsonObject
        ClientTypeName             = $ClientTypeName
        ModelsName                 = $ModelsName
    }
    $swaggerDict = ConvertTo-SwaggerDictionary @ConvertToSwaggerDictionary_params

    Get-PowerShellCodeGenSettings -Path $SpecificationPath -CodeGenSettings $PowerShellCodeGen -PSMetaJsonObject $PSMetaJsonObject
    if (-not $PSMetaJsonObject) {
        foreach ($additionalSwaggerSpecPath in $SwaggerSpecFilePaths) {
            Get-PowerShellCodeGenSettings -Path $additionalSwaggerSpecPath -CodeGenSettings $PowerShellCodeGen
        }
    }

    if (-not $Formatter) {
        if ($PowerShellCodeGen['Formatter']) {
            $Formatter = $PowerShellCodeGen['Formatter']
        }
        else {
            $Formatter = 'None'
        }
    }

    if ($Formatter) {
        if ($Formatter -eq 'PSScriptAnalyzer') {
            if (-not (Get-Module PSScriptAnalyzer -ListAvailable)) {
                Write-Warning $LocalizedData.PSScriptAnalyzerMissing
                $Formatter = 'None'
            }
        }
    }

    # Expand partner metadata
    if ($PowerShellCodeGen['ServiceType']) {
        $partnerFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ServiceTypes" | Join-Path -ChildPath "$($PowerShellCodeGen['ServiceType'].ToLowerInvariant()).PSMeta.json"
        if (-not (Test-Path -Path $partnerFilePath -PathType Leaf)) {
            Write-Warning -Message ($LocalizedData.ServiceTypeMetadataFileNotFound -f $partnerFilePath)
        }
        else {
            Get-PowerShellCodeGenSettings -Path $partnerFilePath -CodeGenSettings $PowerShellCodeGen
        }
    }
    
    $nameSpace = $swaggerDict['info'].NameSpace
    $models = $swaggerDict['info'].Models
    if ($NoVersionFolder -or $PSVersionTable.PSVersion -lt '5.0.0') {
        if (-not $outputDirectory.EndsWith($Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $Name
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $Name
        }
    }
    else {
        $ModuleNameandVersionFolder = Join-Path -Path $Name -ChildPath $Version

        if ($outputDirectory.EndsWith($Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $Version
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $Version
        }
        elseif (-not $outputDirectory.EndsWith($ModuleNameandVersionFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleNameandVersionFolder
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $ModuleNameandVersionFolder
        }
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop -Confirm:$false -WhatIf:$false
    $null = New-Item -ItemType Directory $SymbolPath -Force -ErrorAction Stop -Confirm:$false -WhatIf:$false

    $swaggerMetaDict = @{
        OutputDirectory         = $outputDirectory
        UseAzureCsharpGenerator = $UseAzureCsharpGenerator
        SwaggerSpecPath         = $SpecificationPath
        SwaggerSpecFilePaths    = $SwaggerSpecFilePaths
        AutoRestModeler         = $AutoRestModeler
        PowerShellCodeGen       = $PowerShellCodeGen
    }

    $ParameterGroupCache = @{}
    $PathFunctionDetails = @{}

    foreach ($FilePath in $SwaggerSpecFilePaths) {
        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $FilePath) -join [Environment]::NewLine) -ErrorAction Stop

        if (Get-Member -InputObject $jsonObject -Name 'Definitions') {
            # Handle the Definitions
            $jsonObject.Definitions.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecDefinitionInfo -JsonDefinitionItemObject $_ `
                    -Namespace $Namespace `
                    -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                    -Models $models
            }
        }

        if (Get-Member -InputObject $jsonObject -Name 'Paths') {
            # Handle the Paths
            $jsonObject.Paths.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecPathInfo -JsonPathItemObject $_ `
                    -PathFunctionDetails $PathFunctionDetails `
                    -SwaggerDict $swaggerDict `
                    -SwaggerMetaDict $swaggerMetaDict `
                    -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                    -ParameterGroupCache $ParameterGroupCache `
                    -PSMetaJsonObject $PSMetaJsonObject
            }
        }

        if (Get-Member -InputObject $jsonObject -Name 'x-ms-paths') {
            # Handle extended paths
            $jsonObject.'x-ms-paths'.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecPathInfo -JsonPathItemObject $_ `
                    -PathFunctionDetails $PathFunctionDetails `
                    -SwaggerDict $swaggerDict `
                    -SwaggerMetaDict $swaggerMetaDict `
                    -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                    -ParameterGroupCache $ParameterGroupCache `
                    -PSMetaJsonObject $PSMetaJsonObject

            }
        }

        # Add extra metadata based on service type
        if (($PowerShellCodeGen['ServiceType'] -eq 'azure') -or ($PowerShellCodeGen['ServiceType'] -eq 'azure_stack') -and
            ($PowerShellCodeGen.ContainsKey('azureDefaults') -and $PowerShellCodeGen['azureDefaults'] -and
                (-not (Get-Member -InputObject $PowerShellCodeGen['azureDefaults'] -Name 'clientSideFiltering')) -or
                ($PowerShellCodeGen['azureDefaults'].ClientSideFiltering))) {
            foreach ($entry in $PathFunctionDetails.GetEnumerator()) {
                $hyphenIndex = $entry.Name.IndexOf("-")
                if ($hyphenIndex -gt -1) {
                    $commandVerb = $entry.Name.Substring(0, $hyphenIndex)
                    # Add client-side filter metadata automatically if:
                    #   1: If the command is a Get-* command
                    #   2: A *_List parameter set exists
                    #   3: A *_Get parameter set exists
                    #   4: *_List required parameters are a subset of *_Get required parameters
                    #   5: *_Get has a -Name parameter alias
                    if ($commandVerb -eq 'Get') {
                        $getParameters = @()
                        $listParameters = $null
                        $listOperationId = $null
                        $getOperationId = $null
                        $nameParameterNormalName = $null # This is the one being switched out for -Name later
                        foreach ($parameterSetDetails in $entry.Value.ParameterSetDetails) {
                            if ($parameterSetDetails.OperationId.EndsWith("_Get") -and
                                (-not ($parameterSetDetails.OperationId.StartsWith("InputObject_"))) -and
                                (-not ($parameterSetDetails.OperationId.StartsWith("ResourceId_")))) {
                                $getOperationId = $parameterSetDetails.OperationId
                                foreach ($parametersDetail in $parameterSetDetails.ParameterDetails) {
                                    foreach ($parameterDetailEntry in $parametersDetail.GetEnumerator()) {
                                        $getParameters += $parameterDetailEntry.Value
                                        if ($parameterDetailEntry.Value.ContainsKey('Alias')) {
                                            if ($parameterDetailEntry.Value.Alias -eq 'Name') {
                                                $nameParameterNormalName = $parameterDetailEntry.Value.Name
                                            }
                                        }
                                        elseif ($parameterDetailEntry.Value.Name -eq 'Name') {
                                            # We're currently assuming this is a resource name
                                            $nameParameterNormalName = $parameterDetailEntry.Value.Name
                                        }
                                    }
                                }
                            }
                            elseif ($parameterSetDetails.OperationId.EndsWith("_List")) {
                                $listOperationId = $parameterSetDetails.OperationId
                                $listParameters = @()
                                foreach ($parametersDetail in $parameterSetDetails.ParameterDetails) {
                                    foreach ($parameterDetailEntry in $parametersDetail.GetEnumerator()) {
                                        $listParameters += $parameterDetailEntry.Value
                                    }
                                }
                            }
                        }

                        if ($getParameters -and $listParameters) {
                            $valid = $true
                            foreach ($parameterDetail in $listParameters) {
                                if ($parameterDetail.Mandatory -eq '$true') {
                                    $matchingGetParameter = $getParameters | Where-Object { ($_.Name -eq $parameterDetail.Name) -and ($_.Mandatory -eq '$true') }
                                    if (-not $matchingGetParameter) {
                                        $valid = $false
                                        Write-Warning -Message ($LocalizedData.FailedToAddAutomaticFilter -f $entry.Name)
                                    }
                                }
                            }

                            if ($valid) {
                                if (-not $entry.Value.ContainsKey('Metadata')) {
                                    $entry.Value['Metadata'] = New-Object -TypeName PSCustomObject
                                }

                                if (-not (Get-Member -InputObject $entry.Value['Metadata'] -Name 'ClientSideFilter')) {
                                    $clientSideFilter = New-Object -TypeName PSCustomObject
                                    # Use the current command for server-side results
                                    Add-Member -InputObject $clientSideFilter -Name 'ServerSideResultCommand' -Value '.' -MemberType NoteProperty
                                    # Use the list operation ID
                                    Add-Member -InputObject $clientSideFilter -Name 'ServerSideResultParameterSet' -Value $listOperationId -MemberType NoteProperty
                                    # Use the get operation ID
                                    Add-Member -InputObject $clientSideFilter -Name 'ClientSideParameterSet' -Value $getOperationId -MemberType NoteProperty
                                    # Create a wildcard filter for the Name parameter
                                    $nameWildcardFilter = New-Object -TypeName PSCustomObject
                                    Add-Member -InputObject $nameWildcardFilter -Name 'Type' -Value 'powershellWildcard' -MemberType NoteProperty
                                    Add-Member -InputObject $nameWildcardFilter -Name 'Parameter' -Value $nameParameterNormalName -MemberType NoteProperty
                                    Add-Member -InputObject $nameWildcardFilter -Name 'Property' -Value 'Name' -MemberType NoteProperty
                                    $filters = @($nameWildcardFilter)
                                    Add-Member -InputObject $clientSideFilter -Name 'Filters' -Value $filters -MemberType NoteProperty
                                    $allClientSideFilters = @($clientSideFilter)
                                    Add-Member -InputObject $entry.Value['Metadata'] -Name 'ClientSideFilters' -Value $allClientSideFilters -MemberType NoteProperty
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    $FullClrAssemblyFilePath = $null
    if ($AssemblyFileName) {
        $FullClrAssemblyFilePath = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'fullclr' | Join-Path -ChildPath $AssemblyFileName
        if (-not (Test-Path -Path $FullClrAssemblyFilePath -PathType Leaf)) {
            $message = $LocalizedData.PathNotFound -f $FullClrAssemblyFilePath
            Write-Error -Message $message -ErrorId AssemblyNotFound
            return
        }
    }
    else {
        $ConvertToCsharpCode_params = @{
            SwaggerDict             = $swaggerDict
            SwaggerMetaDict         = $swaggerMetaDict
            PowerShellCorePath      = $PowerShellCorePath
            InstallToolsForAllUsers = $InstallToolsForAllUsers
            UserConsent             = $userConsent
            TestBuild               = $TestBuild
            NoAssembly              = $NoAssembly
            SymbolPath              = $SymbolPath
        }
        $AssemblyGenerationResult = ConvertTo-CsharpCode @ConvertToCsharpCode_params
        if (-not $AssemblyGenerationResult) {
            return
        }
        $FullClrAssemblyFilePath = $AssemblyGenerationResult['FullClrAssemblyFilePath']
    }

    $NameSpace = $SwaggerDict['info'].NameSpace
    $FullClientTypeName = $Namespace + '.' + $SwaggerDict['Info'].ClientTypeName
    $updateResult = Update-PathFunctionDetails -PathFunctionDetails $PathFunctionDetails -DefinitionFunctionDetails $DefinitionFunctionsDetails -FullClientTypeName $FullClientTypeName -Namespace $Namespace -Models $Models
    if (-not $updateResult) {
        return
    }

    $PathFunctionDetails = $updateResult['PathFunctionDetails']
    $ConstructorInfo = $updateResult['ConstructorInfo']
    $ConstructorInfo.GetEnumerator() | ForEach-Object {
        $DefinitionFunctionsDetails[$_.Name]['NonDefaultConstructor'] = $_.Value
    }

    # Need to expand the definitions early as parameter flattening feature requires the parameters list of the definition/model types.
    Expand-SwaggerDefinition -DefinitionFunctionsDetails $DefinitionFunctionsDetails -NameSpace $NameSpace -Models $Models

    $HeaderContent = Get-HeaderContent -SwaggerDict $SwaggerDict -ErrorVariable ev
    if ($ev) {
        return
    }
    $PSHeaderComment = $null
    if ($HeaderContent) {
        $PSHeaderComment = ($PSCommentFormatString -f $HeaderContent)
    }

    $FunctionsToExport = @()
    $FunctionsToExport += New-SwaggerSpecPathCommand -PathFunctionDetails $PathFunctionDetails `
        -SwaggerMetaDict $swaggerMetaDict `
        -SwaggerDict $swaggerDict `
        -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
        -PSHeaderComment $PSHeaderComment `
        -Formatter $Formatter `
        -PowerShellCodeGen $PowerShellCodeGen

    $FunctionsToExport += New-SwaggerDefinitionCommand -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
        -SwaggerMetaDict $swaggerMetaDict `
        -NameSpace $nameSpace `
        -Models $models `
        -HeaderContent $HeaderContent `
        -Formatter $Formatter

    $RootModuleFilePath = Join-Path $outputDirectory "$Name.psm1"
    $testCoreModuleRequirements = ''
    $testFullModuleRequirements = ''
    if ($UseAzureCSharpGenerator) {
        $testCoreModuleRequirements = '. (Join-Path -Path $PSScriptRoot "Test-CoreRequirements.ps1")' + [Environment]::NewLine + "    "
        $testFullModuleRequirements = '. (Join-Path -Path $PSScriptRoot "Test-FullRequirements.ps1")' + [Environment]::NewLine + "    "
    }

    $DynamicAssemblyGenerationCode = $null
    if ($AssemblyFileName) {
        $DllFileName = $AssemblyFileName
    }
    else {
        $DllFileName = "$Namespace.dll"
        $DynamicAssemblyGenerationCode = $ExecutionContext.InvokeCommand.ExpandString($DynamicAssemblyGenerationBlock)
    }

    Out-File -FilePath $RootModuleFilePath `
        -InputObject @($PSHeaderComment, $ExecutionContext.InvokeCommand.ExpandString($RootModuleContents))`
        -Encoding ascii `
        -Force `
        -Confirm:$false `
        -WhatIf:$false

    New-ModuleManifestUtility -Path $outputDirectory `
        -FunctionsToExport $FunctionsToExport `
        -Info $swaggerDict['info'] `
        -PSHeaderComment $PSHeaderComment

    $CopyFilesMap = [ordered]@{
        'Get-TaskResult.ps1'        = 'Get-TaskResult.ps1'
        'Get-ApplicableFilters.ps1' = 'Get-ApplicableFilters.ps1'
        'Test-FilteredResult.ps1'   = 'Test-FilteredResult.ps1'
    }
    if ($UseAzureCsharpGenerator) {
        $CopyFilesMap['New-ArmServiceClient.ps1'] = 'New-ServiceClient.ps1'
        $CopyFilesMap['Test-FullRequirements.ps1'] = 'Test-FullRequirements.ps1'
        $CopyFilesMap['Test-CoreRequirements.ps1'] = 'Test-CoreRequirements.ps1'
        $CopyFilesMap['Get-ArmResourceIdParameterValue.ps1'] = 'Get-ArmResourceIdParameterValue.ps1'
    }
    else {
        $CopyFilesMap['New-ServiceClient.ps1'] = 'New-ServiceClient.ps1'        
    }

    if (-not $AssemblyFileName) {
        $CopyFilesMap['AssemblyGenerationHelpers.ps1'] = 'AssemblyGenerationHelpers.ps1'
        $CopyFilesMap['AssemblyGenerationHelpers.Resources.psd1'] = 'AssemblyGenerationHelpers.Resources.psd1'
    }

    $CopyFilesMap.GetEnumerator() | ForEach-Object {
        Copy-PSFileWithHeader -SourceFilePath (Join-Path -Path "$PSScriptRoot" -ChildPath $_.Name) `
            -DestinationFilePath (Join-Path -Path "$outputDirectory" -ChildPath $_.Value) `
            -PSHeaderComment $PSHeaderComment
    }

    if ($CopyUtilityModuleToOutput) {
        Write-Verbose -Message $LocalizedData.CopyingUtilityModule
        $utilityModuleInfo = Get-Module PSSwaggerUtility
        $existingPath = (Join-Path -Path $outputDirectory -ChildPath PSSwaggerUtility)
        Write-Warning -Message ($LocalizedData.ReSignUtilityModuleWarning -f $existingPath)
        if (Test-Path -Path $existingPath) {
            $null = Remove-Item -Path $existingPath -Recurse -Force
        }

        $null = New-Item -Path $existingPath -ItemType Directory -Force
        foreach ($item in Get-ChildItem -Path $utilityModuleInfo.ModuleBase) {
            $filePath = $item.FullName
            if ($item.Name -eq 'PSSwaggerClientTracing.psm1') {
                Write-Warning -Message $LocalizedData.TracingDisabled
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath 'PSSwaggerClientTracing_Dummy.psm1'
            } 
            elseif ($item.Name -eq 'PSSwaggerServiceCredentialsHelpers.psm1') {
                Write-Warning -Message $LocalizedData.CredentialsDisabled
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath 'PSSwaggerServiceCredentialsHelpers_Dummy.psm1'
            }
            elseif (($item.Name -eq 'PSSwaggerNetUtilities.Code.ps1') -or ($item.Name -eq 'PSSwaggerNetUtilities.Unsafe.Code.ps1')) {
                $filePath = $null
            }

            if ($filePath) {
                $content = Remove-AuthenticodeSignatureBlock -Path $filePath
                if ($item.Name -eq 'PSSwaggerUtility.Resources.psd1') {
                    $namespaceIndex = $content | Select-String -Pattern "CSharpNamespace=Microsoft.PowerShell.Commands.PSSwagger"
                    $content[$namespaceIndex.LineNumber - 1] = "    CSharpNamespace=$($SwaggerDict['info'].NameSpace)"
                }

                $content | Out-File -FilePath (Join-Path -Path $existingPath -ChildPath $item.Name) -Encoding ASCII -Force
            }
        }
    }

    Write-Verbose -Message ($LocalizedData.SuccessfullyGeneratedModule -f $Name, $outputDirectory)
}

#region Module Generation Helpers

function Update-PathFunctionDetails {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $PathFunctionDetails,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $DefinitionFunctionDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $Namespace,

        [Parameter(Mandatory = $true)]
        [string]
        $Models,

        [Parameter(Mandatory = $true)]
        [string]
        $FullClientTypeName
    )

    $cliXmlTmpPath = Get-TemporaryCliXmlFilePath -FullClientTypeName $FullClientTypeName

    try {
        $metadataExtractionParameters = @{
            'PathFunctionDetails' = $PathFunctionDetails
            'DefinitionFunctionDetails' = $DefinitionFunctionDetails
            'Namespace' = $Namespace
            'Models' = $Models
        }
        Export-CliXml -InputObject $metadataExtractionParameters -Path $cliXmlTmpPath
        $PathsPsm1FilePath = Join-Path -Path $PSScriptRoot -ChildPath Paths.psm1
        $command = @"
            Add-Type -Path '$FullClrAssemblyFilePath'
            Import-Module -Name '$PathsPsm1FilePath' -DisableNameChecking
            Set-ExtendedCodeMetadata -MainClientTypeName '$FullClientTypeName' -CliXmlTmpPath '$cliXmlTmpPath'
"@
        $null = & PowerShell.exe -command "& {$command}"

        $codeReflectionResult = Import-CliXml -Path $cliXmlTmpPath
        if ($codeReflectionResult.ContainsKey('VerboseMessages') -and
            $codeReflectionResult.VerboseMessages -and
            ($codeReflectionResult.VerboseMessages.Count -gt 0)) {
            $verboseMessages = $codeReflectionResult.VerboseMessages -Join [Environment]::NewLine
            Write-Verbose -Message $verboseMessages
        }

        if ($codeReflectionResult.ContainsKey('WarningMessages') -and
            $codeReflectionResult.WarningMessages -and
            ($codeReflectionResult.WarningMessages.Count -gt 0)) {
            $warningMessages = $codeReflectionResult.WarningMessages -Join [Environment]::NewLine
            Write-Warning -Message $warningMessages
        }

        if (-not $codeReflectionResult.Result -or 
            $codeReflectionResult.ErrorMessages.Count -gt 0) {
            $errorMessage = (, ($LocalizedData.MetadataExtractFailed) + 
                $codeReflectionResult.ErrorMessages) -Join [Environment]::NewLine
            Write-Error -Message $errorMessage -ErrorId 'UnableToExtractDetailsFromSdkAssembly'
            return
        }

        return $codeReflectionResult.Result
    }
    finally {
        if (Test-Path -Path $cliXmlTmpPath -PathType Leaf) {
            $null = Remove-Item -Path $cliXmlTmpPath -Force -WhatIf:$false -Confirm:$false
        }
    }
}

function ConvertTo-CsharpCode {
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerDict,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $SwaggerMetaDict,

        [Parameter()]
        [string]
        $PowerShellCorePath,

        [Parameter()]
        [switch]
        $InstallToolsForAllUsers,

        [Parameter()]
        [switch]
        $UserConsent,

        [Parameter()]
        [switch]
        $TestBuild,

        [Parameter()]
        [switch]
        $NoAssembly,

        [Parameter()]
        [string]
        $SymbolPath
    )

    Write-Verbose -Message $LocalizedData.GenerateCodeUsingAutoRest
    $info = $SwaggerDict['Info']    

    $AutoRestCommand = Get-Command -Name AutoRest -ErrorAction Ignore | Select-Object -First 1 -ErrorAction Ignore
    if (-not $AutoRestCommand) {
        throw $LocalizedData.AutoRestNotInPath
    }

    if (-not (Get-OperatingSystemInfo).IsCore) {
        if (-not (Get-Command -Name 'Csc.Exe' -ErrorAction Ignore)) {
            throw $LocalizedData.CscExeNotInPath
        }

        $csc = Get-Command -Name 'Csc.Exe'
        # The compiler Roslyn compiler is managed while the in-box compiler is native
        # There's a better way to read the PE header using seeks but this is fine
        [byte[]]$data = New-Object -TypeName byte[] -ArgumentList 4096
        $fs = [System.IO.File]::OpenRead($csc.Source)
        try {
            $null = $fs.Read($data, 0, 4096)
        }
        finally {
            $fs.Dispose()
        }

        # Last 4 bytes of the 64-byte IMAGE_DOS_HEADER is pointer to IMAGE_NT_HEADER
        $p_inh = [System.BitConverter]::ToUInt32($data, 60)
        # Skip past 4 byte signature + 20 byte IMAGE_FILE_HEADER to get to IMAGE_OPTIONAL_HEADER
        $p_ioh = $p_inh + 24
        # Grab the magic header to determine 32-bit or 64-bit
        $magic = [System.BitConverter]::ToUInt16($data, [int]$p_ioh)
        if ($magic -eq 0x20b) {
            # Skip to the end of IMAGE_OPTIONAL_HEADER64 to the first entry in the data directory array
            $p_dataDirectory0 = [System.BitConverter]::ToUInt32($data, [int]$p_ioh + 224)
        }
        else {
            # Same thing, but for IMAGE_OPTIONAL_HEADER32
            $p_dataDirectory0 = [System.BitConverter]::ToUInt32($data, [int]$p_ioh + 208)
        }

        if ($p_dataDirectory0 -eq 0) {
            # If there is no entry, this is a native exe
            # That means this is the in-box csc, which is not supported
            throw $LocalizedData.IncorrectVersionOfCscExeInPath
        }
    }

    $outputDirectory = $SwaggerMetaDict['outputDirectory']
    $nameSpace = $info.NameSpace
    $generatedCSharpPath = Join-Path -Path $outputDirectory -ChildPath "Generated.Csharp"
    $codeGenerator = "CSharp"

    if ($SwaggerMetaDict['UseAzureCsharpGenerator']) { 
        $codeGenerator = "Azure.CSharp"
    }

    $clrPath = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'fullclr'
    if (-not (Test-Path -Path $clrPath)) {
        $null = New-Item -Path $clrPath -ItemType Directory -Force -Confirm:$false -WhatIf:$false
    }

    $outAssembly = "$NameSpace.dll"
    # Delete the previously generated assembly, even if -NoAssembly is specified
    if (Test-Path -Path (Join-Path -Path $clrPath -ChildPath $outAssembly)) {
        $null = Remove-Item -Path (Join-Path -Path $clrPath -ChildPath $outAssembly) -Force
    }

    # Clean old generated code for when operations change or the command is re-run (Copy-Item can't clobber)
    # Note that we don't need to require this as empty as this folder is generated by PSSwagger, not a user folder
    if (Test-Path -Path $generatedCSharpPath) {
        $null = Remove-Item -Path $generatedCSharpPath -Recurse -Force
    }

    if ($NoAssembly) {
        $outAssembly = ''
    }

    $result = @{
        GeneratedCSharpPath     = $generatedCSharpPath
        FullClrAssemblyFilePath = ''
        CoreClrAssemblyFilePath = ''
    }

    $tempCodeGenSettingsPath = ''
    # Latest AutoRest inconsistently appends 'Client' to the specified infoName to generated the client name.
    # We need to override the client name to ensure that generated PowerShell cmdlets work fine.
    # Note: -ClientName doesn't seem to work for legacy invocation
    $ClientName = $info['ClientTypeName']
    try {
        if ($info.ContainsKey('CodeGenFileRequired') -and $info.CodeGenFileRequired) {
            # Some settings need to be overwritten
            # Write the following parameters: AddCredentials, CodeGenerator, Modeler
            $tempCodeGenSettings = @{
                AddCredentials = $true
                CodeGenerator  = $codeGenerator
                Modeler        = $swaggerMetaDict['AutoRestModeler']
                ClientName     = $ClientName
            }

            $tempCodeGenSettingsPath = "$(Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath (Get-Random)).json"
            $tempCodeGenSettings | ConvertTo-Json | Out-File -FilePath $tempCodeGenSettingsPath

            $autoRestParams = @('-Input', $swaggerMetaDict['SwaggerSpecPath'], '-OutputDirectory', $generatedCSharpPath, '-Namespace', $NameSpace, '-CodeGenSettings', $tempCodeGenSettingsPath)
        }
        elseif ( ($AutoRestCommand.Name -eq 'AutoRest.exe') -or 
            ($swaggerMetaDict['AutoRestModeler'] -eq 'CompositeSwagger')) {
            # None of the PSSwagger-required params are being overwritten, just call the CLI directly to avoid the extra disk op
            $autoRestParams = @('-Input', $swaggerMetaDict['SwaggerSpecPath'], 
                '-OutputDirectory', $generatedCSharpPath, 
                '-Namespace', $NameSpace, 
                '-AddCredentials', $true, 
                '-CodeGenerator', $codeGenerator, 
                '-ClientName', $ClientName
                '-Modeler', $swaggerMetaDict['AutoRestModeler'] 
            )
        }
        else {
            # See https://aka.ms/autorest/cli for AutoRest.cmd options.
            $autoRestParams = @(
                "--input-file=$($swaggerMetaDict['SwaggerSpecPath'])",
                "--output-folder=$generatedCSharpPath",
                "--namespace=$NameSpace",
                '--add-credentials',
                '--clear-output-folder=true',
                "--override-client-name=$ClientName"
                '--verbose',
                '--csharp'
            )

            if ($codeGenerator -eq 'Azure.CSharp') {
                $autoRestParams += '--azure-arm'
            }

            if (('continue' -eq $DebugPreference) -or 
                ('inquire' -eq $DebugPreference)) {
                $autoRestParams += '--debug'
            }            
        }

        Write-Verbose -Message $LocalizedData.InvokingAutoRestWithParams
        Write-Verbose -Message $($autoRestParams | Out-String)
        $autorestMessages = & AutoRest $autoRestParams
        if ($autorestMessages) {
            Write-Verbose -Message $($autorestMessages | Out-String)
        }
        if ($LastExitCode) {
            Write-Error -Message $LocalizedData.AutoRestError -ErrorId 'SourceCodeGenerationError'
            return
        }
    }
    finally {
        if ($tempCodeGenSettingsPath -and (Test-Path -Path $tempCodeGenSettingsPath)) {
            $null = Remove-Item -Path $tempCodeGenSettingsPath -Force -ErrorAction Ignore
        }
    }

    Write-Verbose -Message $LocalizedData.GenerateAssemblyFromCode
    if ($info.ContainsKey('CodeOutputDirectory') -and $info.CodeOutputDirectory) {
        $null = Copy-Item -Path $info.CodeOutputDirectory -Destination $generatedCSharpPath -Filter "*.cs" -Recurse -ErrorAction Ignore
    }

    $allCSharpFiles = Get-ChildItem -Path "$generatedCSharpPath\*.cs" `
        -Recurse `
        -File `
        -Exclude Program.cs, TemporaryGeneratedFile* |
        Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    $allCodeFiles = @()
    foreach ($file in $allCSharpFiles) {
        $newFileName = Join-Path -Path $file.Directory -ChildPath "$($file.BaseName).Code.ps1"
        $null = Move-Item -Path $file.FullName -Destination $newFileName -Force
        $allCodeFiles += $newFileName
    }
    
    $allCSharpFilesArrayString = "@('" + $($allCodeFiles -join "','") + "')"
    # Compile full CLR (PSSwagger requires to be invoked from full PowerShell)
    $codeCreatedByAzureGenerator = [bool]$SwaggerMetaDict['UseAzureCsharpGenerator']

    $dependencies = Get-PSSwaggerExternalDependencies -Azure:$codeCreatedByAzureGenerator -Framework 'net4'
    $microsoftRestClientRuntimeAzureRequiredVersion = if ($dependencies.ContainsKey('Microsoft.Rest.ClientRuntime.Azure')) { $dependencies['Microsoft.Rest.ClientRuntime.Azure'].RequiredVersion } else { '' }
    
    if (-not $OutAssembly) {
        $TempGuid = [Guid]::NewGuid().Guid
        if (-not $OutAssembly) {
            $OutAssembly = "$TempGuid.dll"
        }
        $ClrPath = Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath ([Guid]::NewGuid().Guid)
        $null = New-Item -Path $ClrPath -ItemType Directory -Force -WhatIf:$false -Confirm:$false
    }

    $AddPSSwaggerClientType_params = @{
        OutputAssemblyName                             = $outAssembly
        ClrPath                                        = $clrPath
        CSharpFiles                                    = $allCodeFiles
        CodeCreatedByAzureGenerator                    = $codeCreatedByAzureGenerator
        MicrosoftRestClientRuntimeAzureRequiredVersion = $microsoftRestClientRuntimeAzureRequiredVersion
        MicrosoftRestClientRuntimeRequiredVersion      = $dependencies['Microsoft.Rest.ClientRuntime'].RequiredVersion
        NewtonsoftJsonRequiredVersion                  = $dependencies['Newtonsoft.Json'].RequiredVersion
        AllUsers                                       = $InstallToolsForAllUsers
        BootstrapConsent                               = $UserConsent
        TestBuild                                      = $TestBuild
        SymbolPath                                     = $SymbolPath
    }

    if (-not (PSSwaggerUtility\Add-PSSwaggerClientType @AddPSSwaggerClientType_params)) {
        $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
        Write-Error -ErrorId 'UnableToGenerateAssembly' -Message $message
        return
    }

    $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
    Write-Verbose -Message $message
    $result['FullClrAssemblyFilePath'] = Join-Path -Path $ClrPath -ChildPath $OutAssembly

    # If we're not going to save the assembly, no need to generate the core CLR one now
    if ($PowerShellCorePath -and (-not $NoAssembly)) {
        if (-not $outAssembly) {
            $outAssembly = "$NameSpace.dll"
        }

        # Compile core CLR
        $clrPath = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'coreclr'
        if (Test-Path (Join-Path -Path $outputDirectory -ChildPath $outAssembly)) {
            $null = Remove-Item -Path $outAssembly -Force
        }

        if (-not (Test-Path -Path $clrPath)) {
            $null = New-Item $clrPath -ItemType Directory -Force -Confirm:$false -WhatIf:$false
        }
        $dependencies = Get-PSSwaggerExternalDependencies -Azure:$codeCreatedByAzureGenerator -Framework 'netstandard1'
        $microsoftRestClientRuntimeAzureRequiredVersion = if ($dependencies.ContainsKey('Microsoft.Rest.ClientRuntime.Azure')) { $dependencies['Microsoft.Rest.ClientRuntime.Azure'].RequiredVersion } else { '' }

        # In some cases, PSCore doesn't inherit this process's PSModulePath
        $command = @"
            `$env:PSModulePath += ';$env:PSModulePath'
            `$AddPSSwaggerClientType_params = @{
                OutputAssemblyName                             = '$outAssembly'
                ClrPath                                        = '$clrPath'
                CSharpFiles                                    = $allCSharpFilesArrayString
                MicrosoftRestClientRuntimeAzureRequiredVersion = '$microsoftRestClientRuntimeAzureRequiredVersion'
                MicrosoftRestClientRuntimeRequiredVersion      = '$($dependencies['Microsoft.Rest.ClientRuntime'].RequiredVersion)'
                NewtonsoftJsonRequiredVersion                  = '$($dependencies['Newtonsoft.Json'].RequiredVersion)'
                CodeCreatedByAzureGenerator                    = `$$codeCreatedByAzureGenerator
                BootstrapConsent                               = `$$UserConsent
            }
            PSSwaggerUtility\Add-PSSwaggerClientType @AddPSSwaggerClientType_params
"@
        $success = & "$PowerShellCorePath" -command "& {$command}"
        if ((Test-AssemblyCompilationSuccess -Output ($success | Out-String))) {
            $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
            Write-Verbose -Message $message
        }
        else {
            $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
            Write-Error -ErrorId 'UnableToGenerateCoreClrAssembly' -Message $message
            return
        }
        $result['CoreClrAssemblyFilePath'] = Join-Path -Path $ClrPath -ChildPath $OutAssembly
    }

    return $result
}

function Test-AssemblyCompilationSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Output
    )

    Write-Verbose -Message ($LocalizedData.AssemblyCompilationResult -f ($Output))
    $tokens = $Output.Split(' ')
    return ($tokens[$tokens.Count - 1].Trim().EndsWith('True'))
}

function New-ModuleManifestUtility {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string[]]
        $FunctionsToExport,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $Info,
        
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PSHeaderComment
    )

    $FormatsToProcess = Get-ChildItem -Path "$Path\$GeneratedCommandsName\FormatFiles\*.ps1xml" `
        -File `
        -ErrorAction Ignore | Foreach-Object { $_.FullName.Replace($Path, '.') }
                                      
    $ModuleManifestFilePath = "$(Join-Path -Path $Path -ChildPath $Info.ModuleName).psd1"
    $NewModuleManifest_params = @{
        Path              = $ModuleManifestFilePath
        ModuleVersion     = $Info.Version
        Description       = $Info.Description
        CopyRight         = $info.LicenseName
        Author            = $info.ContactEmail
        NestedModules     = @('PSSwaggerUtility')
        RootModule        = "$($Info.ModuleName).psm1"
        FormatsToProcess  = $FormatsToProcess
        FunctionsToExport = $FunctionsToExport
        CmdletsToExport   = @()
        AliasesToExport   = @()
        VariablesToExport = @()
        PassThru          = $true
    }

    if ($Info.DefaultCommandPrefix) {
        $NewModuleManifest_params['DefaultCommandPrefix'] = $Info.DefaultCommandPrefix
    }

    if ($PSVersionTable.PSVersion -ge '5.0.0') {
        # Below parameters are not available on PS 3 and 4 versions.
        if ($Info.ProjectUri) {
            $NewModuleManifest_params['ProjectUri'] = $Info.ProjectUri
        }

        if ($Info.LicenseUri) {
            $NewModuleManifest_params['LicenseUri'] = $Info.LicenseUri
        }
    }

    $PassThruContent = New-ModuleManifest @NewModuleManifest_params
    
    # Add header comment
    if ($PSHeaderComment) {
        Out-File -FilePath $ModuleManifestFilePath `
            -InputObject @($PSHeaderComment, $PassThruContent)`
            -Encoding ascii `
            -Force `
            -Confirm:$false `
            -WhatIf:$false
    }
}

function Get-HeaderContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $SwaggerDict
    )

    $Header = $swaggerDict['Info'].Header
    $HeaderContent = ($DefaultGeneratedFileHeader -f $MyInvocation.MyCommand.Module.Version)
    if ($Header) {
        switch ($Header) {
            'MICROSOFT_MIT' {
                return $MicrosoftMitLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $HeaderContent
            }
            'MICROSOFT_MIT_NO_VERSION' {
                return $MicrosoftMitLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderWithoutVersion
            }
            'MICROSOFT_MIT_NO_CODEGEN' {
                return $MicrosoftMitLicenseHeader
            }
            'MICROSOFT_APACHE' {
                return $MicrosoftApacheLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $HeaderContent
            }
            'MICROSOFT_APACHE_NO_VERSION' {
                return $MicrosoftApacheLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderWithoutVersion
            }
            'MICROSOFT_APACHE_NO_CODEGEN' {
                return $MicrosoftApacheLicenseHeader
            }
            'NONE' {
                return ''
            }
        }
        
        $HeaderFilePath = Resolve-Path -Path $Header -ErrorAction Ignore
        if ($HeaderFilePath) {
            # Selecting the first path when multiple paths are returned by Resolve-Path cmdlet.
            if ($HeaderFilePath.PSTypeNames -contains 'System.Array') {
                $HeaderFilePath = $HeaderFilePath[0]
            }

            if (-not $HeaderFilePath.Path.EndsWith('.txt', [System.StringComparison]::OrdinalIgnoreCase)) {
                $message = ($LocalizedData.InvalidHeaderFileExtension -f $Header)
                Write-Error -Message $message -ErrorId 'InvalidHeaderFileExtension' -Category InvalidArgument
                return
            }

            if (-not (Test-Path -LiteralPath $HeaderFilePath -PathType Leaf)) {
                $message = ($LocalizedData.InvalidHeaderFilePath -f $Header)
                Write-Error -Message $message -ErrorId 'InvalidHeaderFilePath' -Category InvalidArgument
                return    
            }
            
            $HeaderContent = Get-Content -LiteralPath $HeaderFilePath -Raw
        }
        elseif ($Header.EndsWith('.txt', [System.StringComparison]::OrdinalIgnoreCase)) {
            # If this is an existing '.txt' file above Resolve-Path returns a valid header file path
            $message = ($LocalizedData.PathNotFound -f $Header)
            Write-Error -Message $message -ErrorId 'HeaderFilePathNotFound' -Category InvalidArgument
            return
        }
        else {
            $HeaderContent = $Header
        }
    }

    # Escape block comment character sequence, if any, using the PowerShell escape character, grave-accent(`).
    $HeaderContent = $HeaderContent.Replace('<#', '<`#').Replace('#>', '#`>')

    if ($HeaderContent -match '--') {
        Write-Warning -Message $LocalizedData.HeaderContentTwoHyphenWarning
        $HeaderContent = $HeaderContent.Replace('--', '==')
    }

    return $HeaderContent
}

function Copy-PSFileWithHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $SourceFilePath,

        [Parameter(Mandatory = $true)]
        [string]
        $DestinationFilePath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PSHeaderComment
    )

    if (-not (Test-Path -Path $SourceFilePath -PathType Leaf)) {
        Throw ($LocalizedData.PathNotFound -f $SourceFilePath)
    }

    $FileContent = Get-Content -Path $SourceFilePath -Raw
    Out-File -FilePath $DestinationFilePath `
        -InputObject @($PSHeaderComment, $FileContent)`
        -Encoding ascii `
        -Force `
        -Confirm:$false `
        -WhatIf:$false
}

#endregion

Export-ModuleMember -Function New-PSSwaggerModule, New-PSSwaggerMetadataFile