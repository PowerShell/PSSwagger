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
    SpecificationUri  = 'C:\code\swaggerrelated\JsonFiles\SwaggerTransformed.json'
    Path            = $TargetPath
    Name            = $ModuleName
    UseAzureCsharpGenerator = $false
}
New-PSSwaggerModule @param

Import-Module "$PSSwaggerClonePath\PSSwagger\PSSwaggerUtility\PSSwaggerUtility.psd1" -verbose -force
Import-Module $TargetPath\$ModuleName -WarningAction SilentlyContinue
Get-Command -Module $ModuleName
Get-Command -Module $ModuleName -Syntax

$EnvironmentName = "Azure Stack PS"
$UserName = 'serviceadmin@thoroet.onmicrosoft.com'
$AzureStackDomain = 'azurestack.local'
$null = Add-AzSRmEnvironment -Name $EnvironmentName -UserName $UserName -AzureStackDomain $AzureStackDomain

$Credential = Get-Credential -UserName $UserName -Message "Enter credential to login to the AzureStack $EnvironmentName environment"
$null = Login-AzureRmAccount -EnvironmentName $EnvironmentName -Credential $Credential

# Get AzureStack Fabric Location
Get-AzSRegion -Subscription (Get-AzureRmContext).Subscription.SubscriptionId `
              -ResourceGroup 'system' `
              -Apiversion '2016-05-01' `
              -FabricLocation 'local'

$null = Remove-AzSRmEnvironment -Name $EnvironmentName
