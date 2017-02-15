# Ensures a package source exists for the location "http://nuget.org/api/v2/"
function Test-NugetPackageSource {
    $bestNugetLocation = "http://nuget.org/api/v2/"
    $nugetPackageSource = Get-PackageSource | Where-Object {($_.ProviderName -eq "NuGet") -and ($_.Location -eq $bestNugetLocation) } | Select-Object -First 1
    Write-Verbose "Attempted to find NuGet package source. Got: $nugetPackageSource"
    if ($nugetPackageSource -eq $null) {
        Write-Verbose "No NuGet package source found for location $bestNugetLocation. Registering source PSSwaggerNuget."
        $nugetPackageSource = Register-PackageSource "PSSwaggerNuget" -Location $bestNugetLocation -ProviderName "NuGet" -Trusted -Force
    }

    return $nugetPackageSource
}

# Ensures a given package exists. Caller should validate if returned module is null or not (null indicates the package failed to install)
function Test-Package {
    param(
        [string]$packageName,
        [string]$packageSourceName,
        [string]$providerName = "NuGet"
    )

    $module = Get-Package $packageName -ErrorAction SilentlyContinue
    if ($module -eq $null) {
        Write-Verbose "Trying to install missing package $packageName from source $packageSourceName"
        $null = Install-Package $packageName -ProviderName $providerName -Source $packageSourceName -Force
        $module = Get-Package $packageName -ErrorAction SilentlyContinue
    }

    $module
}

function Compile-TestAssembly {
    param(
        [string]$TestAssemblyFullPath,
        [string]$TestCSharpFilePath,
        [string]$CompilationUtilsPath,
        [bool]$UseAzureCSharpGenerator
    )

    Write-Host "Checking for test assembly '$TestAssemblyFullPath'"
    if (-not (Test-Path $TestAssemblyFullPath)) {
        Write-Host "Generating test assembly from file '$TestCSharpFilePath' using script '$CompilationUtilsPath'"
        . "$CompilationUtilsPath"
        Invoke-AssemblyCompilation -CSharpFiles @($TestCSharpFilePath) -OutputAssembly $TestAssemblyFullPath -CodeCreatedByAzureGenerator:$UseAzureCSharpGenerator -Verbose
    }
}