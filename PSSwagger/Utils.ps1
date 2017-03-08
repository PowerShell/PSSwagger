Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

$script:CorePsEditionConstant = 'Core'
# go fwlink for latest nuget.exe for win10 x86
$script:NuGetClientSourceURL = 'https://go.microsoft.com/fwlink/?linkid=843467'
$script:ProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PSSwagger\'
$script:AppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PSSwagger\'
$script:LocalToolsPath = $null
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

.PARAMETER  AllUsers
  User wants to install local tools for all users.

.PARAMETER  BootstrapConsent
  User has consented to bootstrap dependencies.
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
        $RequiredAzureRestVersion,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent
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

    if ($CorePsEditionConstant -eq (Get-PSEdition)) {
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
            AllUsers = $AllUsers
            BootstrapConsent = $BootstrapConsent
        }

        if($RequiredAzureRestVersion)
        {
            $Params['RequiredVersion'] = $RequiredAzureRestVersion
        }

        $azureRestAssemblyPath = Get-MicrosoftRestAzureReference @Params

        if($azureRestAssemblyPath)
        {
            $extraRefs += $azureRestAssemblyPath
        } else {
            return $false
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

.PARAMETER  AllUsers
  User wants to install local tools for all users.

.PARAMETER  BootstrapConsent
  User has consented to bootstrap dependencies.
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
        $RequiredVersion,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent
    )

    $azureRestAssemblyPath = Join-Path -Path $ClrPath -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'
    if (-not (Test-Path -Path $azureRestAssemblyPath)) {
        # Get the assembly from the NuGet package dynamically, then save it locally
        $package = Install-MicrosoftRestAzurePackage -RequiredVersion $RequiredVersion -AllUsers:$AllUsers -BootstrapConsent:$BootstrapConsent
        if($package)
        {
            $azureRestAssemblyPathNuget = Join-Path -Path $package.Location -ChildPath 'lib' | 
                                              Join-Path -ChildPath $Framework | 
                                                  Join-Path -ChildPath 'Microsoft.Rest.ClientRuntime.Azure.dll'

            if (-not (Test-Path -Path $ClrPath)){
                $null = New-Item -Path $ClrPath -ItemType Directory
            }

            $null = Copy-Item -Path $azureRestAssemblyPathNuget -Destination $azureRestAssemblyPath -Force
        } else {
            return ''
        }
    }

    return $azureRestAssemblyPath
}

<#
.DESCRIPTION
  Ensures the Microsoft.Rest.ClientRuntime.Azure package is installed.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.

.PARAMETER  AllUsers
  User wants to install local tools for all users.

.PARAMETER  BootstrapConsent
  User has consented to bootstrap dependencies.
#>
function Install-MicrosoftRestAzurePackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredVersion,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent
    )

    if (Test-Downlevel) {
        return Install-MicrosoftRestAzurePackageWithNuget -RequiredVersion $RequiredVersion -BootstrapConsent:$BootstrapConsent
    } else {
        return Install-MicrosoftRestAzurePackageWithPackageManagement -RequiredVersion $RequiredVersion -AllUsers:$AllUsers
    }
}

<#
.DESCRIPTION
  Initialize script variables pointing to local tools, prompting for download and downloading if not present.

.PARAMETER  AllUsers
  User wants to install local tools for all users.

.PARAMETER  Precompiling
  Initialize local tools required for compilation.
