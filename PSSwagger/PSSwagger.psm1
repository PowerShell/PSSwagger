#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# PSSwagger Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

$SubScripts = @(
    'PSSwagger.Constants.ps1',
    'Utils.ps1'
)
$SubScripts | ForEach-Object {. (Join-Path -Path $PSScriptRoot -ChildPath $_) -Force}

$SubModules = @(
    'Generated.Azure.Common.Helpers',
    'SwaggerUtils.psm1',
    'Utilities.psm1',
    'Paths.psm1',
    'Definitions.psm1'
)
$SubModules | ForEach-Object {Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $_) -Force -Scope Local}

Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.Resources.psd1

<#
.DESCRIPTION
  Decodes the swagger spec and generates PowerShell cmdlets.

.PARAMETER  SwaggerSpecPath
  Full Path to a Swagger based JSON spec.

.PARAMETER  Path
  Full Path to a file where the commands are exported to.

.PARAMETER  ModuleName
  Name of the generated PowerShell module.

.PARAMETER  Version
  Version of the generated PowerShell module.

.PARAMETER  SkipAssemblyGeneration
  Switch to skip precompiling the module's binary component for full CLR.

.PARAMETER  PowerShellCorePath
  Path to PowerShell.exe for PowerShell Core.

.PARAMETER  IncludeCoreFxAssembly
  Switch to additionally compile the module's binary component for core CLR.

.PARAMETER  InstallToolsForAllUsers
  User wants to install local tools for all users.
