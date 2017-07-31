Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PSSwagger.LiveTestFramework.Resources.psd1

<#
.DESCRIPTION
   Compile the PSSwagger.LiveTestFramework assemblies if required, then start the server and return the process. The compiled assemblies can be found in the bin folder.

.PARAMETER  BootstrapConsent
   User has consented to automatically download package dependencies.

.PARAMETER  NoNewWindow
   Don't create a new window for the server. Only available on full PowerShell.
#>
function Start-PSSwaggerLiveTestServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent,

        [Parameter(Mandatory=$false)]
        [switch]
        $NoNewWindow
    )
    
    $osInfo = PSSwaggerUtility\Get-OperatingSystemInfo
    if ($osInfo.IsCore) {
        $clr = 'coreclr'
    } else {
        $clr = 'fullclr'
    }

    $outputDirectory = Join-Path -Path $PSScriptRoot -ChildPath "bin" | Join-Path -ChildPath $clr
    
    # Use a friendlier but longer name
    $exeName = "PSSwagger.LiveTestFramework.ConsoleServer.exe"
    $exePath = Join-Path -Path $outputDirectory -ChildPath $exeName
    $addTypeParams = @{
        BootstrapConsent = $BootstrapConsent
        OutputDirectory = $outputDirectory
    }

    # Check if we have access to write the compiled binaries
    try {
        "" | out-file $exePath -append
        $null = Remove-Item -Path $exePath -Force
        $addTypeParams['SaveAssembly'] = $true
    } catch { }

    if (-not (Test-Path -Path (Join-Path -Path $outputDirectory -ChildPath 'PSSwagger.LTF.Lib.dll'))) {
        Add-PSSwaggerLiveTestLibType @addTypeParams
    }

    if (-not (Test-Path -Path $exePath)) {
        $addTypeParams['OutputFileName'] = $exeName
        Add-PSSwaggerLiveTestServerType @addTypeParams
    }
    
    # Start server.exe
    Write-Verbose -Message ($LocalizedData.StartingConsoleServerFromPath -f ($exePath))
    $startProcessParams = @{
        FilePath = $exePath
        PassThru = $true
    }

    if (-not $osInfo.IsCore -and $NoNewWindow) {
        $startProcessParams['NoNewWindow'] = $true
    }

    Start-Process @startProcessParams
}

<#
.DESCRIPTION
   Compile the PSSwagger LiveTestFramework library assembly for the current CLR.

.PARAMETER  OutputDirectory
   Output directory to place compiled assembly.

.PARAMETER  OutputFileName
   Name of output assembly.

.PARAMETER  DebugSymbolDirectory
   If the assembly is saved to disk, the code used to generate it will be saved here. If the PDB exists, it will also be saved here.

.PARAMETER  AllUsers
   Download package dependencies to PSSwagger global location.

.PARAMETER  BootstrapConsent
   User has consented to automatically download package dependencies.

.PARAMETER  SaveAssembly
   Save output assembly. By default, generates in-memory.
