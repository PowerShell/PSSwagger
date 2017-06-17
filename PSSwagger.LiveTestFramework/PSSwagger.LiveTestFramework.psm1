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
    
    $osInfo = PSSwagger.Common.Helpers\Get-OperatingSystemInfo
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

    $osInfo = PSSwagger.Common.Helpers\Get-OperatingSystemInfo
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

    $osInfo = PSSwagger.Common.Helpers\Get-OperatingSystemInfo
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

    $addTypeParamsResult = PSSwagger.Common.Helpers\Get-PSSwaggerAddTypeParameters @GetPSSwaggerAddTypeParametersParams

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

Export-ModuleMember -Function Start-PSSwaggerLiveTestServer,Add-PSSwaggerLiveTestLibType,Add-PSSwaggerLiveTestServerType