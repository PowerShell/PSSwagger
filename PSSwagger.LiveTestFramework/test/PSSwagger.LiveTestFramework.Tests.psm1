Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
  Ensures all dependencies required for running tests are present on the current machine.
#>
function Initialize-Dependencies {
    [CmdletBinding()]
    param()

    $failed = $false
    $expectedDotNetVersion = "2.1.0-preview1-006547"#"2.0.0-preview1-005952" 
    Write-Host "Setting up PSSwagger.LiveTestFramework.Tests dependencies:"
    Write-Host "    dotnet: $expectedDotnetVersion"
    Write-Host "    Pester: *"
    Write-Host ""
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
        $failed = $true
    }

    if (-not (Get-Command Invoke-Pester)) {
        $pesterModule = Get-Module Pester -ListAvailable | Select-Object -First 1
        if (-not $pesterModule) {
            $pesterModule = Find-Package Pester | Select-Object -First 1
            if (-not $pesterModule) {
                Write-Error -Message 'Failed to find Pester modules online. Run Get-PackageSource. If you do not have PowerShell Gallery set up as a source, you can run: Register-PackageSource -Name PSGallery -Location https://www.powershellgallery.com/api/v2/ -ProviderName PowerShellGet. Afterwards, try rerunning this command.'
                $failed = $true
            } else {
                $pesterModule | Install-Package
                $pesterModule = Get-Module Pester -ListAvailable | Select-Object -First 1
                if (-not $pesterModule) {
                    Write-Error -Message 'Installation of Pester must have failed. See previous errors, if any.'
                    $failed = $true
                }
            }
        }

        if ($pesterModule) {
            Write-Verbose -Message "Found Pester module: $($pesterModule.Version)"
        } else {
            # In case we somehow fall here
            Write-Error -Message 'No Pester module found and installation failed or did not run. See previous errors, if any.'
            $failed = $true
        }
    } else {
        Write-Verbose -Message "Pester already installed: $((Get-Module Pester -ListAvailable | Select-Object -First 1).Version)"
    }

    if ($failed) {
        Write-Error -Message 'One or more dependencies failed to intialize.'
    } else {
        Write-Host "Completed setting up PSSwagger.LiveTestFramework.Tests dependencies." -BackgroundColor DarkGreen
    }
}

<#
.DESCRIPTION
  Initiates a test run. Also calls Initialize-Dependencies
