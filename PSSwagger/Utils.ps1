﻿Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

$script:CorePsEditionConstant = 'Core'

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
        [System.IO.FileInfo[]]
        $CSharpFiles,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OutputAssembly,

        [Parameter(Mandatory=$false)]
        [switch]
        $CodeCreatedByAzureGenerator,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredAzureRestVersion
    )

    # Append the content of each file into a single string
    $srcContent = @()
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

    if ('Core' -eq $PSEdition) {
        # Base framework references
        $srcContent = ,'#define DNXCORE50' + $srcContent
        $systemRefs = @('System.dll',
                        'System.Core.dll',
                        'System.Net.Http.dll',
                        'Microsoft.CSharp.dll',
                        'System.Private.Uri.dll',
                        'System.Runtime.dll',
                        'System.Threading.Tasks.dll',
                        'System.Text.RegularExpressions.dll',
                        'System.Collections.dll',
                        'System.Net.Primitives.dll',
                        'System.Text.Encoding.dll',
                        'System.Linq.dll')

        if ($CodeCreatedByAzureGenerator) {
            $systemRefs += 'System.Runtime.Serialization.Primitives.dll'
        }

        if (-not $clrPath) {
            $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'coreclr'
        }
    } else {
        # Base framework references
        $systemRefs = @('System.dll',
                        'System.Core.dll',
                        'System.Net.Http.dll',
                        'System.Net.Http.WebRequest',
                        'System.Runtime.Serialization.dll',
                        'System.Xml.dll')

        if (-not $clrPath) {
            $clrPath = Join-Path -Path "$PSScriptRoot" -ChildPath 'ref' | Join-Path -ChildPath 'fullclr'
        }

        # Microsoft.Rest.ClientRuntime.Azure.dll isn't packaged with AzureRM.Profile, but is required by AutoRest generated code
        # If the extra assembly already exists, use it
        $Params = @{
            Framework = 'net45'
            ClrPath = $clrPath
        }
        if($RequiredAzureRestVersion)
        {
            $Params['RequiredVersion'] = $RequiredAzureRestVersion
        }
        $azureRestAssemblyPath = Get-MicrosoftRestAzureReference @Params

        if($azureRestAssemblyPath)
        {
            $extraRefs += $azureRestAssemblyPath
        }
    }

    if (-not (Test-Path -Path $clrPath -PathType Container)) {
        $null = New-Item -Path $clrPath -ItemType Directory -Force
    }

    # Compile
    $oneSrc = $srcContent -join "`n"
    
    if ($OutputAssembly) {
        Add-Type -TypeDefinition $oneSrc `
                 -ReferencedAssemblies ($systemRefs + $extraRefs + $moduleRefs) `
                 -OutputAssembly $OutputAssembly `
                 -Language CSharp `
                 -IgnoreWarnings `
                 -WarningAction Ignore

        if ((Get-Item -Path $OutputAssembly).Length -eq 0kb) {
            return $false
        }
    } else {
        $moduleRefs | ForEach-Object { Add-Type -Path $_ -ErrorAction Ignore }
        $extraRefs | ForEach-Object { Add-Type -Path $_ -ErrorAction Ignore }
        
        Add-Type -TypeDefinition $oneSrc `
                 -ReferencedAssemblies ($systemRefs + $extraRefs + $moduleRefs) `
                 -Language CSharp `
                 -IgnoreWarnings `
                 -WarningAction Ignore

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
    if ($script:CorePsEditionConstant -eq (Get-PSEdition)) {
        $module = Get-Module -Name AzureRM.Profile.NetCore.Preview -ListAvailable | 
                      Select-Object -First 1 -ErrorAction Ignore
                      
        $refs += (Join-Path -Path "$($module.ModuleBase)" -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll')
    } else {
        $module = Get-Module -Name AzureRM.Profile -ListAvailable | 
                      Select-Object -First 1 -ErrorAction Ignore
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

    if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ($script:CorePsEditionConstant -eq $PSEdition)) {
        return $script:CorePsEditionConstant
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
        [string]
        $Framework,

        [Parameter(Mandatory=$true)]
        [string]
        $ClrPath,

        [Parameter(Mandatory=$false)]
        [string]
        $RequiredVersion
    )

    $azureRestAssemblyPath = Join-Path -Path $ClrPath -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'
    if (-not (Test-Path -Path $azureRestAssemblyPath)) {
        # Get the assembly from the NuGet package dynamically, then save it locally
        $package = Install-MicrosoftRestAzurePackage -RequiredVersion $RequiredVersion
        if($package)
        {
            $azureRestAssemblyPathNuget = Join-Path -Path (Split-Path -Path $package.Source -Parent) -ChildPath 'lib' | 
                                              Join-Path -ChildPath $Framework | 
                                                  Join-Path -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'

            if (-not (Test-Path -Path $ClrPath)){
                $null = New-Item -Path $ClrPath -ItemType Directory
            }

            $null = Copy-Item -Path $azureRestAssemblyPathNuget -Destination $azureRestAssemblyPath -Force
        }
    }

    return $azureRestAssemblyPath
}

<#
.DESCRIPTION
  Ensures the Microsoft.Rest.ClientRuntime.Azure package is installed.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.
#>
function Install-MicrosoftRestAzurePackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredVersion
    )

    $params = @{
        Name='Microsoft.Rest.ClientRuntime.Azure'
        ProviderName='NuGet'
        ForceBootstrap = $true
        Verbose = $false
        Debug = $false
    }

    if ($RequiredVersion) {
        $params['RequiredVersion'] = $RequiredVersion
    }

    $package = Get-Package @params -ErrorAction Ignore | Select-Object -First 1 -ErrorAction Ignore

    if (-not $package) {
        $NuGetSourceName = Get-NugetPackageSource
        $IsNuGetSourceRegistered = $false
        if (-not $NuGetSourceName) {
            $NuGetSourceName = Register-NugetPackageSource

            if($NuGetSourceName)
            {
                $IsNuGetSourceRegistered = $true
            }
            else
            {
                # Register-PackageSource should fail with an error
                return
            }
        }

        try
        {
            $null = Find-Package @params -Source $NuGetSourceName | 
                        Install-Package -Force `
                                        -Scope CurrentUser `
                                        -Verbose:$false `
                                        -Debug:$false `
                                        -Confirm:$false `
                                        -WhatIf:$false

            $package = Get-Package @params | Select-Object -First 1 -ErrorAction Ignore
        }
        finally
        {
            if ($IsNuGetSourceRegistered) {
                $null = Unregister-PackageSource -Name $NuGetSourceName `
                                                 -Verbose:$false `
                                                 -Debug:$false `
                                                 -WhatIf:$false `
                                                 -Confirm:$false
            }
        }
    }

    return $package
}

