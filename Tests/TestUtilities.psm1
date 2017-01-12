# Ensures a package source exists for the location "http://nuget.org/api/v2/"
function Ensure-NugetPackageSource {
    $bestNugetLocation = "http://nuget.org/api/v2/"
    $nugetPackageSource = Get-PackageSource | Where-Object {($_.ProviderName -eq "NuGet") -and ($_.Location -eq $bestNugetLocation) }
    Write-Verbose "Attempted to find NuGet package source. Got: $nugetPackageSource"
    if ($nugetPackageSource -eq $null) {
        Write-Verbose "No NuGet package source found for location $bestNugetLocation. Registering source PSSwaggerNuget."
        Register-PackageSource "PSSwaggerNuget" -Location $bestNugetLocation -ProviderName "NuGet" -Trusted -Force
    }
}

# Ensures a given package exists. Caller should validate if returned module is null or not (null indicates the package failed to install)
function Ensure-Package {
    param(
        [string]$packageName
    )

    $module = Get-Package $packageName -ErrorAction SilentlyContinue
    if ($module -eq $null) {
        Write-Verbose "Trying to install missing package $packageName"
        $null = Install-Package $packageName -Force
        $module = Get-Package $packageName -ErrorAction SilentlyContinue
    }

    $module
}