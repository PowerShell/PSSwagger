﻿<#
.DESCRIPTION
  Compiles AutoRest generated C# code using the framework of the current PowerShell process.

.PARAMETER  CSharpFiles
  All C# files to compile. Only AutoRest generated code is fully supported.

.PARAMETER  OutputAssembly
  Full Path to the output assembly.

.PARAMETER  CodeCreatedByAzureGenerator
  Flag to specify if the generated C# code was created using the Azure C# generator or the regular C# generator in AutoRest.

.PARAMETER  CopyExtraReferences
  Switch to specify if the non-framework assemblies that were used to compile the output assembly should be copied to the ref directory.
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
        [switch]$CopyExtraReferences
    )

    # Append the content of each file into a single string
    $srcContent += $CSharpFiles | ForEach-Object { "// File $($_.FullName)"; get-content -path $_.FullName }
    
    # Find the reference assemblies to use
    # Note that PSCore has to be built off netstandard1.7 or above (i.e. the built-in PSCore on Nano Server won't work)
    $systemRefs = @()
    $extraRefs = @()
    if ('Core' -eq $PSEdition) {
        # Base framework references
        $srcContent = ,'#define DNXCORE50' + $srcContent
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','Microsoft.CSharp.dll','System.Private.Uri.dll','System.Runtime.dll','System.Threading.Tasks.dll','System.Text.RegularExpressions.dll','System.Collections.dll','System.Net.Primitives.dll','System.Text.Encoding.dll','System.Linq.dll')
        if ($CodeCreatedByAzureGenerator) {
            $systemRefs += 'System.Runtime.Serialization.Primitives.dll'
        }

        # For Core CLR edition, use AzureRM.Profile.NetCore.Preview module
        $module = Get-Module -Name AzureRM.Profile.NetCore.Preview -ListAvailable | select-object -first 1
        $extraRefs += Get-ChildItem -Path (Join-Path -Path $module.ModuleBase -ChildPath "*.dll") | ForEach-Object { $_.FullName }

        $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "coreclr"
    } else {
        # Base framework references
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','System.Net.Http.WebRequest','System.Runtime.Serialization.dll','System.Xml.dll')

        # For Desktop edition, use AzureRM.Profile module
        $module = Get-Module -Name AzureRM.Profile -ListAvailable | select-object -first 1
        $extraRefs += Get-ChildItem -Path (Join-Path -Path $module.ModuleBase -ChildPath "*.dll") | ForEach-Object { $_.FullName }

        $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "fullclr"

         # These are extra required assemblies that AzureRM.Profile doesn't package for some reason
        $extraRefs += Join-Path -Path "$clrPath" -ChildPath "Microsoft.Rest.ClientRuntime.Azure.dll"
    }

    if (-not (Test-Path -Path $clrPath -PathType Container)) {
        $null = New-Item -Path $clrPath -ItemType Directory -Force
    }

    # Compile
    $oneSrc = $srcContent -join "`n"
    if ($OutputAssembly) {
        Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs) -OutputAssembly $OutputAssembly -IgnoreWarnings
        if ((Get-Item -Path $OutputAssembly).Length -eq 0kb) {
            return $false
        }

    } else {
        $typeReturned = Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs) -IgnoreWarnings -PassThru
        # TODO validate
    }
    
    if ($CopyExtraReferences) {
            # Copy extra refs
            $extraRefs | ForEach-Object {
                $newFile = (Join-Path -Path "$clrPath" -ChildPath (Split-Path -Path $_ -Leaf))
                if ($_ -ne $newFile) {
                    $null = Copy-Item -Path $_ -Destination $newFile -Force
                }
            }
        }
        
    return $true
}