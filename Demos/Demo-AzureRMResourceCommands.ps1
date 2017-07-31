$PSSwaggerClonePath = 'C:\Code\PSSwagger'
$TargetPath = 'C:\Temp\generatedmodule'
Set-Location -Path $PSSwaggerClonePath

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

#region Generate AzureRM commands
Import-Module .\PSSwagger\PSSwagger.psd1 -Force

$param = @{
    Path = $TargetPath
    UseAzureCsharpGenerator = $true
    IncludeCoreFxAssembly = $false
}

# AzureRM.Resources
$param['SpecificationUri'] = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-resources/resources/2015-11-01/swagger/resources.json'
$param['Name']           = 'Generated.AzureRM.Resources'
New-PSSwaggerModule @param
#endregion Generate AzureRM commands


Import-Module "$PSSwaggerClonePath\PSSwagger\PSSwaggerUtility\PSSwaggerUtility.psd1" -verbose -force

Import-Module $TargetPath\Generated.AzureRM.Resources -WarningAction SilentlyContinue

Get-Command -Module Generated.AzureRM.Resources

Login-AzureRmAccount -SubscriptionName PSSwagger

# ResourceGroup Cleanup
if(Get-ResourceGroups -ResourceGroupName $ResourceGroupName -ErrorAction silentlycontinue) {
    Remove-ResourceGroups -ResourceGroupName $ResourceGroupName
}

$USERNAME = $env:USERNAME.ToLower()
$ResourceGroupName = "ContosoResourceGroup$USERNAME"
$Location = 'WestEurope'
$RGParameters = New-ResourceGroupObject -Location $Location

New-ResourceGroupsOrUpdate -ResourceGroupName $ResourceGroupName -Parameters $RGParameters
Get-ResourceGroups -ResourceGroupName $ResourceGroupName

# With AsJob parameter
GetAll-ResourceGroups -AsJob | Wait-Job
Get-Job | Receive-Job

Get-ResourceGroups -ResourceGroupName $ResourceGroupName -AsJob | Wait-Job
Get-Job | Receive-Job

# Remove jobs
Get-Job | Remove-Job

# ResourceGroup Cleanup
if(Get-ResourceGroups -ResourceGroupName $ResourceGroupName -ErrorAction silentlycontinue) {
    Remove-ResourceGroups -ResourceGroupName $ResourceGroupName
}