#>
function Add-PSSwaggerLiveTestLibType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputFileName = "PSSwagger.LTF.Lib.dll",

        [Parameter(Mandatory=$false)]
        [string]
        $DebugSymbolDirectory,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent,

        [Parameter(Mandatory=$false)]
        [switch]
        $SaveAssembly
    )

    $osInfo = PSSwaggerUtility\Get-OperatingSystemInfo
    $codeFilePaths = @()
    $systemRefs = @()
    $packageDependencies = @{}
    # TODO: Fill in system and package refs for both CLR
    if ($osInfo.IsCore) {
        $clr = 'coreclr'
        # TODO: Fill in system and package refs for core CLR
        $systemRefs += 'System.dll'
    } else {
        $clr = 'fullclr'
        # TODO: Fill in system and package refs for full CLR
        $systemRefs += 'System.dll'
    }

    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path -Path $PSScriptRoot -ChildPath "bin" | Join-Path -ChildPath $clr
    }

    foreach ($item in (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "src" | Join-Path -ChildPath "PSSwagger.LTF.Lib" | Join-Path -ChildPath "*.Code.ps1") -Recurse -File)) {
        if ($osInfo.IsWindows) {
            $sig = Get-AuthenticodeSignature -FilePath $item.FullName
            if (('Valid' -ne $sig.Status) -and ('NotSigned' -ne $sig.Status) -and ('UnknownError' -ne $sig.Status)) {
                throw ($LocalizedData.CodeFileSignatureValidationFailed -f ($item.FullName))
            }
        }

        $codeFilePaths += $item.FullName
    }

    Add-PSSwaggerLiveTestTypeGeneric -CodeFilePaths $codeFilePaths -OutputDirectory $OutputDirectory -OutputFileName $OutputFileName `
                                     -DebugSymbolDirectory $DebugSymbolDirectory -SystemReferences $systemRefs `
                                     -PackageDependencies $PackageDependencies -AllUsers:$AllUsers `
                                     -BootstrapConsent:$BootstrapConsent -SaveAssembly:$SaveAssembly
}

<#
.DESCRIPTION
   Compile the PSSwagger LiveTestFramework Console Server assembly for the current CLR.

.PARAMETER  OutputDirectory
   Output directory to place compiled assembly.

.PARAMETER  OutputFileName
   Name of output assembly.

.PARAMETER  DebugSymbolDirectory
   If the assembly is saved to disk, the code used to generate it will be saved here. If the PDB exists, it will also be saved here.

.PARAMETER  AllUsers
   Download package dependencies to PSSwagger global location.

.PARAMETER  BootstrapConsent
   User has consented to automatically  download package dependencies.

.PARAMETER  SaveAssembly
   Save output assembly. By default, generates in-memory.
#>
function Add-PSSwaggerLiveTestServerType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputFileName = "PSSwagger.LTF.ConsoleServer.exe",

        [Parameter(Mandatory=$false)]
        [string]
        $DebugSymbolDirectory,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent,

        [Parameter(Mandatory=$false)]
        [switch]
        $SaveAssembly
    )

    $osInfo = PSSwaggerUtility\Get-OperatingSystemInfo
    $codeFilePaths = @()
    $systemRefs = @()
    $packageDependencies = @{}
    # TODO: Fill in system and package refs for both CLR
    if ($osInfo.IsCore) {
        $clr = 'coreclr'
        # TODO: Fill in system and package refs for core CLR
        $systemRefs += 'System.dll'
    } else {
        $clr = 'fullclr'
        # TODO: Fill in system and package refs for full CLR
        $systemRefs += 'System.dll'
    }

    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path -Path $PSScriptRoot -ChildPath "bin" | Join-Path -ChildPath $clr
    }

    foreach ($item in (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "src" | Join-Path -ChildPath "PSSwagger.LTF.ConsoleServer" | Join-Path -ChildPath "*.Code.ps1") -Recurse -File)) {
        if ($osInfo.IsWindows) {
            $sig = Get-AuthenticodeSignature -FilePath $item.FullName
            if (('Valid' -ne $sig.Status) -and ('NotSigned' -ne $sig.Status) -and ('UnknownError' -ne $sig.Status)) {
                throw ($LocalizedData.CodeFileSignatureValidationFailed -f ($item.FullName))
            }
        }

        $codeFilePaths += $item.FullName
    }

    Add-PSSwaggerLiveTestTypeGeneric -CodeFilePaths $codeFilePaths -OutputDirectory $OutputDirectory -OutputFileName $OutputFileName `
                                     -DebugSymbolDirectory $DebugSymbolDirectory -SystemReferences $systemRefs `
                                     -PackageDependencies $PackageDependencies -AllUsers:$AllUsers `
                                     -BootstrapConsent:$BootstrapConsent -SaveAssembly:$SaveAssembly -OutputType 'ConsoleApplication'
}

<#
.DESCRIPTION
   Compile a generic PSSwagger LiveTestFramework assembly.

.PARAMETER  CodeFilePaths
   Full paths to the code files to compile.

.PARAMETER  OutputDirectory
   Output directory to place compiled assembly.

.PARAMETER  OutputFileName
   Name of output assembly.

.PARAMETER  DebugSymbolDirectory
   If the assembly is saved to disk, the code used to generate it will be saved here. If the PDB exists, it will also be saved here.

.PARAMETER  SystemReferences
   Framework references to add.

.PARAMETER  PackageDependencies
   Package dependencies required.

.PARAMETER  AllUsers
   Download package dependencies to PSSwagger global location.

.PARAMETER  BootstrapConsent
   User has consented to automatically download package dependencies.

.PARAMETER  SaveAssembly
   Save output assembly. By default, generates in-memory.
