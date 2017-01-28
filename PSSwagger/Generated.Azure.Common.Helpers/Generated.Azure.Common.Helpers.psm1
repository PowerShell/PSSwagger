
$script:AzSCredential = $null
$script:AzSEnvironmentName = 'Azure Stack PS'

function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()
    $AzureContext = Get-AzRmContext
    $authenticationFactory = [Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory]::new() 
    if ('Desktop' -eq $PSEdition) {
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    } else {
        [Action[string]]$stringAction = {param($s) Write-Host "Prompt Message: $stringAction"}
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext, $stringAction)
    }

    $serviceCredentials
}

function Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    ,[System.Net.Http.DelegatingHandler[]]::new(0) 
}

function Get-AzSubscriptionId
{
    [CmdletBinding()]
    param()
    $AzureContext = Get-AzRmContext
    $AzureContext.Subscription.SubscriptionId
}

<#
.DESCRIPTION
    Gets the Azure Profile for the current process. 
    This command uses Login-AzureRMAccount
#>
function Get-AzSCredential
{
   [CmdletBinding()]
   param()

   if (-not $script:AzSCredential)
   {
       # Prompt for Azure Stack Credentials
       $script:AzSCredential = Get-Credential
   }
   
   if(-not $script:AzSCredential)
   {
       Throw "Invalid AzureStack Credential"
   }

   $script:AzSCredential
}

function New-AzSEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $AzureStackDomain
    )
    
    $Credential = Get-AzSCredential
    $AadTenantId = $Credential.UserName.split('@')[-1]

    # Add the Microsoft Azure Stack environment
    $null = Add-AzureRmEnvironment -Name $script:AzSEnvironmentName `
                                   -ActiveDirectoryEndpoint "https://login.windows.net/$AadTenantId/" `
                                   -ActiveDirectoryServiceEndpointResourceId "https://api.$azureStackDomain/3c76139d-1ec0-4ef2-a84d-1528675c6731"`
                                   -ResourceManagerEndpoint "https://api.$azureStackDomain/" `
                                   -GalleryEndpoint "https://gallery.$azureStackDomain/" `
                                   -GraphEndpoint "https://graph.windows.net/"
}

function Remove-AzSEnvironment
{
    [CmdletBinding()]
    param(
    )

    Remove-AzureRmEnvironment -Name $script:AzSEnvironmentName
}

function Get-AzSServiceCredential
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $AzureStackDomain
    )
    
    $Credential = Get-AzSCredential
    
    # Create new AzureStack environment
    New-AzSEnvironment -AzureStackDomain $AzureStackDomain

    # Create Service Credentials
    $AzureProfile = Login-AzureRmAccount -EnvironmentName $script:AzSEnvironmentName -Credential $Credential
    $authenticationFactory = [Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory]::new() 
    if ('Desktop' -eq $PSEdition) {
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    } else {
        [Action[string]]$stringAction = {param($s) Write-Host "Prompt Message: $stringAction"}
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext, $stringAction)
    }

    $serviceCredentials
}

function Get-AzRmContext {
    if ('Desktop' -eq $PSEdition) {
        AzureRM.Profile\Get-AzureRmContext -ErrorAction Stop
    } else {
        AzureRM.Profile.NetCore.Preview\Get-AzureRmContext -ErrorAction Stop
    }
}

$asm = @()
if ($PSEdition -eq 'Desktop') {
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "net45" | Join-Path -ChildPath "Newtonsoft.Json.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "net45" | Join-Path -ChildPath "Microsoft.Rest.ClientRuntime.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "net45" | Join-Path -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "net45" | Join-Path -ChildPath "Microsoft.Rest.ClientRuntime.Azure.dll"
} else {
    # TODO: Figure out the framework and runtime to load
    $framework = "netstandard1.7"
    $runtime = "win10-x64"
    # NOTE: This import order is very specific
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Newtonsoft.Json.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Microsoft.Rest.ClientRuntime.dll"
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Microsoft.Rest.ClientRuntime.Azure.dll" 
    $asm += Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "ref" | Join-Path -ChildPath "$framework" | Join-Path -ChildPath "$runtime" | Join-Path -ChildPath "Microsoft.Azure.Management.ResourceManager.dll" 
}

$asm | %{
    if (Test-Path $_) { 
        Add-Type -Path $_ -PassThru
    }
}