<#
.DESCRIPTION
  Get a NuGet package source with location nuget.org/api/v2.
#>
function Get-NugetPackageSource
{
    Get-PackageSource -Provider NuGet `
                      -ForceBootstrap `
                      -Verbose:$false `
                      -Debug:$false |
        Where-Object { $_.Location -match 'nuget.org/api/v2' } |
            Select-Object -First 1 -ErrorAction Ignore |
                Foreach-Object {$_.Name}
}

<#
.DESCRIPTION
  Creates a temporary NuGet package source with given location.

.PARAMETER  Location
  Location of NuGet package source. Defaults to 'https://nuget.org/api/v2'.
#>
function Register-NugetPackageSource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $Location = 'https://nuget.org/api/v2'
    )

    $SourceName = "PSSwaggerNuGetSource_$([System.Guid]::NewGuid())"

    $params = @{
        Name = $SourceName
        Location = $Location
        ProviderName = 'NuGet'
        ForceBootstrap = $true
        Verbose = $false
        Debug = $false
        Confirm = $false
        WhatIf = $false
    }

    if(Register-PackageSource @params)
    {
        return $SourceName
    }
}

<#
.DESCRIPTION
  Get PowerShell Common parameter/preference values.

.PARAMETER  CallerPSBoundParameters
  PSBoundParameters of the caller.
#>
function Get-PSCommonParameters
{
    param(
        [Parameter(Mandatory=$true)]
        $CallerPSBoundParameters
    )

    $VerbosePresent = $false
    if (-not $CallerPSBoundParameters.ContainsKey('Verbose'))
    {
        if($VerbosePreference -in 'Continue','Inquire')
        {
            $VerbosePresent = $true
        }
    }
    else
    {
        $VerbosePresent = $true
    }

    $DebugPresent = $false
    if (-not $CallerPSBoundParameters.ContainsKey('Debug'))
    {
        if($debugPreference -in 'Continue','Inquire')
        {
            $DebugPresent = $true
        }
    }
    else
    {
        $DebugPresent = $true
    }

    if(Test-Path variable:\errorActionPreference)
    {
        $errorAction = $errorActionPreference
    }
    else
    {
        $errorAction = 'Continue'
    }

    if ($CallerPSBoundParameters['ErrorAction'] -eq 'SilentlyContinue')
    {
        $errorAction = 'SilentlyContinue'
    }

    if($CallerPSBoundParameters['ErrorAction'] -eq 'Ignore')
    {
        $errorAction = 'SilentlyContinue'
    }

    if ($CallerPSBoundParameters['ErrorAction'] -eq 'Inquire')
    {
        $errorAction = 'Continue'
    }

    if(Test-Path variable:\warningPreference)
    {
        $warningAction = $warningPreference
    }
    else
    {
        $warningAction = 'Continue'
    }

    if ($CallerPSBoundParameters['WarningAction'] -in 'SilentlyContinue','Ignore')
    {
        $warningAction = 'SilentlyContinue'
    }

    if ($CallerPSBoundParameters['WarningAction'] -eq 'Inquire')
    {
        $warningAction = 'Continue'
    }

    return @{
        Verbose = $VerbosePresent
        Debug = $DebugPresent
        WarningAction = $warningAction
        ErrorAction = $errorAction
    }    
}
