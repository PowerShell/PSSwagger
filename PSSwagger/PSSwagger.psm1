#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
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
    'PSSwagger.Common.Helpers',
    'SwaggerUtils.psm1',
    'Utilities.psm1',
    'Paths.psm1',
    'Definitions.psm1'
)

$SubModules | ForEach-Object {Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $_) -Force -Scope Local -DisableNameChecking}

Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

<#
.DESCRIPTION
  Decodes the swagger spec and generates PowerShell cmdlets.

.PARAMETER  SwaggerSpecPath
  Full Path to a Swagger based JSON spec.

.PARAMETER  Path
  Full Path to a file where the commands are exported to.

.PARAMETER  Name
  Name of the generated PowerShell module.

.PARAMETER  Version
  Version of the generated PowerShell module.

.PARAMETER  DefaultCommandPrefix
  Prefix value to be prepended to cmdlet noun or to cmdlet name without verb.

.PARAMETER  NoAssembly
  Switch to disable saving the precompiled module assembly and instead enable dynamic compilation.

.PARAMETER  PowerShellCorePath
  Path to PowerShell.exe for PowerShell Core.

.PARAMETER  IncludeCoreFxAssembly
  Switch to additionally compile the module's binary component for core CLR.

.PARAMETER  InstallToolsForAllUsers
  User wants to install local tools for all users.
  
.PARAMETER  TestBuild
  Switch to disable optimizations during build of full CLR binary component.

.PARAMETER  SymbolPath
  Path to save generated C# code and PDB file. Defaults to $Path\symbols

.PARAMETER  ConfirmBootstrap
  Automatically consent to downloading nuget.exe or NuGet packages as required.
