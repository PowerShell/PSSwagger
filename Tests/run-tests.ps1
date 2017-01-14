param(
    [ValidateSet("All","UnitTest","ScenarioTest")]
    [string[]]$TestSuite = "All",
    [string[]]$TestName,
    [ValidateSet("net452", "netstandard1.6")]
    [string]$TestFramework = "net452",
    [ValidateSet("win10-x64")]
    [string]$Runtime = "win10-x64",
    [switch]$SkipBootstrap
)

$executeTestsCommand = ""

# Import test utilities
Import-Module "$PSScriptRoot\TestUtilities.psm1" -Force
$nugetPackageSource = Test-NugetPackageSource

# Set up scenario test requirements
if ($TestSuite.Contains("All") -or $TestSuite.Contains("ScenarioTest")) {
    # Ensure node.js is installed
    $nodejsModule = Test-Package -packageName "Node.JS" -packageSourceName $nugetPackageSource.Name
    if ($nodejsModule -eq $null) {
        throw "Node.JS failed to install."
    }

    $nodejsInstallPath = Split-Path -Path $nodejsModule.Source
    # Ensure npm is installed
    $npmModule = Test-Package -packageName "Npm" -packageSourceName $nugetPackageSource.Name
    if ($npmModule -eq $null) {
        throw "NPM failed to install."
    }

    $npmInstallPath = Split-Path -Path $npmModule.Source

    # Ensure the location exists where we keep node and node modules
    $nodeModulePath = Join-Path -Path $PSScriptRoot -ChildPath "NodeModules"
    $nodeExePath = Join-Path -Path $nodeModulePath -ChildPath "node.exe"
    $jsonServerPath = Join-Path -Path $nodeModulePath -ChildPath "json-server.cmd"
    if (-not (Test-Path $nodeModulePath)) {
        Write-Verbose "Creating local node modules directory $nodeModulePath"
        New-Item -Path $nodeModulePath -ItemType Directory -Force 
    }

    # Let's copy node.exe to the other directory so we can keep everything in one place
    if (-not (Test-Path $nodeExePath)) {
        Write-Verbose "Copying node.exe from NuGet package to $nodeExePath"
        Copy-Item -Path (Join-Path -Path $nodejsInstallPath -ChildPath "node.exe") -Destination $nodeExePath
    }

    # Ensure we have json-server
    if (-not (Test-Path $jsonServerPath)) {
        Write-Verbose "Couldn't find $jsonServerPath. Running npm install -g json-server."
        & $nodeExePath (Join-Path -Path $npmInstallPath -ChildPath "node_modules\npm\bin\npm-cli.js") "install" "-g" "json-server"
    }

    $executeTestsCommand += ";`$env:Path+=`";$nodeModulePath`""

    # Build PSSwagger.Test.dll using dotnet CLI
    if ($SkipBootstrap -eq $false) {
        & "$PSScriptRoot\..\tools\bootstrap.ps1"
    }

    Push-Location "PSSwagger.TestUtilities"
    dotnet restore
    dotnet -v build
    dotnet publish
    Pop-Location

    $testCredsAsmLocation = "$PSScriptRoot\PSSwagger.TestUtilities\bin\Debug\$TestFramework\$Runtime\publish"
    $executeTestsCommand += ";Add-Type -Path $testCredsAsmLocation\PSSwagger.TestUtilities.dll"
}

# Set up AutoRest
$autoRestModule = Test-Package -packageName "AutoRest" -packageSourceName $nugetPackageSource.Name
$autoRestInstallPath = Split-Path -Path $autoRestModule.Source
$executeTestsCommand += ";`$env:Path+=`";$autoRestInstallPath\tools`""

if ($TestFramework -eq "netstandard1.6") {
    # TODO: Find PowerShell Core folder and Pester folder, add to executeTestsCommand - See issues/15
}

$executeTestsCommand += ";Invoke-Pester -ExcludeTag KnownIssue -OutputFormat NUnitXml -OutputFile ScenarioTestResults.xml -Verbose"

# Set up Pester params
$pesterParams = @{'ExcludeTag' = 'KnownIssue'; 'OutputFormat' = 'NUnitXml'; 'OutputFile' = 'TestResults.xml'}
if ($PSBoundParameters.ContainsKey('TestName')) {
    $executeTestsCommand += " -TestName $TestName"
}

if ($TestSuite.Contains("All")) {
    Write-Verbose "Invoking all tests."
} else {
    Write-Verbose "Running only tests with tag: $TestSuite"
    $executeTestsCommand += " -Tag $TestSuite"
}

# Set up the common generated modules location
$generatedModulesPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Generated"
if (-not (Test-Path $nodeExePath)) {
        Write-Verbose "Copying node.exe from NuGet package to $nodeExePath"
        Copy-Item -Path (Join-Path -Path $nodejsInstallPath -ChildPath "node.exe") -Destination $nodeExePath
    }

Write-Verbose "Executing: $executeTestsCommand"
$executeTestsCommand | Out-File pesterCommand.ps1

# TODO: Run PowerShell Core if testframework is core CLR - See issues/15
powershell -command .\pesterCommand.ps1

# Verify output
$x = [xml](Get-Content -raw "ScenarioTestResults.xml")
if ([int]$x.'test-results'.failures -gt 0)
{
    throw "$($x.'test-results'.failures) tests failed"
}