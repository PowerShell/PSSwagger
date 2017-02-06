function Compile-CSharpCode {
    param(
        [System.IO.FileInfo[]]$CSharpFiles,
        [string]$OutputAssembly,
        [bool]$AzureCSharpGenerator,
        [switch]$CopyExtraReferences
    )

    # Append the content of each file into a single string
    $srcContent += $CSharpFiles | ForEach-Object { "// File $($_.FullName)"; get-content $_.FullName }
    
    # Find the reference assemblies to use
    # Note that PSCore has to be built off netstandard1.7 or above (i.e. the built-in PSCore on Nano Server won't work)
    $systemRefs = @()
    $extraRefs = @()
    if ('Desktop' -eq $PSEdition) {
        # Base framework references
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','System.Net.Http.WebRequest','System.Runtime.Serialization.dll','System.Xml.dll')

        # For Desktop edition, use AzureRM.Profile module
        $module = Get-Module AzureRM.Profile -ListAvailable | select-object -first 1
        $extraRefs += Get-ChildItem -Path $module.ModuleBase -Filter *.dll | ForEach-Object { $_.FullName }

        # These are extra required assemblies that AzureRM.Profile doesn't package for some reason
        $clrPath = Join-Path "$PSScriptRoot" "ref" | Join-Path -ChildPath "fullclr"
        $extraRefs += Join-Path "$clrPath" "Microsoft.Rest.ClientRuntime.Azure.dll"
    } else {
        # Base framework references
        $srcContent = ,'#define DNXCORE50' + $srcContent
        $systemRefs = @('System.dll','System.Core.dll','System.Net.Http.dll','Microsoft.CSharp.dll','System.Private.Uri.dll','System.Runtime.dll','System.Threading.Tasks.dll','System.Text.RegularExpressions.dll','System.Collections.dll','System.Net.Primitives.dll','System.Text.Encoding.dll','System.Linq.dll')
        if ($AzureCSharpGenerator) {
            $systemRefs += 'System.Runtime.Serialization.Primitives.dll'
        }

        # For Core CLR edition, use AzureRM.Profile.NetCore.Preview module
        $module = Get-Module AzureRM.Profile.NetCore.Preview -ListAvailable | select-object -first 1
        $extraRefs += Get-ChildItem -Path $module.ModuleBase -Filter *.dll | ForEach-Object { $_.FullName }

        $clrPath = Join-Path "$PSScriptRoot" "ref" | Join-Path -ChildPath "coreclr"
    }

    if (-not (Test-Path $clrPath)) {
        $null = New-Item $clrPath -ItemType Directory -Force
    }

    # Compile
    $oneSrc = $srcContent -join "`n"
    Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies ($systemRefs + $extraRefs) -OutputAssembly $OutputAssembly
    if ((Get-item $OutputAssembly).Length -eq 0kb) {
        return $false
    }

    if ($CopyExtraReferences) {
        # Copy extra refs
        $extraRefs | ForEach-Object {
            $newFile = (Join-Path "$clrPath" (Split-Path $_ -Leaf))
            if ($_ -ne $newFile) {
                $null = Copy-Item $_ $newFile
            }
        }
    }

    return $true
}