#>
function Initialize-LocalTools {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers,

        [Parameter(Mandatory=$false)]
        [switch]
        $Precompiling
    )

    Initialize-LocalToolsVariables -AllUsers:$AllUsers

    $bootstrapActions = @()
    $bootstrapPrompts = @()
    if ((Test-Downlevel) -and $Precompiling) {
        $expectedPath = Get-MicrosoftRestAzureNugetPackagePath
        if (-not $expectedPath) {
            $nugetExePath = Get-NugetExePath
            if (-not (Get-Command $nugetExePath -ErrorAction Ignore)) {
                $bootstrapPrompts += $UtilsLocalizedData.NugetBootstrapPrompt -f ($script:NuGetClientSourceURL)
                $bootstrapActions += { 
                    param()
                    Write-Verbose -Message $UtilsLocalizedData.NugetBootstrapDownload
                    $null = Invoke-WebRequest -Uri $script:NuGetClientSourceURL `
                                              -OutFile $nugetExePath
                }
            }

            $bootstrapPrompts += $UtilsLocalizedData.AzureRestBootstrapPrompt
            $bootstrapActions += { 
                param()
                Write-Verbose $UtilsLocalizedData.AzureRestBootstrapDownload
            } 
        }
    }

    $consent = $false
    if ($bootstrapPrompts.Length -gt 0) {
        $prompt = $bootstrapPrompts -join [Environment]::NewLine

        $consent = $PSCmdlet.ShouldContinue($UtilsLocalizedData.BootstrapConfirmTitle, $prompt)
        if ($consent) {
            for ($i = 0; $i -lt $bootstrapActions.Length; $i++) {
                $null = $bootstrapActions[$i].Invoke()
            }
        }
    }

    return $consent
}

<#
.DESCRIPTION
  Initialize script variables pointing to local tools, prompting for download and downloading if not present.

.PARAMETER  AllUsers
  User wants to install local tools for all users.
#>
function Initialize-LocalToolsVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers
    )

    if ($AllUsers) {
        $script:LocalToolsPath = $script:ProgramDataPath
    } else {
        $script:LocalToolsPath = $script:AppLocalPath
    }

    if (-not (Test-Path -Path $script:LocalToolsPath)) {
        $null = New-Item -Path $script:LocalToolsPath `
                         -ItemType Directory -Force `
                         -ErrorAction SilentlyContinue `
                         -WarningAction SilentlyContinue `
                         -Confirm:$false `
                         -WhatIf:$false
    }
}

<#
.DESCRIPTION
  Initialize script variables pointing to local tools, prompting for download and downloading if not present.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.

.PARAMETER  AllUsers
  User wants to install local tools for all users.
#>
function Install-MicrosoftRestAzurePackageWithPackageManagement
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredVersion,

        [Parameter(Mandatory=$false)]
        [switch]
        $AllUsers
    )

    $params = @{
        Name='Microsoft.Rest.ClientRuntime.Azure'
        ProviderName='NuGet'
        ForceBootstrap = $true
        Verbose = $false
        Debug = $false
    }

    $installParams = @{
        Force = $true
        Verbose = $false
        Debug = $false
        Confirm = $false
        WhatIf = $false
    }

    if (-not $AllUsers) {
        $installParams['Scope'] = 'CurrentUser'
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
                        Install-Package @installParams

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

    $packageProps = @{
        Name = $package.Name;
        Version = $package.Version;
        Location = (Split-Path -Path $package.Source -Parent)
    }

    return New-Object -TypeName PSObject -Property $packageProps
}

<#
.DESCRIPTION
  Finds the local Microsoft.Rest.ClientRuntime.Azure package and downloads it if missing.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.

.PARAMETER  BootstrapConsent
  User has accepted bootstrapping missing dependencies.
#>
function Install-MicrosoftRestAzurePackageWithNuget
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredVersion,

        [Parameter(Mandatory=$false)]
        [switch]
        $BootstrapConsent
    )

    $path = Get-MicrosoftRestAzureNugetPackagePath -RequiredVersion $RequiredVersion
    if (-not $path) {
        $nugetExePath = Get-NugetExePath
        if (-not (Get-Command $nugetExePath -ErrorAction Ignore)) {
            # Should be downloaded by now, let's not copy the code - just throw an error
            # This also happens when the user didn't want to bootstrap nuget.exe
            throw $UtilsLocalizedData.NugetMissing
        }

        if ($BootstrapConsent) {
            $nugetArgs = "install Microsoft.Rest.ClientRuntime.Azure -noninteractive -outputdirectory `"$script:LocalToolsPath`" -source https://nuget.org/api/v2 -verbosity detailed"
            if ($RequiredVersion) {
                $nugetArgs += " -version $RequiredVersion"
            }

            $stdout = Invoke-Expression "& `"$nugetExePath`" $nugetArgs"
            Write-Verbose -Message ($UtilsLocalizedData.NuGetOutput -f ($stdout))
            if ($LastExitCode) {
                return
            }

            $path = Get-MicrosoftRestAzureNugetPackagePath -RequiredVersion $RequiredVersion
        } else {
            throw $UtilsLocalizedData.AzureRestMissing
        }
    }

    $versionMatch = [Regex]::Match($path, "(.+?)(Microsoft[.]Rest[.]ClientRuntime[.]Azure[.])([0-9.]*).*")
    $packageProps = @{
        Name = 'Microsoft.Rest.ClientRuntime.Azure';
        Version = $versionMatch.Groups[3].Value;
        Location = $path
    }

    return New-Object -TypeName PSObject -Property $packageProps
}