#>
function Add-PSSwaggerLiveTestTypeGeneric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $CodeFilePaths,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputFileName,

        [Parameter(Mandatory=$false)]
        [ValidateSet("ConsoleApplication","Library")]
        [string]
        $OutputType = 'Library',

        [Parameter(Mandatory=$false)]
        [string]
        $DebugSymbolDirectory,

        [Parameter(Mandatory=$true)]
        [string[]]
        $SystemReferences,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $PackageDependencies,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent,

        [Parameter(Mandatory=$false)]
        [switch]
        $SaveAssembly
    )

    if ($OutputDirectory -and -not (Test-Path -Path $OutputDirectory -PathType Container)) {
        $null = New-Item -Path $OutputDirectory -ItemType Directory -Force
    }

    if ($DebugSymbolDirectory -and -not (Test-Path -Path $DebugSymbolDirectory -PathType Container)) {
        $null = New-Item -Path $DebugSymbolDirectory -ItemType Directory -Force
    }

    $GetPSSwaggerAddTypeParametersParams = @{
        Path = $CodeFilePaths
        OutputDirectory = $OutputDirectory
        AllUsers = $AllUsers
        BootstrapConsent = $BootstrapConsent
        TestBuild = $true
        SymbolPath = $DebugSymbolDirectory
        PackageDependencies = $PackageDependencies
        FileReferences = $SystemReferences
        OutputType = $OutputType
    }

    if ($SaveAssembly) {
        $GetPSSwaggerAddTypeParametersParams['OutputAssemblyName'] = $OutputFileName
    }

    $addTypeParamsResult = Get-PSSwaggerAddTypeParameters @GetPSSwaggerAddTypeParametersParams

    if ($addTypeParamsResult['ResolvedPackageReferences']) {
        foreach ($extraRef in $addTypeParamsResult['ResolvedPackageReferences']) {
            if ($SaveAssembly) {
                $null = Copy-Item -Path $extraRef -Destination (Join-Path -Path $OutputDirectory -ChildPath (Split-Path -Path $extraRef -Leaf)) -Force
            }

            Add-Type -Path $extraRef -ErrorAction Ignore
        }
    }

    if ($addTypeParamsResult['SourceFileName']) {
        # A source code file is expected to exist
        # Emit the created source code
        $addTypeParamsResult['SourceCode'] | Out-File -FilePath $addTypeParamsResult['SourceFileName']
    }

    $addTypeParams = $addTypeParamsResult['Params']
    Add-Type @addTypeParams

    # Copy the PDB to the symbol path if specified
    if ($addTypeParamsResult['OutputAssemblyPath']) {
        # Verify result of Add-Type
        if ((-not (Test-Path -Path $addTypeParamsResult['OutputAssemblyPath'])) -or ((Get-Item -Path $addTypeParamsResult['OutputAssemblyPath']).Length -eq 0kb)) {
            return $false
        }

        $outputAssemblyItem = Get-Item -Path $addTypeParamsResult['OutputAssemblyPath']
        $OutputPdbName = "$($outputAssemblyItem.BaseName).pdb"
        if ($DebugSymbolDirectory -and (Test-Path -Path (Join-Path -Path $OutputDirectory -ChildPath $OutputPdbName))) {
            $null = Copy-Item -Path (Join-Path -Path $OutputDirectory -ChildPath $OutputPdbName) -Destination (Join-Path -Path $DebugSymbolDirectory -ChildPath $OutputPdbName)
        }
    }
}

<#
.DESCRIPTION
  Compiles AutoRest generated C# code using the framework of the current PowerShell process.

.PARAMETER  Path
  All *.Code.ps1 C# files to compile.

.PARAMETER  OutputDirectory
  Full Path to output directory.

.PARAMETER  OutputAssemblyName
  Optional assembly file name.

.PARAMETER  AllUsers
  User has specified to install package dependencies to global location.

.PARAMETER  BootstrapConsent
  User has consented to bootstrap dependencies.

.PARAMETER  TestBuild
  Build binaries for testing (disable compiler optimizations, enable full debug information).

.PARAMETER  SymbolPath
  Path to store PDB file and matching source file.

.PARAMETER  PackageDependencies
  Map of package dependencies to add as referenced assemblies but don't exist on disk.

.PARAMETER  FileReferences
  Compilation references that exist on disk.

.PARAMETER  PreprocessorDirectives
  Preprocessor directives to add to the top of the combined source code file.
