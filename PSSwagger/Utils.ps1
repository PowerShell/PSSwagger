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
        [switch]$CodeCreatedByAzureGenerator
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
    if ('Core' -eq $PSEdition) {
        # Base framework references
        $srcContent = ,'#define DNXCORE50' + $srcContent
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','Microsoft.CSharp.dll','System.Private.Uri.dll','System.Runtime.dll','System.Threading.Tasks.dll','System.Text.RegularExpressions.dll','System.Collections.dll','System.Net.Primitives.dll','System.Text.Encoding.dll','System.Linq.dll')
        if ($CodeCreatedByAzureGenerator) {
            $systemRefs += 'System.Runtime.Serialization.Primitives.dll'
        }

        $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'coreclr'
    } else {
        # Base framework references
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','System.Net.Http.WebRequest','System.Runtime.Serialization.dll','System.Xml.dll')

        $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'fullclr'

         # These are extra required assemblies that AzureRM.Profile doesn't package for some reason
        $extraRefs += Join-Path -Path "$clrPath" -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'
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
        Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs + $moduleRefs) -IgnoreWarnings -Language CSharp
    }

    # Copy extra refs
    $extraRefs | ForEach-Object {
        $newFile = (Join-Path -Path "$clrPath" -ChildPath (Split-Path -Path $_ -Leaf))
        if ($_ -ne $newFile) {
            $null = Copy-Item -Path $_ -Destination $newFile -Force
        }
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

    if ($CorePsEditionConstant -eq (Get-PSEdition)) {
        $module = Get-Module -Name AzureRM.Profile.NetCore.Preview -ListAvailable | select-object -first 1
    } else {
        $module = Get-Module -Name AzureRM.Profile -ListAvailable | select-object -first 1
    }

     Get-ChildItem -Path (Join-Path -Path $module.ModuleBase -ChildPath '*.dll') -File | ForEach-Object { $_.FullName }
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