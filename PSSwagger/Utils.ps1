$CorePsEditionConstant = 'Core'
Microsoft.PowerShell.Utility\Import-LocalizedData  UtilsLocalizedData -filename Utils.Resources.psd1

<#
.DESCRIPTION
  Compiles AutoRest generated C# code using the framework of the current PowerShell process.

.PARAMETER  CSharpFiles
  All C# files to compile. Only AutoRest generated code is fully supported.

.PARAMETER  OutputAssembly
  Full Path to the output assembly.

.PARAMETER  CodeCreatedByAzureGenerator
  Flag to specify if the generated C# code was created using the Azure C# generator or the regular C# generator in AutoRest.

.PARAMETER  RequiredAzureRestVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package, required for full CLR compilation.
#>
function Invoke-AssemblyCompilation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo[]]$CSharpFiles,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]$OutputAssembly,

        [Parameter(Mandatory=$false)]
        [switch]$CodeCreatedByAzureGenerator,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]$RequiredAzureRestVersion
    )

    # Append the content of each file into a single string
    $srcContent += $CSharpFiles | ForEach-Object { "// File $($_.FullName)"; get-content -path $_.FullName }
    
    # Find the reference assemblies to use
    # System refs are expected to exist on the system
    # Extra refs are shipped by PSSwagger
    # Module refs are shipped by AzureRM
    $systemRefs = @()
    $extraRefs = @()
    $moduleRefs = Get-AzureRMDllReferences
    $clrPath = ''
    if ($OutputAssembly) {
        $clrPath = Split-Path -Path $OutputAssembly -Parent
    }

    if ('Core' -eq (Get-PSEdition)) {
        # Base framework references
        $srcContent = ,'#define DNXCORE50' + $srcContent
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','Microsoft.CSharp.dll','System.Private.Uri.dll','System.Runtime.dll','System.Threading.Tasks.dll','System.Text.RegularExpressions.dll','System.Collections.dll','System.Net.Primitives.dll','System.Text.Encoding.dll','System.Linq.dll')
        if ($CodeCreatedByAzureGenerator) {
            $systemRefs += 'System.Runtime.Serialization.Primitives.dll'
        }

        if (-not $clrPath) {
            $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'coreclr'
        }
    } else {
        # Base framework references
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','System.Net.Http.WebRequest','System.Runtime.Serialization.dll','System.Xml.dll')

        if (-not $clrPath) {
            $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'fullclr'
        }

        # Microsoft.Rest.ClientRuntime.Azure.dll isn't packaged with AzureRM.Profile, but is required by AutoRest generated code
        # If the extra assembly already exists, use it
        $azureRestAssemblyPath = Get-MicrosoftRestAzureReference -Framework 'net45' -ClrPath $clrPath

        $extraRefs += $azureRestAssemblyPath
    }

    if (-not (Test-Path -Path $clrPath -PathType Container)) {
        $null = New-Item -Path $clrPath -ItemType Directory -Force
    }

    # Compile
    $oneSrc = $srcContent -join "`n"
    
    if ($OutputAssembly) {
        Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs + $moduleRefs) -OutputAssembly $OutputAssembly -IgnoreWarnings -Language CSharp
        if ((Get-Item -Path $OutputAssembly).Length -eq 0kb) {
            return $false
        }
    } else {
        $moduleRefs | ForEach-Object { Add-Type -Path $_ -ErrorAction Ignore }
        $extraRefs | ForEach-Object { Add-Type -Path $_ -ErrorAction Ignore }
        Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs + $moduleRefs) -IgnoreWarnings -Language CSharp
    }
        
    return $true
}

<#
.DESCRIPTION
  Retrieves all assembly references located in the PSEdition-appropriate AzureRM module.
#>
function Get-AzureRMDllReferences {
    [CmdletBinding()]
    param()

    $refs = @()
    if ($CorePsEditionConstant -eq (Get-PSEdition)) {
        $module = Get-Module -Name AzureRM.Profile.NetCore.Preview -ListAvailable | select-object -first 1
        $refs += (Join-Path -Path "$($module.ModuleBase)" -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll')
    } else {
        $module = Get-Module -Name AzureRM.Profile -ListAvailable | select-object -first 1
    }

    $refs += @((Join-Path -Path "$($module.ModuleBase)" -ChildPath 'Microsoft.Rest.ClientRuntime.dll'),
        (Join-Path -Path "$($module.ModuleBase)" -ChildPath 'Newtonsoft.Json.dll'))
    return $refs
}

<#
.DESCRIPTION
  Retrieves the PSEdition string. One of 'Core' or 'Desktop'.
#>
function Get-PSEdition {
    [CmdletBinding()]
    param()

    if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ($CorePsEditionConstant -eq $PSEdition)) {
        return $CorePsEditionConstant
    }

    # This sentinel isn't too important, since we only do checks for the Core string
    return 'Desktop'
}

<#
.DESCRIPTION
  Gets the path to the local machine's Microsoft.Rest.ClientRuntime.Azure.dll reference, downloading the package from NuGet if missing.

.PARAMETER  Framework
  Framework of the assembly to return.

.PARAMETER  ClrPath
  Path to CLR-specific reference directory in generated module.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.
