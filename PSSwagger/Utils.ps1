$CorePsEditionConstant = 'Core'

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
    if ('' -ne $OutputAssembly) {
        $clrPath = Split-Path -Path $OutputAssembly -Parent
    }

    if ('Core' -eq $PSEdition) {
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

    if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ($CorePsEditionConstant -eq $PSEdition)) {
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
        if (-not (Test-Path -Path (Split-Path -Path $azureRestAssemblyPath -Parent))) {
            $null = New-Item -Path (Split-Path -Path $azureRestAssemblyPath -Parent) -ItemType Directory
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

    if (-not $RequiredVersion) {
        $package = Get-Package -Name Microsoft.Rest.ClientRuntime.Azure -ErrorAction SilentlyContinue | Select-Object -First 1
    } else {
        $package = Get-Package -Name Microsoft.Rest.ClientRuntime.Azure -RequiredVersion $RequiredVersion -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if (-not $package) {
        if (-not $RequiredVersion) {
            $null = Find-Package -Name Microsoft.Rest.ClientRuntime.Azure | Select-Object -First 1 | Install-Package
            $package = Get-Package -Name Microsoft.Rest.ClientRuntime.Azure | Select-Object -First 1
        } else {
            $null = Find-Package -Name Microsoft.Rest.ClientRuntime.Azure -RequiredVersion $RequiredVersion | Select-Object -First 1 | Install-Package
            $package = Get-Package -Name Microsoft.Rest.ClientRuntime.Azure -RequiredVersion $RequiredVersion | Select-Object -First 1
        }
    }

    return $package
}