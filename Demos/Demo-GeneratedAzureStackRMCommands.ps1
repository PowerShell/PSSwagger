param(
    [string]
    $PSSwaggerClonePath = 'C:\Code\PSSwagger',

    [string]
    $TargetPath = 'C:\Temp\generatedmodule'
)
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

#region Handle Autorest installation

$autoRestVersion = "0.16.0"
$autoRestInstallation = get-package -Name AutoRest -RequiredVersion $autoRestVersion -ProviderName NuGet
if(-not $autoRestInstallation) {
    $autoRestInstallation = Install-Package -Name AutoRest -Source https://www.nuget.org/api/v2 -RequiredVersion 0.16.0 -ProviderName NuGet -Scope CurrentUser -Force
}

$autoRestInstallationLocation = ($autoRestInstallation).Source
$autoRestInstallPath = Join-Path -ChildPath "tools" -Path (Split-Path $autoRestInstallationLocation)

if(-not (($env:Path -split ';') -match [regex]::Escape($autoRestInstallPath))){$env:Path += ";$autoRestInstallPath"}

#endregion Handle Autorest installation


if(-not (Test-Path -Path $PSSwaggerClonePath -PathType Container))
{
    Throw "$PSSwaggerClonePath is not available."
}
Set-Location -Path $PSSwaggerClonePath
Import-Module .\PSSwagger\PSSwagger.psd1 -Force

# AzureStackRM.FabricResourceProvider
$ModuleName = 'Generated.AzureStackRM.FabricResourceProvider'
$param = @{
    SwaggerSpecUri  = 'C:\code\swaggerrelated\JsonFiles\SwaggerTransformed.json'
    Path            = $TargetPath
    ModuleName      = $ModuleName
    Authentication = 'AzureStack'
    UseAzureCsharpGenerator = $false
}
Export-CommandFromSwagger @param

Import-Module "$PSSwaggerClonePath\PSSwagger\Generated.Azure.Common.Helpers"
Import-Module $TargetPath\$ModuleName -WarningAction SilentlyContinue
Get-Command -Module $ModuleName
Get-Command -Module $ModuleName -Syntax


# Get AzureStack Fabric Location
$Subscription = 'f2f3698f-b9e7-48d3-8179-e67e9e92f0a7'
$ResourceGroup = 'system'    
$Apiversion = "2016-05-01"
$fabricLocation = 'local'
$azureStackDomain = 'azurestack.local'
# Supply values for the following parameters:
#  AzureStackDomain: azurestack.local

# Supply password for AzureStack account
# Example: serviceadmin@thoroet.onmicrosoft.com
Get-AzSRegion -Subscription $Subscription -ResourceGroup $ResourceGroup -Apiversion $Apiversion -FabricLocation $fabricLocation -Verbose
