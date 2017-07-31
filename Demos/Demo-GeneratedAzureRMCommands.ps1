param(
    [string]
    $PSSwaggerClonePath = 'D:\Work\PS\Swagger\PSSwagger',

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

#region Generate AzureRM commands
if(-not (Test-Path -Path $PSSwaggerClonePath -PathType Container))
{
    Throw "$PSSwaggerClonePath is not available."
}
Set-Location -Path $PSSwaggerClonePath
Import-Module .\PSSwagger\PSSwagger.psd1 -Force

Get-Command -Module PSSwagger
Get-Command New-PSSwaggerModule -Syntax

$param = @{
    Path = $TargetPath
    UseAzureCsharpGenerator = $true
}

# AzureRM.Resources
$param['SpecificationUri'] = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-resources/resources/2015-11-01/swagger/resources.json'
$param['Name']           = 'Generated.AzureRM.Resources'
New-PSSwaggerModule @param

# AzureRM.Storage
$param['SpecificationUri'] = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-storage/2015-06-15/swagger/storage.json'
$param['Name']           = 'Generated.AzureRM.Storage'
New-PSSwaggerModule @param

# AzureRM.Network
$param['SpecificationUri'] = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-network/2015-06-15/swagger/network.json'
$param['Name']           = 'Generated.AzureRM.Network'
New-PSSwaggerModule @param

# AzureRM.Compute
$param['SpecificationUri'] = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-compute/2015-06-15/swagger/compute.json'
$param['Name']           = 'Generated.AzureRM.Compute'
New-PSSwaggerModule @param

#endregion Generate AzureRM commands

#region initialization
Import-Module "$PSSwaggerClonePath\PSSwagger\PSSwaggerUtility\PSSwaggerUtility.psd1" -verbose -force
Import-Module $TargetPath\Generated.AzureRM.Resources -WarningAction SilentlyContinue
Import-Module $TargetPath\Generated.AzureRM.Storage -WarningAction SilentlyContinue
Import-Module $TargetPath\Generated.AzureRM.Network -WarningAction SilentlyContinue
Import-Module $TargetPath\Generated.AzureRM.Compute -WarningAction SilentlyContinue
#endregion initialization

# List Commands
Get-Command -Module Generated.AzureRM.Resources
Get-Command -Module Generated.AzureRM.Storage
Get-Command -Module Generated.AzureRM.Network
Get-Command -Module Generated.AzureRM.Compute


# Get syntax of the generated commands
Get-Command -Module Generated.AzureRM.Resources -Syntax
Get-Command -Module Generated.AzureRM.Storage -Syntax
Get-Command -Module Generated.AzureRM.Network -Syntax
Get-Command -Module Generated.AzureRM.Compute -Syntax

## Global
$USERNAME = $env:USERNAME.ToLower()
$ResourceGroupName = "ContosoResourceGroup$USERNAME"
$Location = 'WestEurope'

## Storage
$StorageName = "contosostorage$USERNAME"
$StorageType = 'StandardGRS'

## Network
$InterfaceName = "ContosoServerInterface07$USERNAME"
$SubnetName = "ContosoSubnet07$USERNAME"
$VNetName = "ContosoVNet07$USERNAME"
$VNetAddressPrefix = '10.0.0.0/16'
$VNetSubnetAddressPrefix = '10.0.0.0/24'

$IPConfigurationName = "ContosoIpConfig$USERNAME"

## Compute
$VMName = "ContosoVirtualMachine07$USERNAME"
$ComputerName = "$($USERNAME)VM"
$VMSize = 'Standard_A2'
$OSDiskName = $VMName + 'OSDisk'

$ImagePublisher = 'MicrosoftWindowsServer'
$ImageOffer = 'WindowsServer'
$ImageSKU = '2012-R2-Datacenter'
$ImageVersion = 'latest'

$AdminUsername = 'ContosoUser'
$AdminPassword = 'ContosoUserPassword~1'

$VMExtensionName = 'BGInfo'

$Tags = new-object 'System.Collections.Generic.Dictionary[[string],[string]]'
$Tags.Add('CreatedUsingGeneratedCommands','CreatedUsingGeneratedCommands')
$Tags.Add('ContosTag1','ContosoTag1')
$Tags.Add('ContosTag2','ContosoTag2')
$Tags.Add('ContosTag3','ContosoTag3')


#region Resource Group

Login-AzureRmAccount -SubscriptionName PSSwagger

# ResourceGroup Cleanup
if(Get-ResourceGroups -ResourceGroupName $ResourceGroupName -ErrorAction silentlycontinue) {
    Remove-ResourceGroups -ResourceGroupName $ResourceGroupName
}

Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the resource group '$ResourceGroupName'"
$RGParameters = New-ResourceGroupObject -Location $Location -Tags $Tags
New-ResourceGroupsOrUpdate -ResourceGroupName $ResourceGroupName -Parameters $RGParameters
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the resource group '$ResourceGroupName'"
#endregion Resource Group

#region Storage

Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the storage account '$StorageName'"
$StorageAccountCreateParameters = New-StorageAccountCreateParametersObject -Location $Location -AccountType $StorageType
$StorageAccount = New-StorageAccounts -ResourceGroupName $ResourceGroupName -AccountName $StorageName -Parameters $StorageAccountCreateParameters
$StorageAccount

$StorageAccount = Get-StorageAccountsProperties -ResourceGroupName $ResourceGroupName -AccountName $StorageName
$StorageAccount

Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the storage account '$StorageName'"

#endregion Storage

#region Network

## PublicIPAddresses
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Public IP address for '$InterfaceName'"
$PublicIPAddressParameters = New-PublicIPAddressObject -Location $Location -PublicIPAllocationMethod Dynamic
$PIp = New-PublicIPAddressesOrUpdate -ResourceGroupName $ResourceGroupName -PublicIpAddressName $InterfaceName -Parameters $PublicIPAddressParameters
$PIp
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Public IP address for '$InterfaceName'"

## VNet
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Virtual Network '$VNetName'"
$AddressSpace = New-AddressSpaceObject -AddressPrefixes $VNetAddressPrefix
$VirtualNetworkParameters = New-VirtualNetworkObject -Location $Location -AddressSpace $AddressSpace

$VNet = New-VirtualNetworksOrUpdate -ResourceGroupName $ResourceGroupName -VirtualNetworkName $VNetName -Parameters $VirtualNetworkParameters
$VNet
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Virtual Network '$VNetName'"

## Subnet 
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Subnet '$SubnetName'"
$SubnetParameters = New-SubnetObject -AddressPrefix $VNetSubnetAddressPrefix
$SubnetConfig = New-SubnetsOrUpdate -ResourceGroupName $ResourceGroupName -VirtualNetworkName $VNetName -SubnetName $SubnetName -SubnetParameters $SubnetParameters
$SubnetConfig
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Subnet '$SubnetName'"


## NetworkInterface
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Network Interface '$InterfaceName'"

$IPConfigurationPublicIPAddress = New-PublicIPAddressObject -Id $PIp.Id
$IPConfigurationSubnet = New-SubnetObject -Id $SubnetConfig.Id
$IPConfiguration = New-NetworkInterfaceIPConfigurationObject -PublicIPAddress $IPConfigurationPublicIPAddress `
                                                             -Subnet $IPConfigurationSubnet `
                                                             -Name $IPConfigurationName `
                                                             -PrivateIPAllocationMethod Dynamic

$NetworkInterfaceParameters = New-NetworkInterfaceObject -Location $Location -IpConfigurations $IPConfiguration
$Interface = New-NetworkInterfacesOrUpdate -ResourceGroupName $resourceGroupName -NetworkInterfaceName $InterfaceName -Parameters $NetworkInterfaceParameters
$Interface
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Network Interface '$InterfaceName'"

#endregion Network



#region Compute
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Virtual Machine '$VMName'"

# HardwareProfile
$HardwareProfile = New-HardwareProfileObject -VMSize $VMSize

#region storageProfile

## ImageReference
$ImageReference = New-ImageReferenceObject -Publisher $ImagePublisher -Offer $ImageOffer -SKU $ImageSKU -Version $ImageVersion

## OSDisk

### VirtualHardDisk vhd
$Vhd = New-VirtualHardDiskObject -Uri "$($StorageAccount.PrimaryEndpoints.Blob)vhds/$($OSDiskName).vhd"
$OSDisk = New-OSDiskObject -Name $OSDiskName -VHD $Vhd -CreateOption FromImage

### StorageProfile
$StorageProfile = New-StorageProfileObject -ImageReference $ImageReference -OSDisk $OSDisk

#endregion storageProfile

#region OSProfile

# WindowsConfiguration
$WindowsConfiguration = New-WindowsConfigurationObject -ProvisionVMAgent -EnableAutomaticUpdates
$OSProfile = New-OSProfileObject -ComputerName $ComputerName `
                                 -AdminUsername $AdminUsername `
                                 -AdminPassword $AdminPassword `
                                 -WindowsConfiguration $WindowsConfiguration
#endregion  OSProfile

# $NetworkProfile
$NetworkInterfaceReference = New-NetworkInterfaceReferenceObject -Id $Interface.Id
$NetworkProfile = New-NetworkProfileObject -NetworkInterfaces $NetworkInterfaceReference
   
# DiagnosticsProfile
$BootDiagnostics = New-BootDiagnosticsObject -Enabled -StorageUri $StorageAccount.PrimaryEndpoints.Blob
$DiagnosticsProfile = New-DiagnosticsProfileObject -BootDiagnostics $BootDiagnostics

$VirtualMachineParameters = New-VirtualMachineObject -Location $Location `
                                                     -HardwareProfile $HardwareProfile `
                                                     -StorageProfile $StorageProfile `
                                                     -OSProfile $OSProfile `
                                                     -NetworkProfile $NetworkProfile `
                                                     -DiagnosticsProfile $DiagnosticsProfile `
                                                     -Tags $Tags

# VM Creation
$VM = New-VirtualMachinesOrUpdate -ResourceGroupName $ResourceGroupName -VMName $VMName -Parameters $VirtualMachineParameters
$VM
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Virtual Machine '$VMName'"


# VirtualMachine Extension
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Creating the Virtual Machine Extension '$VMExtensionName'"
$ExtensionParameters = New-VirtualMachineExtensionObject -Location $Location `
                                                         -Publisher 'Microsoft.Compute' `
                                                         -VirtualMachineExtensionType 'BGInfo' `
                                                         -TypeHandlerVersion '2.1' `
                                                         -AutoUpgradeMinorVersion

$VMExtension = New-VirtualMachineExtensionsOrUpdate -ResourceGroupName $ResourceGroupName -VMName $VMName -VMExtensionName $VMExtensionName -ExtensionParameters $ExtensionParameters
$VMExtension
Write-Host -BackgroundColor DarkGreen -ForegroundColor Green "Successfully created the Virtual Machine Extension '$VMExtensionName'"

#endregion Compute

# ResourceGroup Cleanup
if(Get-ResourceGroups -ResourceGroupName $ResourceGroupName -ErrorAction silentlycontinue) {
    Remove-ResourceGroups -ResourceGroupName $ResourceGroupName
}