#>
function New-PSSwaggerModule
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerPath')]
        [string] 
        $SwaggerSpecPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerURI')]
        [Uri]
        $SwaggerSpecUri,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [Version]
        $Version = '0.0.1',

        [Parameter(Mandatory = $false)]
        [string]
        $DefaultCommandPrefix,

        [Parameter()]
        [switch]
        $UseAzureCsharpGenerator,

        [Parameter()]
        [switch]
        $NoAssembly,

        [Parameter()]
        [string]
        $PowerShellCorePath,

        [Parameter()]
        [switch]
        $IncludeCoreFxAssembly,

        [Parameter()]
        [switch]
        $InstallToolsForAllUsers,

        [Parameter()]
        [switch]
        $TestBuild,

        [Parameter()]
        [string]
        $SymbolPath,

        [Parameter()]
        [switch]
        $ConfirmBootstrap,

        [Parameter()]
        [string]
        $TempMetadataFile
    )

    $tempMetadata = [PSCustomObject]@{}
    if ($TempMetadataFile -and (Test-Path -Path $TempMetadataFile)) {
        Write-Verbose -Message "Using temporary implementation of metadata file."
        $tempMetadata = Get-Content -Path $TempMetadataFile | ConvertFrom-Json
    }

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
    
    if ($PSCmdlet.ParameterSetName -eq 'SwaggerURI')
    {
        # Ensure that if the URI is coming from github, it is getting the raw content
        if($SwaggerSpecUri.Host -eq 'github.com'){
            $SwaggerSpecUri = "https://raw.githubusercontent.com$($SwaggerSpecUri.AbsolutePath.Replace('/blob/','/'))"
            $message = $LocalizedData.ConvertingSwaggerSpecToGithubContent -f ($SwaggerSpecUri)
            Write-Verbose -Message $message -Verbose
        }

        $TempPath = Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath (Get-Random)
        $null = New-Item -Path $TempPath -ItemType Directory -Force -Confirm:$false -WhatIf:$false

        $SwaggerFileName = Split-Path -Path $SwaggerSpecUri -Leaf
        $SwaggerSpecPath = Join-Path -Path $TempPath -ChildPath $SwaggerFileName

        $message = $LocalizedData.SwaggerSpecDownloadedTo -f ($SwaggerSpecUri, $SwaggerSpecPath)
        Write-Verbose -Message $message
        
        $ev = $null
        Invoke-WebRequest -Uri $SwaggerSpecUri -OutFile $SwaggerSpecPath -ErrorVariable ev
        if($ev) {
            return 
        }

        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
        if((Get-Member -InputObject $jsonObject -Name 'Documents') -and ($jsonObject.Documents.Count))
        {
            $AutoRestModeler = 'CompositeSwagger'
            $BaseSwaggerUri = "$SwaggerSpecUri".Substring(0, "$SwaggerSpecUri".LastIndexOf('/'))
            foreach($document in $jsonObject.Documents)
            {
                $FileName = Split-Path -Path $document -Leaf
                $DocumentFolderPrefix = (Split-Path -Path $document -Parent).Replace('/', [System.IO.Path]::DirectorySeparatorChar).TrimStart('.')
                
                $DocumentFolderPath = Join-Path -Path $TempPath -ChildPath $DocumentFolderPrefix

                if(-not (Test-Path -LiteralPath $DocumentFolderPath -PathType Container))
                {
                    $null = New-Item -Path $DocumentFolderPath -ItemType Container -Force -Confirm:$false -WhatIf:$false
                }
                $SwaggerDocumentPath = Join-Path -Path $DocumentFolderPath -ChildPath $FileName

                $ev = $null
                Invoke-WebRequest -Uri $($BaseSwaggerUri + $($document.replace('\','/').TrimStart('.'))) -OutFile $SwaggerDocumentPath -ErrorVariable ev
                if($ev) {
                    return 
                }
                $SwaggerSpecFilePaths += $SwaggerDocumentPath
            }
        }
        else
        {
            $SwaggerSpecFilePaths += $SwaggerSpecPath
        }
    }    

    $outputDirectory = Microsoft.PowerShell.Management\Resolve-Path -Path $Path | Select-Object -First 1 -ErrorAction Ignore
    $outputDirectory = "$outputDirectory".TrimEnd('\').TrimEnd('/')
    if (-not $SymbolPath) {
        $SymbolPath = Join-Path -Path $Path -ChildPath "symbols"
    }

    if (-not $outputDirectory -or (-not (Test-path -Path $outputDirectory -PathType Container)))
    {
        throw $LocalizedData.PathNotFound -f ($Path)
        return
    }
  
    # Validate swagger path and composite swagger paths
    if (-not (Test-path -Path $SwaggerSpecPath))
    {
        throw $LocalizedData.SwaggerSpecPathNotExist -f ($SwaggerSpecPath)
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'SwaggerPath')
    {
        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
        if((Get-Member -InputObject $jsonObject -Name 'Documents') -and ($jsonObject.Documents.Count))
        {
            $AutoRestModeler = 'CompositeSwagger'
            $SwaggerBaseDir = Split-Path -Path $SwaggerSpecPath -Parent
            foreach($document in $jsonObject.Documents)
            {
                $FileName = Split-Path -Path $document -Leaf
                if(Test-Path -Path $document -PathType Leaf)
                {
                    $SwaggerSpecFilePaths += $document
                }
                elseif(Test-Path -Path (Join-Path -Path $SwaggerBaseDir -ChildPath $document) -PathType Leaf)
                {
                    $SwaggerSpecFilePaths += Join-Path -Path $SwaggerBaseDir -ChildPath $document
                }
                else {
                    throw $LocalizedData.PathNotFound -f ($document)
                    return
                }
            }
        }
        else
        {
            $SwaggerSpecFilePaths += $SwaggerSpecPath
        }
    }

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

    $userConsent = Initialize-PSSwaggerLocalTools -AllUsers:$InstallToolsForAllUsers -Azure:$UseAzureCsharpGenerator -Framework $frameworksToCheckDependencies -AcceptBootstrap:$ConfirmBootstrap

    $DefinitionFunctionsDetails = @{}

    # Parse the JSON and populate the dictionary
    $ConvertToSwaggerDictionary_params = @{
        SwaggerSpecPath = $SwaggerSpecPath
        ModuleName = $Name
        ModuleVersion = $Version
        DefaultCommandPrefix = $DefaultCommandPrefix
        SwaggerSpecFilePaths = $SwaggerSpecFilePaths
        DefinitionFunctionsDetails = $DefinitionFunctionsDetails
        AzureSpec = $UseAzureCsharpGenerator
    }
    
    $swaggerDict = ConvertTo-SwaggerDictionary -ExtendedTempMetadata ($tempMetadata) @ConvertToSwaggerDictionary_params
    $nameSpace = $swaggerDict['info'].NameSpace
    $models = $swaggerDict['info'].Models
    if($PSVersionTable.PSVersion -lt '5.0.0') {
        if (-not $outputDirectory.EndsWith($Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $Name
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $Name
        }
    } else {
        $ModuleNameandVersionFolder = Join-Path -Path $Name -ChildPath $Version

        if ($outputDirectory.EndsWith($Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleVersion
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $ModuleVersion
        } elseif (-not $outputDirectory.EndsWith($ModuleNameandVersionFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleNameandVersionFolder
            $SymbolPath = Join-Path -Path $SymbolPath -ChildPath $ModuleNameandVersionFolder
        }
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop
    $null = New-Item -ItemType Directory $SymbolPath -Force -ErrorAction Stop

    $swaggerMetaDict = @{
        OutputDirectory = $outputDirectory
        UseAzureCsharpGenerator = $UseAzureCsharpGenerator
        SwaggerSpecPath = $SwaggerSpecPath
        SwaggerSpecFilePaths = $SwaggerSpecFilePaths
        AutoRestModeler = $AutoRestModeler
        ExtendedTempMetadata = $tempMetadata
    }

    $ParameterGroupCache = @{}
    $PathFunctionDetails = @{}

    foreach($FilePath in $SwaggerSpecFilePaths) {
        $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $FilePath) -join [Environment]::NewLine) -ErrorAction Stop

        if(Get-Member -InputObject $jsonObject -Name 'Definitions') {
            # Handle the Definitions
            $jsonObject.Definitions.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecDefinitionInfo -JsonDefinitionItemObject $_ `
                                            -Namespace $Namespace `
                                            -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                            -Models $models
            }
        }

        if(Get-Member -InputObject $jsonObject -Name 'Paths') {
            # Handle the Paths
            $jsonObject.Paths.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecPathInfo -JsonPathItemObject $_ `
                                        -PathFunctionDetails $PathFunctionDetails `
                                        -SwaggerDict $swaggerDict `
                                        -SwaggerMetaDict $swaggerMetaDict `
                                        -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                        -ParameterGroupCache $ParameterGroupCache
            }
        }

        if(Get-Member -InputObject $jsonObject -Name 'x-ms-paths') {
            # Handle extended paths
            $jsonObject.'x-ms-paths'.PSObject.Properties | ForEach-Object {
                Get-SwaggerSpecPathInfo -JsonPathItemObject $_ `
                                        -PathFunctionDetails $PathFunctionDetails `
                                        -SwaggerDict $swaggerDict `
                                        -SwaggerMetaDict $swaggerMetaDict `
                                        -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                        -ParameterGroupCache $ParameterGroupCache
            }
        }
    }

    $codePhaseResult = ConvertTo-CsharpCode -SwaggerDict $swaggerDict `
                                            -SwaggerMetaDict $swaggerMetaDict `
                                            -PowerShellCorePath $PowerShellCorePath `
                                            -InstallToolsForAllUsers:$InstallToolsForAllUsers `
                                            -UserConsent:$userConsent `
                                            -TestBuild:$TestBuild `
                                            -PathFunctionDetails $PathFunctionDetails `
                                            -NoAssembly:$NoAssembly `
                                            -SymbolPath $SymbolPath

    $PathFunctionDetails = $codePhaseResult.PathFunctionDetails
    $generatedCSharpFilePath = $codePhaseResult.GeneratedCSharpPath

    $FunctionsToExport = @()
    $FunctionsToExport += New-SwaggerSpecPathCommand -PathFunctionDetails $PathFunctionDetails `
                                                     -SwaggerMetaDict $swaggerMetaDict `
                                                     -SwaggerDict $swaggerDict

    $FunctionsToExport += New-SwaggerDefinitionCommand -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                                       -SwaggerMetaDict $swaggerMetaDict `
                                                       -NameSpace $nameSpace `
                                                       -Models $models

    $RootModuleFilePath = Join-Path $outputDirectory "$Name.psm1"
    Out-File -FilePath $RootModuleFilePath `
             -InputObject $ExecutionContext.InvokeCommand.ExpandString($RootModuleContents)`
             -Encoding ascii `
             -Force `
             -Confirm:$false `
             -WhatIf:$false

    New-ModuleManifestUtility -Path $outputDirectory `
                              -FunctionsToExport $FunctionsToExport `
                              -Info $swaggerDict['info'] `
                              -UseAzureCsharpGenerator:$UseAzureCsharpGenerator

    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Generated.Resources.psd1") (Join-Path -Path "$outputDirectory" -ChildPath "$Name.Resources.psd1") -Force

    Write-Verbose -Message ($LocalizedData.SuccessfullyGeneratedModule -f $Name,$outputDirectory)
}

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

        [Parameter(Mandatory=$true)]
        [hashtable]
        $PathFunctionDetails,

        [Parameter()]
        [switch]
        $NoAssembly,

        [Parameter()]
        [string]
        $SymbolPath
    )

    Write-Verbose -Message $LocalizedData.GenerateCodeUsingAutoRest
    $info = $SwaggerDict['Info']

    $autoRestExePath = "autorest.exe"
    if (-not (get-command -name autorest.exe))
    {
        throw $LocalizedData.AutoRestNotInPath
    }

    $outputDirectory = $SwaggerMetaDict['outputDirectory']
    $nameSpace = $info.NameSpace
    $generatedCSharpPath = Join-Path -Path $outputDirectory -ChildPath "Generated.Csharp"
    $codeGenerator = "CSharp"

    if ($SwaggerMetaDict['UseAzureCsharpGenerator'])
    { 
        $codeGenerator = "Azure.CSharp"
    }

    $clrPath = Join-Path -Path $outputDirectory -ChildPath 'ref' | Join-Path -ChildPath 'fullclr'
    if (-not (Test-Path -Path $clrPath)) {
        $null = New-Item -Path $clrPath -ItemType Directory
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

    $return = @{
        GeneratedCSharpPath = $generatedCSharpPath
    }

    $tempCodeGenSettingsPath = ''
    try {
        if ($info.ContainsKey('CodeGenFileRequired') -and $info.CodeGenFileRequired) {
            # Some settings need to be overwritten
            # Write the following parameters: AddCredentials, CodeGenerator, Modeler
            $tempCodeGenSettings = @{
                AddCredentials = $true
                CodeGenerator = $codeGenerator
                Modeler = $swaggerMetaDict['AutoRestModeler']
            }

            $tempCodeGenSettingsPath = "$(Join-Path -Path (Get-XDGDirectory -DirectoryType Cache) -ChildPath (Get-Random)).json"
            $tempCodeGenSettings | ConvertTo-Json | Out-File -FilePath $tempCodeGenSettingsPath

            $autoRestParams = @('-Input', $swaggerMetaDict['SwaggerSpecPath'], '-OutputDirectory', $generatedCSharpPath, '-Namespace', $NameSpace, '-CodeGenSettings', $tempCodeGenSettingsPath)
        } else {
            # None of the PSSwagger-required params are being overwritten, just call the CLI directly to avoid the extra disk op
            $autoRestParams = @('-Input', $swaggerMetaDict['SwaggerSpecPath'], '-OutputDirectory', $generatedCSharpPath, '-Namespace', $NameSpace, '-AddCredentials', $true, '-CodeGenerator', $codeGenerator, '-Modeler', $swaggerMetaDict['AutoRestModeler'])
        }

        Write-Verbose -Message $LocalizedData.InvokingAutoRestWithParams
        for ($i = 0; $i -lt $autoRestParams.Length; $i += 2) {
            Write-Verbose -Message ($LocalizedData.AutoRestParam -f ($autoRestParams[$i], $autoRestParams[$i+1]))
        }

        $null = & $autoRestExePath $autoRestParams
        if ($LastExitCode)
        {
            throw $LocalizedData.AutoRestError
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

    $allCSharpFiles= Get-ChildItem -Path "$generatedCSharpPath\*.cs" `
                                   -Recurse `
                                   -File `
                                   -Exclude Program.cs,TemporaryGeneratedFile* |
                                        Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    $allCodeFiles = @()
    foreach ($file in $allCSharpFiles) {
        $newFileName = Join-Path -Path $file.Directory -ChildPath "$($file.BaseName).Code.ps1"
        $null = Move-Item -Path $file.FullName -Destination $newFileName -Force
        $allCodeFiles += $newFileName
    }
    
    $allCSharpFilesArrayString = "@('"+ $($allCodeFiles -join "','") + "')"
    # Compile full CLR (PSSwagger requires to be invoked from full PowerShell)
    $codeCreatedByAzureGenerator = [bool]$SwaggerMetaDict['UseAzureCsharpGenerator']

    # As of 3/2/2017, there's a version mismatch between the latest Microsoft.Rest.ClientRuntime.Azure package and the latest AzureRM.Profile package
    # So we have to hardcode Microsoft.Rest.ClientRuntime.Azure to at most version 3.3.4
    $modulePostfix = $info['infoName']
    $NameSpace = $info.namespace
    $fullModuleName = $Namespace + '.' + $modulePostfix
    $cliXmlTmpPath = Get-TemporaryCliXmlFilePath -FullModuleName $fullModuleName
    try {
        Export-CliXml -InputObject $PathFunctionDetails -Path $cliXmlTmpPath
        $dependencies = Get-PSSwaggerExternalDependencies -Azure:$codeCreatedByAzureGenerator -Framework 'net4'
        $microsoftRestClientRuntimeAzureRequiredVersion = if ($dependencies.ContainsKey('Microsoft.Rest.ClientRuntime.Azure')) { $dependencies['Microsoft.Rest.ClientRuntime.Azure'].RequiredVersion } else { '' }
        $command = "Import-Module '$PSScriptRoot\PSSwagger.Common.Helpers';
                    Invoke-PSSwaggerAssemblyCompilation  -OutputAssemblyName '$outAssembly' ``
                                                -ClrPath '$clrPath' ``
                                                -CSharpFiles $allCSharpFilesArrayString ``
                                                -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator ``
                                                -MicrosoftRestClientRuntimeAzureRequiredVersion '$microsoftRestClientRuntimeAzureRequiredVersion' ``
                                                -MicrosoftRestClientRuntimeRequiredVersion '$($dependencies['Microsoft.Rest.ClientRuntime'].RequiredVersion)' ``
                                                -NewtonsoftJsonRequiredVersion '$($dependencies['Newtonsoft.Json'].RequiredVersion)' ``
                                                -AllUsers:`$$InstallToolsForAllUsers ``
                                                -BootstrapConsent:`$$UserConsent ``
                                                -TestBuild:`$$TestBuild ``
                                                -SymbolPath $SymbolPath;
                    Import-Module `"`$(Join-Path -Path `"$PSScriptRoot`" -ChildPath `"Paths.psm1`")` -DisableNameChecking;
                    Set-ExtendedCodeMetadata -MainClientTypeName $fullModuleName ``
                                                -CliXmlTmpPath $cliXmlTmpPath"

        $success = & "powershell" -command "& {$command}"
        
        $codeReflectionResult = Import-CliXml -Path $cliXmlTmpPath
        if ($codeReflectionResult.ContainsKey('VerboseMessages') -and $codeReflectionResult.VerboseMessages -and ($codeReflectionResult.VerboseMessages.Count -gt 0)) {
            $verboseMessages = $codeReflectionResult.VerboseMessages -Join [Environment]::NewLine
            Write-Verbose -Message $verboseMessages
        }

        if ($codeReflectionResult.ContainsKey('WarningMessages') -and $codeReflectionResult.WarningMessages -and ($codeReflectionResult.WarningMessages.Count -gt 0)) {
            $warningMessages = $codeReflectionResult.WarningMessages -Join [Environment]::NewLine
            Write-Warning -Message $warningMessages
        }

        if ((Test-AssemblyCompilationSuccess -Output ($success | Out-String))) {
            $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
            Write-Verbose -Message $message
        } else {
            # This should be enough to let the user know we failed to generate their module's assembly.
            if (-not $outAssembly) {
                $outAssembly = "$NameSpace.dll"
            }

            $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
            Throw $message
        }

        if (-not $codeReflectionResult.Result -or $codeReflectionResult.ErrorMessages.Count -gt 0) {
            $errorMessage = (,($LocalizedData.MetadataExtractFailed) + 
                $codeReflectionResult.ErrorMessages) -Join [Environment]::NewLine
            throw $errorMessage
        }

        $return.PathFunctionDetails = $codeReflectionResult.Result
    } finally {
        if (Test-Path -Path $cliXmlTmpPath) {
            $null = Remove-Item -Path $cliXmlTmpPath
        }
    }
    
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
            $null = New-Item $clrPath -ItemType Directory
        }
        $dependencies = Get-PSSwaggerExternalDependencies -Azure:$codeCreatedByAzureGenerator -Framework 'netstandard1'
        $microsoftRestClientRuntimeAzureRequiredVersion = if ($dependencies.ContainsKey('Microsoft.Rest.ClientRuntime.Azure')) { $dependencies['Microsoft.Rest.ClientRuntime.Azure'].RequiredVersion } else { '' }
        $command = "Import-Module '$PSScriptRoot\PSSwagger.Common.Helpers';
                    Invoke-PSSwaggerAssemblyCompilation -OutputAssemblyName '$outAssembly' ``
                                               -ClrPath '$clrPath' ``
                                               -CSharpFiles $allCSharpFilesArrayString ``
                                               -MicrosoftRestClientRuntimeAzureRequiredVersion '$microsoftRestClientRuntimeAzureRequiredVersion' ``
                                               -MicrosoftRestClientRuntimeRequiredVersion '$($dependencies['Microsoft.Rest.ClientRuntime'].RequiredVersion)' ``
                                               -NewtonsoftJsonRequiredVersion '$($dependencies['Newtonsoft.Json'].RequiredVersion)' ``
                                               -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator ``
                                               -BootstrapConsent:`$$UserConsent"

        $success = & "$PowerShellCorePath" -command "& {$command}"
        if ((Test-AssemblyCompilationSuccess -Output ($success | Out-String))) {
            $message = $LocalizedData.GeneratedAssembly -f ($outAssembly)
            Write-Verbose -Message $message
        } else {
            $message = $LocalizedData.UnableToGenerateAssembly -f ($outAssembly)
            Throw $message
        }
    }

    return $return
}

function Test-AssemblyCompilationSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Output
    )

    Write-Verbose -Message ($LocalizedData.AssemblyCompilationResult -f ($Output))
    $tokens = $Output.Split(' ')
    return ($tokens[$tokens.Count-1].Trim().EndsWith('True'))
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

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Info,

        [Parameter()]
        [switch]
        $UseAzureCsharpGenerator
    )

    $FormatsToProcess = Get-ChildItem -Path "$Path\$GeneratedCommandsName\FormatFiles\*.ps1xml" `
                                      -File `
                                      -ErrorAction Ignore | Foreach-Object { $_.FullName.Replace($Path, '.') }

    $NewModuleManifest_params = @{
        Path = "$(Join-Path -Path $Path -ChildPath $Info.ModuleName).psd1"
        ModuleVersion = $Info.Version
        Description = $Info.Description
        CopyRight = $info.LicenseName
        Author = $info.ContactEmail
        RequiredModules = @('PSSwagger.Common.Helpers')
        RootModule = "$($Info.ModuleName).psm1"
        FormatsToProcess = $FormatsToProcess
        FunctionsToExport = $FunctionsToExport
    }

    if ($UseAzureCsharpGenerator) {
        $NewModuleManifest_params.RequiredModules += 'PSSwagger.Azure.Helpers'
    }

    if($Info.DefaultCommandPrefix)
    {
        $NewModuleManifest_params['DefaultCommandPrefix'] = $Info.DefaultCommandPrefix
    }

    if($PSVersionTable.PSVersion -ge '5.0.0')
    {
        # Below parameters are not available on PS 3 and 4 versions.
        if($Info.ProjectUri)
        {
            $NewModuleManifest_params['ProjectUri'] = $Info.ProjectUri
        }

        if($Info.LicenseUri)
        {
            $NewModuleManifest_params['LicenseUri'] = $Info.LicenseUri
        }
    }

    New-ModuleManifest @NewModuleManifest_params
}

#endregion

Export-ModuleMember -Function New-PSSwaggerModule