#>
function Start-Run {
    [CmdletBinding()]
    param(
        [ValidateSet('Pester','CSharp','All')]
        [string]
        $TestType = 'All'
    )

    # Currently running PowerShell in-process isn't supported in PowerShell Core, so we currently only support full CLR
    $Framework = 'net452'
    Write-Host "Test run for framework: $Framework" -BackgroundColor DarkYellow
    Initialize-Dependencies

    $runCSharp = ($TestType -eq 'All') -or ($TestType -eq 'CSharp')
    $runPester = ($TestType -eq 'All') -or ($TestType -eq 'Pester')

    # Ensure C# files exist
    $wasCSharp = $false
    Write-Host "Transforming code files into C# before executing unit tests"
    pushd (Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath 'src')
    if (Get-ChildItem -Path (Join-Path -Path . -ChildPath "*.cs") -Recurse -File) {
        Write-Verbose "Original files were C# files"
        $wasCSharp = $true
    }
    .\ConvertTo-CSharpFiles.ps1
    popd
    $trxLogs = @()
    $pesterLogs = @()
    if ($runCSharp)
    {
        Write-Host "Discovering and running C# projects"
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "*.csproj") -File -Recurse | ForEach-Object {
            # Execute only if it's a Microsoft.NET.SDK project
            if ((Get-Content -Path $_.FullName | Out-String).Contains("<Project Sdk=`"Microsoft.NET.Sdk`"")) {
                Write-Verbose "Executing test project: $($_.FullName)"
                pushd $_.DirectoryName
                $trxLogPath = Join-Path -Path $_.DirectoryName -ChildPath "Results" | Join-Path -ChildPath $Framework
                if (-not (Test-Path -Path $trxLogPath)) {
                    $null = New-Item -Path $trxLogPath -ItemType Container -Force
                }

                $trxLogFile = Join-Path -Path $trxLogPath -ChildPath "$($_.BaseName).trx"
                if (Test-Path -Path $trxLogFile) {
                    $null = Remove-Item -Path $trxLogFile
                }

                $trxLogs += $trxLogFile
                dotnet restore
                dotnet build --framework $Framework
                dotnet publish --framework $Framework
                dotnet test --framework $Framework --logger "trx;LogFileName=$trxLogFile"
                popd
            }
        }
    }

    if ($runPester)
    {
        # Transform back into .Code.ps1 for the PowerShell module
        Write-Host "Transforming C# into code files before executing PowerShell tests"
        pushd (Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath 'src')
        .\ConvertFrom-CSharpFiles.ps1
        popd
        Write-Host "Running tests under Pester folder"
        pushd (Join-Path -Path $PSScriptRoot -ChildPath Pester)
        powershell -command "& {Invoke-Pester -ExcludeTag KnownIssue -OutputFormat NUnitXml -OutputFile PesterResults.xml}"
        $pesterLogs += (Get-Item -Path PesterResults.xml).FullName
        popd
    }

    if ($wasCSharp) {
        pushd (Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath 'src')
        .\ConvertTo-CSharpFiles.ps1
        popd
    }
    
    Write-Host "`n`n"
    Write-Host "Test result files:"
    $totalTests = 0
    $executedTests = 0
    $passedTests = 0
    $failedTests = 0
    $otherResultsTests = 0
    foreach ($logFile in $trxLogs) {
        Write-Host "   - $logFile"
        if (-not (Test-Path -Path $logFile))
        {
            Write-Error "Log file doesn't exist. Did the test run work?"
            $totalTests++
        } else 
        {
            [xml]$xml = Get-Content -Path $logFile
            $totalTests += $xml.TestRun.ResultSummary.Counters.Total
            $executedTests += $xml.TestRun.ResultSummary.Counters.Executed
            $passedTests += $xml.TestRun.ResultSummary.Counters.Passed
            $failedTests += $xml.TestRun.ResultSummary.Counters.Failed
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Error
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Timeout
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Aborted
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Inconclusive
            $passedTests += $xml.TestRun.ResultSummary.Counters.PassedButRunAborted
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.NotRunnable
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.NotExecuted
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Disconnected
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Warning
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Completed
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.InProgress
            $otherResultsTests += $xml.TestRun.ResultSummary.Counters.Pending
        }
    }

    foreach ($logFile in $pesterLogs) {
        Write-Host "   - $logFile"
        if (-not (Test-Path -Path $logFile))
        {
            Write-Error "Log file doesn't exist. Did the test run work?"
            $totalTests++
        } else 
        {
            [xml]$xml = Get-Content -Path $logFile
            $totalTests += $xml.'test-results'.total
            $executedTests += $xml.'test-results'.total
            $passedTests += $xml.'test-results'.total - $xml.'test-results'.failures - $xml.'test-results'.errors - $xml.'test-results'.'not-run' `
                - $xml.'test-results'.inconclusive - $xml.'test-results'.ignored - $xml.'test-results'.skipped - $xml.'test-results'.invalid
            $failedTests += $xml.'test-results'.failures
            $failedTests += $xml.'test-results'.errors
            $otherResultsTests += $xml.'test-results'.'not-run'
            $otherResultsTests += $xml.'test-results'.inconclusive
            $otherResultsTests += $xml.'test-results'.ignored
            $otherResultsTests += $xml.'test-results'.skipped
            $otherResultsTests += $xml.'test-results'.invalid
        }
    }
    Write-Host "`n`n"
    Write-Host "Total: $totalTests" -BackgroundColor DarkCyan
    Write-Host "Executed: $executedTests" -BackgroundColor DarkCyan
    Write-Host "Passed: $passedTests" -BackgroundColor DarkGreen
    Write-Host "Failed: $failedTests" -BackgroundColor DarkRed
    Write-Host "Inconclusive: $otherResultsTests" -BackgroundColor DarkRed

    Write-Host "`n`n"
    if ($passedTests -eq $totalTests) {
        Write-Host "Test run passed!" -BackgroundColor DarkGreen
        $true
    } else {
        Write-Host "Test run failed." -BackgroundColor DarkRed
        $false
    }
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

    # Install for Linux and OS X
    if ($osInfo.IsLinux -or $osInfo.IsOSX) {
        $LinuxInfo = Get-Content /etc/os-release -Raw | ConvertFrom-StringData
        $IsUbuntu = $LinuxInfo.ID -match 'ubuntu'

        # Uninstall all previous dotnet packages
        $uninstallScript = if ($IsUbuntu) {
            "dotnet-uninstall-debian-packages.sh"
        } elseif ($osInfo.IsOSX) {
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

Export-ModuleMember -Function Initialize-Dependencies,Start-Run