#>
function New-PSSwaggerModule
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

        [Parameter(Mandatory = $false)]
        [Version]
        $Version = '0.0.1',

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
        $IncludeCoreFxAssembly,

        [Parameter()]
        [switch]
        $InstallToolsForAllUsers
    )

    if ($SkipAssemblyGeneration -and $PowerShellCorePath) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('PowerShellCorePath', 'SkipAssemblyGeneration')
        throw $message
    }

    if ($SkipAssemblyGeneration -and $IncludeCoreFxAssembly) {
        $message = $LocalizedData.ParameterSetNotAllowed -f ('IncludeCoreFxAssembly', 'SkipAssemblyGeneration')
        throw $message
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

    $userConsent = Initialize-LocalTools -Precompiling:(-not $SkipAssemblyGeneration) -AllUsers:$InstallToolsForAllUsers

    if ((-not $SkipAssemblyGeneration) -and ($IncludeCoreFxAssembly)) {
        if ((-not ('Core' -eq (Get-PSEdition))) -and (-not $PowerShellCorePath)) {
            $psCore = Get-Msi -Name "PowerShell*" -MaximumVersion "6.0.0.11" | Sort-Object -Property Version -Descending
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
    }

    $jsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop

    # Parse the JSON and populate the dictionary
    $swaggerDict = ConvertTo-SwaggerDictionary -SwaggerSpecPath $SwaggerSpecPath -ModuleName $ModuleName -ModuleVersion $Version
    $nameSpace = $swaggerDict['info'].NameSpace

    $outputDirectory = $Path.TrimEnd('\').TrimEnd('/')

    if($PSVersionTable.PSVersion -lt '5.0.0') {
        if (-not $outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleName
        }
    } else {
        $ModuleNameandVersionFolder = Join-Path -Path $ModuleName -ChildPath $Version

        if ($outputDirectory.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleVersion
        } elseif (-not $outputDirectory.EndsWith($ModuleNameandVersionFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $outputDirectory = Join-Path -Path $outputDirectory -ChildPath $ModuleNameandVersionFolder
        }
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop

    $swaggerMetaDict = @{
        OutputDirectory = $outputDirectory
        UseAzureCsharpGenerator = $UseAzureCsharpGenerator
        SwaggerSpecPath = $SwaggerSpecPath
    }

    $generatedCSharpFilePath = ConvertTo-CsharpCode -SwaggerDict $swaggerDict `
                                                    -SwaggerMetaDict $swaggerMetaDict `
                                                    -SkipAssemblyGeneration:$SkipAssemblyGeneration `
                                                    -PowerShellCorePath $PowerShellCorePath `
                                                    -InstallToolsForAllUsers:$InstallToolsForAllUsers `
                                                    -UserConsent:$userConsent

    # Prepare dynamic compilation
    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Utils.ps1") (Join-Path -Path $outputDirectory -ChildPath "Utils.ps1")
    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Utils.Resources.psd1") (Join-Path -Path $outputDirectory -ChildPath "Utils.Resources.psd1")

    $allCSharpFiles = Get-ChildItem -Path "$generatedCSharpFilePath\*.cs" `
                                    -Recurse `
                                    -File `
                                    -Exclude Program.cs,TemporaryGeneratedFile* | 
                          Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'

    $filesHash = New-CodeFileCatalog -Files $allCSharpFiles
    $fileHashesFileName = "GeneratedCsharpCatalog.json"

    ConvertTo-Json -InputObject $filesHash | 
        Out-File -FilePath (Join-Path -Path "$outputDirectory" -ChildPath "$fileHashesFileName") `
                 -Encoding ascii `
                 -Confirm:$false `
                 -WhatIf:$false

    $jsonFileHashAlgorithm = "SHA512"
    $jsonFileHash = (Get-CustomFileHash -Path (Join-Path -Path "$outputDirectory" -ChildPath "$fileHashesFileName") -Algorithm $jsonFileHashAlgorithm).Hash

    # If we precompiled the assemblies, we need to require a specific version of the dependent NuGet packages
    # For now, there's only one required package (Microsoft.Rest.ClientRuntime.Azure)
    $requiredVersionParameter = ''
    if (-not $SkipAssemblyGeneration) {
        # Compilation would have already installed this package, so this will just retrieve the package info
        # As of 3/2/2017, there's a version mismatch between the latest Microsoft.Rest.ClientRuntime.Azure package and the latest AzureRM.Profile package
        # So we have to hardcode Microsoft.Rest.ClientRuntime.Azure to at most version 3.3.4
        $package = Install-MicrosoftRestAzurePackage -RequiredVersion 3.3.4 -AllUsers:$InstallToolsForAllUsers -BootstrapConsent:$userConsent
        if($package)
        {
            $requiredVersionParameter = "-RequiredAzureRestVersion $($package.Version)"
        }
    }

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
                                -SwaggerDict $swaggerDict `
                                -SwaggerMetaDict $swaggerMetaDict `
                                -DefinitionFunctionsDetails $DefinitionFunctionsDetails
    }

    $FunctionsToExport = @()
    $FunctionsToExport += New-SwaggerSpecPathCommand -PathFunctionDetails $PathFunctionDetails `
                                                     -SwaggerMetaDict $swaggerMetaDict `
                                                     -SwaggerDict $swaggerDict

    $FunctionsToExport += New-SwaggerDefinitionCommand -DefinitionFunctionsDetails $DefinitionFunctionsDetails `
                                                        -SwaggerMetaDict $swaggerMetaDict `
                                                        -NameSpace $nameSpace

    $RootModuleFilePath = Join-Path $outputDirectory "$ModuleName.psm1"
    Out-File -FilePath $RootModuleFilePath `
             -InputObject $ExecutionContext.InvokeCommand.ExpandString($RootModuleContents)`
             -Encoding ascii `
             -Force `
             -Confirm:$false `
             -WhatIf:$false

    New-ModuleManifestUtility -Path $outputDirectory `
                              -FunctionsToExport $FunctionsToExport `
                              -Info $swaggerDict['info']

    Copy-Item (Join-Path -Path "$PSScriptRoot" -ChildPath "Generated.Resources.psd1") (Join-Path -Path "$outputDirectory" -ChildPath "$ModuleName.Resources.psd1") -Force
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
        [bool]
        $SkipAssemblyGeneration,

        [Parameter()]
        [String]
        $PowerShellCorePath,

        [Parameter()]
        [switch]
        $InstallToolsForAllUsers,

        [Parameter()]
        [switch]
        $UserConsent
    )

    Write-Verbose -Message $LocalizedData.GenerateCodeUsingAutoRest

    $autoRestExePath = "autorest.exe"
    if (-not (get-command -name autorest.exe))
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
        Write-Verbose -Message $LocalizedData.GenerateAssemblyFromCode
        $allCSharpFiles= Get-ChildItem -Path "$generatedCSharpPath\*.cs" `
                                       -Recurse `
                                       -File `
                                       -Exclude Program.cs,TemporaryGeneratedFile* |
                                       Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'

        $allCSharpFilesArrayString = "@('"+ $($allCSharpFiles.FullName -join "','") + "')"

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
        # As of 3/2/2017, there's a version mismatch between the latest Microsoft.Rest.ClientRuntime.Azure package and the latest AzureRM.Profile package
        # So we have to hardcode Microsoft.Rest.ClientRuntime.Azure to at most version 3.3.4
        $command = ". '$PSScriptRoot\Utils.ps1';
                    Initialize-LocalToolsVariables;
                    Invoke-AssemblyCompilation -OutputAssembly '$outAssembly' ``
                                               -CSharpFiles $allCSharpFilesArrayString ``
                                               -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator ``
                                               -RequiredAzureRestVersion 3.3.4 ``
                                               -AllUsers:`$$InstallToolsForAllUsers ``
                                               -BootstrapConsent:`$$UserConsent"

        $success = powershell -command "& {$command}"
        if ((Test-AssemblyCompilationSuccess -Output ($success | Out-String))) {
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
            
            $command = ". '$PSScriptRoot\Utils.ps1'; 
                        Initialize-LocalToolsVariables;
                        Invoke-AssemblyCompilation -OutputAssembly '$outAssembly' ``
                                                   -CSharpFiles $allCSharpFilesArrayString ``
                                                   -CodeCreatedByAzureGenerator:`$$codeCreatedByAzureGenerator"

            $success = & "$PowerShellCorePath" -command "& {$command}"
            if ((Test-AssemblyCompilationSuccess -Output ($success | Out-String))) {
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

function Test-AssemblyCompilationSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Output
    )

    Write-Verbose -Message ($LocalizedData.AssemblyCompilationResult -f ($Output))
    $tokens = $Output.Split(' ')
    return ($tokens[$tokens.Count-1].Trim() -eq 'True')
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
        $Info
    )

    $FormatsToProcess = Get-ChildItem -Path "$Path\$GeneratedCommandsName\FormatFiles\*.ps1xml" `
                                      -File `
                                      -ErrorAction Ignore | Foreach-Object { $_.FullName.Replace($Path, '.') }

    New-ModuleManifest -Path "$(Join-Path -Path $Path -ChildPath $Info.ModuleName).psd1" `
                       -ModuleVersion $Info.Version `
                       -RequiredModules @('Generated.Azure.Common.Helpers') `
                       -RootModule "$($Info.ModuleName).psm1" `
                       -FormatsToProcess $FormatsToProcess `
                       -FunctionsToExport $FunctionsToExport
}

#endregion

function New-CodeFileCatalog
{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Files
    )

    $hashAlgorithm = "SHA512"
    $filesTable = @{"Algorithm" = $hashAlgorithm}
    $Files | ForEach-Object {
        $fileName = "$_".Replace("$generatedCSharpFilePath","").Trim("\").Trim("/") 
        $hash = (Get-CustomFileHash $_ -Algorithm $hashAlgorithm).Hash
        $message = $LocalizedData.FoundFileWithHash -f ($fileName, $hash)
        Write-Verbose $message
        $filesTable.Add("$fileName", $hash) 
    }

    return $filesTable
}

Export-ModuleMember -Function New-PSSwaggerModule