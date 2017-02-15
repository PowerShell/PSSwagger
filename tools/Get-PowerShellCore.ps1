param(
    [string]$RequiredPSVersion
)

Install-PackageProvider PSL -Force

if ([Environment]::OSVersion.Version.Major -eq 6) {
    Write-Verbose "Assuming OS is Win 8.1 (includes Win Server 2012 R2)"
    $pslLocation = Join-Path -Path $PSScriptRoot -ChildPath "PSL" | Join-Path -ChildPath "win81" | Join-Path -ChildPath "PSL.json"
} else {
    Write-Verbose "Assuming OS is Win 10"
    $pslLocation = Join-Path -Path $PSScriptRoot -ChildPath "PSL" | Join-Path -ChildPath "win10" | Join-Path -ChildPath "PSL.json"
}

if (-not $RequiredPSVersion) {
    $powershellCore = (Get-Package -provider PSL -name PowerShell -ErrorAction SilentlyContinue)
} else {
    $powershellCore = (Get-Package -provider PSL -name PowerShell -requiredversion $RequiredPSVersion -ErrorAction SilentlyContinue)
}

if (-not $powershellCore)
{
    $pslPackageSource = Get-PackageSource | Where-Object { $_.Location -eq $pslLocation } | Select-Object -first 1
    if ($pslPackageSource -eq $null) {
        $pslPackageSource = Register-PackageSource PSCorePSLSourcePSSwagger -ProviderName PSL -Location $pslLocation -Trusted
    }

    $powershellCore = Install-Package PowerShell -Provider PSL -Source $pslPackageSource.Name -Force -verbose
}