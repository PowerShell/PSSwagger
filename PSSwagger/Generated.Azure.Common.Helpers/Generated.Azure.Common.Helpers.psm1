
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

function Get-AzResourceManagerUrl
{
    [CmdletBinding()]
    param()

    if ('Desktop' -eq $PSEdition) {
        $AzureContext = AzureRM.Profile\Get-AzureRmContext -ErrorAction Stop
    } else {
        $AzureContext = AzureRM.Profile.NetCore.Preview\Get-AzureRmContext -ErrorAction Stop
    }

    $AzureContext.Environment.ResourceManagerUrl
}

function Add-AzSRmEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [string]
        $UserName,

        [Parameter(Mandatory = $true)]
        [string]
        $AzureStackDomain
    )
    
    $AadTenantId = $UserName.split('@')[-1]
    $Graphendpoint = "https://graph.$azureStackDomain"
    if ($AadTenantId -like '*.onmicrosoft.com')
    {
        $Graphendpoint = "https://graph.windows.net/"
    } 

    $Endpoints = Microsoft.PowerShell.Utility\Invoke-RestMethod -Method Get -Uri "https://api.$azureStackDomain/metadata/endpoints?api-version=1.0"
    $ActiveDirectoryServiceEndpointResourceId = $Endpoints.authentication.audiences[0]

    # Add the Microsoft Azure Stack environment
    if ('Desktop' -eq $PSEdition) {
        AzureRM.Profile\Add-AzureRmEnvironment -Name $Name `
                                            -ActiveDirectoryEndpoint "https://login.windows.net/$AadTenantId/" `
                                            -ActiveDirectoryServiceEndpointResourceId $ActiveDirectoryServiceEndpointResourceId `
                                            -ResourceManagerEndpoint "https://api.$azureStackDomain/" `
                                            -GalleryEndpoint "https://gallery.$azureStackDomain/" `
                                            -GraphEndpoint $Graphendpoint
    } else {
        AzureRM.Profile.NetCore.Preview\Add-AzureRmEnvironment -Name $Name `
                                           -ActiveDirectoryEndpoint "https://login.windows.net/$AadTenantId/" `
                                           -ActiveDirectoryServiceEndpointResourceId $ActiveDirectoryServiceEndpointResourceId `
                                           -ResourceManagerEndpoint "https://api.$azureStackDomain/" `
                                           -GalleryEndpoint "https://gallery.$azureStackDomain/" `
                                           -GraphEndpoint $Graphendpoint
    }
}

function Remove-AzSRmEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    if ('Desktop' -eq $PSEdition) {
        AzureRM.Profile\Remove-AzureRmEnvironment @PSBoundParameters
    } else {
        AzureRM.Profile.NetCore.Preview\Remove-AzureRmEnvironment @PSBoundParameters
    }
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