<#
.DESCRIPTION
  Gets the expected path of the local Microsoft.Rest.ClientRuntime.Azure nuget package.

.PARAMETER  RequiredVersion
  Optional string specifying required version of Microsoft.Rest.ClientRuntime.Azure package.
#>
function Get-MicrosoftRestAzureNugetPackagePath {
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $RequiredVersion
    )

    $outputSubPath = "Microsoft.Rest.ClientRuntime.Azure"
    if ($RequiredVersion) {
        $outputSubPath += ".$RequiredVersion"
    }

    $path = (Get-ChildItem -Path (Join-Path -Path $script:LocalToolsPath -ChildPath "$outputSubPath*") | Select-Object -First 1 | ForEach-Object FullName)
    return $path
}

function Get-NugetExePath {
    if ((Get-Command nuget.exe -ErrorAction Ignore)) {
        return "nuget.exe"
    }

    return (Join-Path -Path $script:LocalToolsPath -ChildPath "nuget.exe")
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

    if ($PSVersionTable.PSVersion -lt '5.0.0') {
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
            $hasher = New-Object $hasherType
        } else {
            # Check if the type is supported in the current system
            $algorithmType = "System.Security.Cryptography.${Algorithm}" -as [Type]
            if ($algorithmType) {
                if ($Algorithm -eq "MACTripleDES") {
                    $hasher = New-Object $algorithmType
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

<#
.DESCRIPTION
  Tests if current PowerShell session is considered downlevel.
#>
function Test-Downlevel {
    return ($PSVersionTable.PSVersion -lt '5.0.0')
}

<#
.DESCRIPTION
  Finds local MSI installations.

.PARAMETER  Name
  Name of MSIs to find. Supports * wildcard.

.PARAMETER  MaximumVersion
  Maximum version of MSIs to find.
#>
function Get-Msi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$false)]
        [string]
        $MaximumVersion
    )

    if (Test-Downlevel) {
        return Get-MsiWithWmi -Name $Name -MaximumVersion $MaximumVersion
    } else {
        return Get-MsiWithPackageManagement -Name $Name -MaximumVersion $MaximumVersion
    }
}

<#
.DESCRIPTION
  Finds local MSI installations using WMI.

.PARAMETER  Name
  Name of MSIs to find. Supports * wildcard.

.PARAMETER  MaximumVersion
  Maximum version of MSIs to find.
#>
function Get-MsiWithWmi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$false)]
        [string]
        $MaximumVersion
    )

    $wqlNameFilter = $Name.Replace('*', '%')
    $filter = "Name like '$wqlNameFilter'"
    if ($MaximumVersion) {
        $filter += " AND Version <= '$MaximumVersion'"
    }

    $products = Get-WmiObject -Class Win32_Product -Filter $filter
    $returnObjects = @()
    $products | ForEach-Object {
        $objectProps = @{
            'Name'=$_.Name;
            'Version'=$_.Version
        }

        $returnObjects += (New-Object -TypeName PSObject -Prop $objectProps)
    }

    return $returnObjects
}

<#
.DESCRIPTION
  Finds local MSI installations using PackageManagement.

.PARAMETER  Name
  Name of MSIs to find. Supports * wildcard.

.PARAMETER  MaximumVersion
  Maximum version of MSIs to find.
#>
function Get-MsiWithPackageManagement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$false)]
        [string]
        $MaximumVersion
    )

    $products = Get-Package -Name $Name `
                            -MaximumVersion $MaximumVersion `
                            -ProviderName msi `
                            -Verbose:$false `
                            -Debug:$false
    $returnObjects = @()
    $products | ForEach-Object {
        $objectProps = @{
            'Name'=$_.Name;
            'Version'=$_.Version
        }

        $returnObjects += (New-Object -TypeName PSObject -Prop $objectProps)
    }

    return $returnObjects
}