Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
  Ensures all dependencies required for running tests are present on the current machine.
#>
function Initialize-BuildDependency {
    [CmdletBinding()]
    param()

    $expectedDotNetVersion = "2.1.0-preview1-006547"
    Write-Host "Setting up PSSwagger.LiveTestFramework.Build dependencies:"
    Write-Host "    dotnet: $expectedDotnetVersion"
    Write-Host "    PSSwaggerUtility: *"
    Write-Host ""
    $failed = Setup-PSSwaggerUtility
    if (-not $failed) {
        Initialize-PSSwaggerDependencies
        Import-Module -Name PSSwaggerUtility
        $r = Setup-DotNet | Select-Object -Last 1
        $failed = $failed -or $r
    }

    if ($failed) {
        Write-Error -Message 'One or more dependencies failed to intialize.'
    } else {
        Write-Host "Completed setting up PSSwagger.LiveTestFramework.Build dependencies." -BackgroundColor DarkGreen
    }

    $failed
}

<#
.DESCRIPTION
  Build PSSwagger LiveTestFramework Console Server and libraries using dotnet CLI.
  Optionally copies binaries to OutputDirectory parameter value if available.
#>
function Invoke-Build {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet('net452')]
        $Framework = 'net452',

        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet('Debug','Release')]
        $Configuration = 'Debug',

        [Parameter(Mandatory=$false)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [switch]
        $CleanOutputDirectory
    )

    Initialize-BuildDependency
    if ($OutputDirectory -and $CleanOutputDirectory -and (Test-Path -Path $OutputDirectory -PathType Container)) {
        Remove-Item -Path $OutputDirectory -Recurse
    }

    if ($OutputDirectory -and (-not (Test-Path -Path $OutputDirectory -PathType Container))) {
        $null = New-Item -Path $OutputDirectory -ItemType Directory
    }

    $cache = @{}
    Get-ChildItem -Path (Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "src" | Join-Path -ChildPath "*.csproj") -File -Recurse | ForEach-Object {
        # Execute only if it's a Microsoft.NET.SDK project
        if ((Get-Content -Path $_.FullName | Out-String).Contains("<Project Sdk=`"Microsoft.NET.Sdk`"")) {
            $built = Start-BuildDotNetProject -Project $_ -Framework $Framework -Configuration $Configuration `
                               -ProjectCache $cache `
                               -Clean -Publish
            if ($built -and $OutputDirectory) {
                $src = (Join-Path -Path $_.DirectoryName -ChildPath "bin" | 
                    Join-Path -ChildPath $Configuration |
                    Join-Path -ChildPath $Framework |
                    Join-Path -ChildPath "publish" |
                    Join-Path -ChildPath "*")
                Write-Verbose -Message "Copying files from '$src' to '$OutputDirectory'"
                Copy-Item -Path $src -Destination $OutputDirectory -Force
            }
        }
    }
}

function Start-BuildDotNetProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]
        $Project,

        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet('net452')]
        $Framework = 'net452',

        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet('Debug','Release')]
        $Configuration = 'Debug',

        [Parameter(Mandatory=$false)]
        [switch]
        $Clean,

        [Parameter(Mandatory=$false)]
        [switch]
        $Publish,

        [Parameter(Mandatory=$false)]
        [switch]
        $Test,

        [Parameter(Mandatory=$false)]
        [string]
        $TestLogger,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $ProjectCache
    )

    Write-Verbose -Message "Building project: $($Project.FullName)"
    $build = $true
    pushd $Project.DirectoryName
    if ($ProjectCache) {
        if ($ProjectCache.ContainsKey("$($Project.FullName)")) {
            Write-Verbose -Message "Skipping project (already built)"
            $build = $false
        }
        if ($build) {
            $projectRefs = Select-Xml -Path $Project.FullName -XPath "/Project/ItemGroup/ProjectReference" | 
                Select-Object -ExpandProperty Node |
                Select-Object -ExpandProperty Include |
                Resolve-Path
            foreach ($projectRef in $projectRefs) {
                Write-Verbose -Message "Skipping this project in the future (will still build in this pass): $projectRef"
                $ProjectCache["$projectRef"] = $true
            }
        }
    }

    if ($build) {
        if ($Clean) {
            dotnet clean | Write-Verbose
        }
        dotnet restore | Write-Verbose
        dotnet build --framework $Framework | Write-Verbose
        if ($Publish) {
            dotnet publish --framework $Framework | Write-Verbose
        }
        if ($Test) {
            if ($TestLogger) {
                dotnet test --framework $Framework --logger $TestLogger | Write-Verbose
            } else {
                dotnet test --framework $Framework | Write-Verbose
            }
        }
    }
    popd
    return $build
}

function Setup-PSSwaggerUtility {
    [CmdletBinding()]
    param()

    if (-not (Get-Module -Name PSSwaggerUtility -ListAvailable)) {
        $p = Find-Package -Name PSSwaggerUtility -Source PSGallery -ProviderName PowerShellGet
        if (-not $p) {
            Write-Error -Message "Couldn't find PSSwaggerUtility package. Run 'Find-Package PSSwaggerUtility -Source PSGallery -ProviderName PowerShellGet' to see error messages or recommended actions."
            return $true
        }

        $p | Install-Package -Scope CurrentUser
        if (-not (Get-Module -Name PSSwaggerUtility -ListAvailable)) {
            Write-Error -Message "Couldn't install PSSwaggerUtility package. Run 'Install-Package PSSwaggerUtility -Source PSGallery -ProviderName PowerShellGet -Scope CurrentUser' to see error messages or recommended actions."
            return $true
        }
    }

    return $false
}

function Setup-DotNet {
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
        Write-Verbose -Message "dotnet not found in path. Attempting to add the expected dotnet CLI path."
        $originalPath = $env:PATH
        $dotnetPath = Get-DotNetPath
        $env:PATH = $dotnetPath + [IO.Path]::PathSeparator + $env:PATH

        if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
            $env:PATH = $originalPath
            Write-Verbose -Message "None of that worked! Re-bootstrapping dotnet CLI."
            Install-Dotnet -Version $expectedDotNetVersion
        } else {
            $dotnetversion = dotnet --version
            if ($dotnetversion -ne $expectedDotNetVersion) {
                Write-Verbose -Message "Unsupported dotnet version found: $dotnetversion. Downloading dotnet CLI."
                Install-Dotnet -Version $expectedDotNetVersion
            }
        }
    } else {
        $dotnetversion = dotnet --version
        if ($dotnetversion -ne $expectedDotNetVersion) {
            Write-Verbose -Message "Unsupported dotnet version found: $dotnetversion. Attempting to add the expected dotnet CLI path."
            $originalPath = $env:PATH
            $dotnetPath = Get-DotNetPath
            $env:PATH = $dotnetPath + [IO.Path]::PathSeparator + $env:PATH
            if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
                $env:PATH = $originalPath
                Write-Verbose -Message "None of that worked! Re-bootstrapping dotnet CLI."
                Install-Dotnet -Version $expectedDotNetVersion
            } else {
                $dotnetversion = dotnet --version
                if ($dotnetversion -ne $expectedDotNetVersion) {
                    Write-Verbose -Message "Unsupported dotnet version found: $dotnetversion. Downloading dotnet CLI."
                    Install-Dotnet -Version $expectedDotNetVersion
                }
            }
        }
    }

    if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
        Write-Error -Message 'Failed to set up dotnet dependency.'
        return $true
    }

    return $false
}

<#
.DESCRIPTION
  Downloads dotnet CLI and adds it to the path.
#>
function Install-Dotnet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Channel = "preview",
        [Parameter(Mandatory=$false)]
        [string]$Version = "2.0.0-preview1-005952"
    )

    $osInfo = PSSwaggerUtility\Get-OperatingSystemInfo
    $obtainUrl = "https://raw.githubusercontent.com/dotnet/cli/master/scripts/obtain"

    # Install for Linux and Mac OS
    if ($osInfo.IsLinux -or $osInfo.IsMacOS) {
        $LinuxInfo = Get-Content /etc/os-release -Raw | ConvertFrom-StringData
        $IsUbuntu = $LinuxInfo.ID -match 'ubuntu'

        # Uninstall all previous dotnet packages
        $uninstallScript = if ($IsUbuntu) {
            "dotnet-uninstall-debian-packages.sh"
        } elseif ($osInfo.IsMacOS) {
            "dotnet-uninstall-pkgs.sh"
        }

        if ($uninstallScript) {
            Start-NativeExecution {
                curl -sO $obtainUrl/uninstall/$uninstallScript
                bash ./$uninstallScript
            }
        } else {
            Write-Warning "This script only removes prior versions of dotnet for Ubuntu 14.04 and OS X"
        }

        $installScript = "dotnet-install.sh"
        Start-NativeExecution {
            curl -sO $obtainUrl/$installScript
            bash ./$installScript -c $Channel -v $Version
        }
    } elseif ($osInfo.IsWindows) {
        Remove-Item -ErrorAction SilentlyContinue -Recurse -Force ~\AppData\Local\Microsoft\dotnet
        $installScript = "dotnet-install.ps1"
        Invoke-WebRequest -Uri $obtainUrl/$installScript -OutFile $installScript
        & ./$installScript -Channel $Channel -Version $Version
    }

    $originalPath = $env:PATH
    $dotnetPath = Get-DotNetPath

    if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
        Write-Verbose -Message "dotnet not found in path. Adding downloaded dotnet to path."
        $env:PATH = $dotnetPath + [IO.Path]::PathSeparator + $env:PATH
    }

    if (-not (Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
        Write-Error -Message "dotnet failed to be added to path. Restoring original."
        $env:PATH = $originalPath
    }
}

<#
.DESCRIPTION
  Gets the expected dotnet CLI location.
#>
function Get-DotNetPath
{
    [CmdletBinding()]
    param()

    $osInfo = PSSwaggerUtility\Get-OperatingSystemInfo
    if ($osInfo.IsWindows) {
        $path = "$env:LocalAppData\Microsoft\dotnet"
    } else {
        $path = "$env:HOME/.dotnet"
    }

    Write-Verbose -Message "dotnet CLI path: $path"
    $path
}

<#
.DESCRIPTION
  Executes a script block.
#>
function script:Start-NativeExecution([scriptblock]$sb, [switch]$IgnoreExitcode)
{
    $backupEAP = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    try {
        & $sb
        # note, if $sb doesn't have a native invocation, $LASTEXITCODE will
        # point to the obsolete value
        if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
            throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
        }
    } finally {
        $script:ErrorActionPreference = $backupEAP
    }
}

Export-ModuleMember -Function Initialize-BuildDependency,Invoke-Build,Start-BuildDotNetProject