#>
function Get-PSSwaggerAddTypeParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]
        $Path,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OutputAssemblyName,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent,

        [Parameter(Mandatory=$false)]
        [switch]
        $TestBuild,

        [Parameter(Mandatory=$false)]
        [string]
        $SymbolPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet("ConsoleApplication","Library")]
        [string]
        $OutputType = 'Library',
		
        [Parameter(Mandatory=$false)]
        [hashtable]
        $PackageDependencies,
		
        [Parameter(Mandatory=$false)]
        [string[]]
        $FileReferences,

        [Parameter(Mandatory=$false)]
        [string[]]
        $PreprocessorDirectives
    )
	
    $resultObj = @{
        # The add type parameters to use
        Params = $null
        # Full path to resolved package reference assemblies
        ResolvedPackageReferences = @()
        # The expected output assembly full path
        OutputAssemblyPath = $null
        # The actual source to be emitted
        SourceCode = $null
        # The file name the returned params expect to exist, if required
        SourceFileName = $null
    }

    # Resolve package dependencies
    $extraRefs = @()
    if ($PackageDependencies) {
        foreach ($entry in ($PackageDependencies.GetEnumerator() | Sort-Object { $_.Value.LoadOrder })) {
            $reference = $entry.Value
            $resolvedRef = Get-PSSwaggerDependency -PackageName $reference.PackageName `
                                                -RequiredVersion $reference.RequiredVersion `
                                                -References $reference.References `
                                                -Framework $reference.Framework `
                                                -AllUsers:$AllUsers -Install -BootstrapConsent:$BootstrapConsent
            $extraRefs += $resolvedRef
            $resultObj['ResolvedPackageReferences'] += $resolvedRef
        }
    }

    # Combine the possibly authenticode-signed *.Code.ps1 files into a single file, adding preprocessor directives to the beginning if specified
    $srcContent = @()
    $srcContent += $Path | ForEach-Object { "// File $_"; Remove-AuthenticodeSignatureBlock -Path $_ }
    if ($PreprocessorDirectives) {
        foreach ($preprocessorDirective in $PreprocessorDirectives) {
            $srcContent = ,$preprocessorDirective + $srcContent
        }
    }

    $oneSrc = $srcContent -join "`n"
    $resultObj['SourceCode'] = $oneSrc
    if ($SymbolPath) {
        if ($OutputAssemblyName) {
            $OutputAssemblyBaseName = [System.IO.Path]::GetFileNameWithoutExtension("$OutputAssemblyName")
            $resultObj['SourceFileName'] = Join-Path -Path $SymbolPath -ChildPath "Generated.$OutputAssemblyBaseName.cs"
        } else {
            $resultObj['SourceFileName'] = Join-Path -Path $SymbolPath -ChildPath "Generated.cs"
        }

        $addTypeParams = @{
            Path = $resultObj['SourceFileName']
            WarningAction = 'Ignore'
        }
    } else {
        $addTypeParams = @{
            TypeDefinition = $oneSrc
            Language = "CSharp"
            WarningAction = 'Ignore'
        }
    }

    if (-not (Get-OperatingSystemInfo).IsCore) {
        $compilerParameters = New-Object -TypeName System.CodeDom.Compiler.CompilerParameters
        $compilerParameters.CompilerOptions = '/debug:full'
        if ($TestBuild) {
            $compilerParameters.IncludeDebugInformation = $true
        } else {
            $compilerParameters.CompilerOptions += ' /optimize+'
        }

        if ($OutputType -eq 'ConsoleApplication') {
            $compilerParameters.GenerateExecutable = $true
        }
    
        $compilerParameters.WarningLevel = 3
        foreach ($ref in ($FileReferences + $extraRefs)) {
            $null = $compilerParameters.ReferencedAssemblies.Add($ref)
        }
        $addTypeParams['CompilerParameters'] = $compilerParameters
    } else {
        $addTypeParams['ReferencedAssemblies'] = ($FileReferences + $extraRefs)
        if ($OutputType -eq 'ConsoleApplication') {
            $addTypeParams['ReferencedAssemblies'] = $OutputType
        }
    }

    $OutputPdbName = ''
    if ($OutputAssemblyName) {
        $OutputAssembly = Join-Path -Path $OutputDirectory -ChildPath $OutputAssemblyName
        $resultObj['OutputAssemblyPath'] = $OutputAssembly
        if ($addTypeParams.ContainsKey('CompilerParameters')) {
            $addTypeParams['CompilerParameters'].OutputAssembly = $OutputAssembly
        } else {
            $addTypeParams['OutputAssembly'] = $OutputAssembly
        }
    } else {
        if ($addTypeParams.ContainsKey('CompilerParameters')) {
            $addTypeParams['CompilerParameters'].GenerateInMemory = $true
        }
    }
    
    $resultObj['Params'] = $addTypeParams
    return $resultObj
}

Export-ModuleMember -Function Start-PSSwaggerLiveTestServer,Add-PSSwaggerLiveTestLibType,Add-PSSwaggerLiveTestServerType