#>
function Get-MicrosoftRestAzureReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('net45')]
        [string]$Framework,

        [Parameter(Mandatory=$true)]
        [string]$ClrPath,

        [Parameter(Mandatory=$false)]
        [string]$RequiredVersion
    )

    $azureRestAssemblyPath = Join-Path -Path $ClrPath -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'
    if (-not (Test-Path -Path $azureRestAssemblyPath)) {
        # Get the assembly from the NuGet package dynamically, then save it locally
        $package = Install-MicrosoftRestAzurePackage -RequiredVersion $RequiredVersion
        $azureRestAssemblyPathNuget = Join-Path -Path (Split-Path -Path $package.Source -Parent) -ChildPath 'lib' | Join-Path -ChildPath $Framework | Join-Path -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'
        if (-not (Test-Path -Path $ClrPath)) {
            $null = New-Item -Path $ClrPath -ItemType Directory
        }

        $null = Copy-Item -Path $azureRestAssemblyPathNuget -Destination $azureRestAssemblyPath -Force
    }

    return $azureRestAssemblyPath
}

<#
.DESCRIPTION
  Ensures the Microsoft.Rest.ClientRuntime.Azure package is installed.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.
#>
function Install-MicrosoftRestAzurePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]$RequiredVersion
    )

    $params = @{
        Name='Microsoft.Rest.ClientRuntime.Azure';
        ProviderName='NuGet';
        ErrorAction='SilentlyContinue'
    }

    if ($RequiredVersion) {
        $params['RequiredVersion'] = $RequiredVersion
    }

    $package = Get-Package @params | Select-Object -First 1

    if (-not $package) {
        $newPsName = ''
        $existingPackageSource = Get-NugetPackageSource
        if (-not $existingPackageSource) {
            $newPsName = New-NugetPackageSource
            $packageSourceName = $newPsName
        } else {
            $packageSourceName = $existingPackageSource.Name
        }

        $null = Find-Package @params -Source $packageSourceName | Select-Object -First 1 | Install-Package
        $package = Get-Package @params | Select-Object -First 1
        if ($newPsName) {
            $null = Unregister-PackageSource -Name $newPsName
        }
    }

    return $package
}

<#
.DESCRIPTION
  Gets the NuGet package source with location nuget.org/api/v2 exists.
#>
function Get-NugetPackageSource {
    $packageSource = Get-PackageSource | Where-Object { $_.Location -contains 'nuget.org/api/v2' } | Select-Object -First 1
    return $packageSource
}

<#
.DESCRIPTION
  Creates a temporary NuGet package source with given location.

.PARAMETER  Location
  Location of NuGet package source. Defaults to 'https://nuget.org/api/v2'.
#>
function New-NugetPackageSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Location = 'https://nuget.org/api/v2'
    )

    $psName = [guid]::newguid().Guid
    $psName = "PSSwagger NuGet ($psName)"
    $null = Register-PackageSource -Name $psName -Location $Location -ProviderName NuGet
    return $psName
}

<#
.DESCRIPTION
  Runs the built-in Get-FileHash cmdlet if PowerShell is 5.1+ or PowerShell Core. Otherwise, runs a similar custom implementation of Get-FileHash (Get-InternalFileHash).
  Unlike the built-in Get-FileHash, this function does not support MACTripleDES.

.PARAMETER  Path
  Path to file to hash.

.PARAMETER  Algorithm
  Hash algorithm to use.
#>
function Get-CustomFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [System.String]
        $Path,

        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5", "RIPEMD160")]
        [System.String]
        $Algorithm="SHA256"
    )

    if ((-not ($CorePsEditionConstant -eq (Get-PSEdition))) -and ($PSVersionTable.PSVersion -lt '5.1')) {
        return Get-InternalFileHash -Path $Path -Algorithm $Algorithm
    } else {
        return Get-FileHash -Path $Path -Algorithm $Algorithm
    }
}

<#
.DESCRIPTION
  Implementation of Get-FileHash from PowerShell 5.1+ and PowerShell Core. For use with PowerShell 5.0 or older. Has pipeline and multiple file support removed for simplicity.

.PARAMETER  Path
  Path to file to hash.

.PARAMETER  Algorithm
  Hash algorithm to use.
#>
function Get-InternalFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [System.String]
        $Path,

        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5", "RIPEMD160")]
        [System.String]
        $Algorithm="SHA256"
    )
    
    begin {
        # Construct the strongly-typed crypto object
        
        # First see if it has a FIPS algorithm  
        $hasherType = "System.Security.Cryptography.${Algorithm}CryptoServiceProvider" -as [Type]
        if ($hasherType) {
            $hasher = $hasherType::New()
        } else {
            # Check if the type is supported in the current system
            $algorithmType = "System.Security.Cryptography.${Algorithm}" -as [Type]
            if ($algorithmType) {
                if ($Algorithm -eq "MACTripleDES") {
                    $hasher = $algorithmType::New()
                } else {
                    $hasher = $algorithmType::Create()
                }
            }
            else {
                throw $UtilsLocalizedData.AlgorithmNotSupported -f ($Algorithm)
            }
        }

        function GetStreamHash {
            param(
                [System.IO.Stream]
                $InputStream,

                [System.Security.Cryptography.HashAlgorithm]
                $Hasher)

            # Compute file-hash using the crypto object
            [Byte[]] $computedHash = $Hasher.ComputeHash($InputStream)
            [string] $hash = [BitConverter]::ToString($computedHash) -replace '-',''

            $retVal = [PSCustomObject] @{
                Algorithm = $Algorithm.ToUpperInvariant()
                Hash = $hash
            }

            $retVal
        }
    }
    
    process {
        $filePath = Resolve-Path -Path $Path
        if(Test-Path -Path $filePath -PathType Container) {
            continue
        }

        try {
            # Read the file specified in $FilePath as a Byte array
            [system.io.stream]$stream = [system.io.file]::OpenRead($filePath)
            GetStreamHash -InputStream $stream -Hasher $hasher
        }
        catch [Exception] {
            throw $UtilsLocalizedData.FailedToReadFile -f ($filePath)
        }
        finally {
            if($stream) {
                $stream.Dispose()
            }
        }
    }
}