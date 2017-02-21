Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
    . (Join-Path -Path "$PSScriptRoot" -ChildPath "Test-CoreRequirements.ps1")
    $moduleName = 'AzureRM.Profile.NetCore.Preview'
} else {
    . (Join-Path -Path "$PSScriptRoot" -ChildPath "Test-FullRequirements.ps1")
    $moduleName = 'AzureRM.Profile'
}

function Get-AzServiceCredential
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop
    $authenticationFactory = New-Object -TypeName Microsoft.Azure.Commands.Common.Authentication.Factories.AuthenticationFactory
    if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
        [Action[string]]$stringAction = {param($s)}
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext, $stringAction)
    } else {
        $serviceCredentials = $authenticationFactory.GetServiceClientCredentials($AzureContext)
    }

    $serviceCredentials
}

function Get-AzDelegatingHandler
{
    [CmdletBinding()]
    param()

    New-Object -TypeName System.Net.Http.DelegatingHandler[] 0
}

function Get-AzSubscriptionId
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop    
    $AzureContext.Subscription.SubscriptionId
}

function Get-AzResourceManagerUrl
{
    [CmdletBinding()]
    param()

    $AzureContext = & "$moduleName\Get-AzureRmContext" -ErrorAction Stop    
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
    & "$moduleName\Add-AzureRmEnvironment" -Name $Name `
                                           -ActiveDirectoryEndpoint "https://login.windows.net/$AadTenantId/" `
                                           -ActiveDirectoryServiceEndpointResourceId $ActiveDirectoryServiceEndpointResourceId `
                                           -ResourceManagerEndpoint "https://api.$azureStackDomain/" `
                                           -GalleryEndpoint "https://gallery.$azureStackDomain/" `
                                           -GraphEndpoint $Graphendpoint
}

function Remove-AzSRmEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    & "$moduleName\Remove-AzureRmEnvironment" @PSBoundParameters
}

<#
.DESCRIPTION
  Gets the list of required modules to be imported for the scriptblock.

.PARAMETER  ModuleInfo
  PSModuleInfo object of the Swagger command.
#>
function Get-RequiredModulesPath
{
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSModuleInfo]
        $ModuleInfo
    )
    
    $ModulePaths = @()
    $ModulePaths += $ModuleInfo.RequiredModules | ForEach-Object { Get-RequiredModulesPath -ModuleInfo $_}

    $ManifestPath = Join-Path -Path (Split-Path -Path $ModuleInfo.Path -Parent) -ChildPath "$($ModuleInfo.Name).psd1"
    if(Test-Path -Path $ManifestPath)
    {
        $ModulePaths += $ManifestPath
    }
    else
    {
        $ModulePaths += $ModuleInfo.Path
    }

    return $ModulePaths | Select-Object -Unique
}

<#
.DESCRIPTION
  Invokes the specified script block as PSSwaggerJob.

.PARAMETER  ScriptBlock
  ScriptBlock to be executed in the PSSwaggerJob

.PARAMETER  CallerPSCmdlet
  Called $PSCmldet object to set the failure status.

.PARAMETER  CallerPSBoundParameters
  Parameters to be passed into the specified script block.

.PARAMETER  CallerModule
  PSModuleInfo object of the Swagger command.
#>
function Invoke-SwaggerCommandUtility
{
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [Parameter(Mandatory=$true)]
        $CallerPSBoundParameters,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSModuleInfo]
        $CallerModule
    )

    $AsJob = $false
    if($CallerPSBoundParameters.ContainsKey('AsJob'))
    {
        $AsJob = $true
    }
    
    $null = $CallerPSBoundParameters.Remove('WarningVariable')
    $null = $CallerPSBoundParameters.Remove('ErrorVariable')
    $null = $CallerPSBoundParameters.Remove('OutVariable')
    $null = $CallerPSBoundParameters.Remove('OutBuffer')
    $null = $CallerPSBoundParameters.Remove('PipelineVariable')
    $null = $CallerPSBoundParameters.Remove('InformationVariable')
    $null = $CallerPSBoundParameters.Remove('InformationAction')
    $null = $CallerPSBoundParameters.Remove('AsJob')

    $PSSwaggerJobParameters = @{}
    $PSSwaggerJobParameters['ScriptBlock'] = $ScriptBlock

    # Required modules list    
    if ($CallerModule)
    {        
        $PSSwaggerJobParameters['RequiredModules'] = Get-RequiredModulesPath -ModuleInfo $CallerModule
    }

    $VerbosePresent = $false
    if (-not $CallerPSBoundParameters.ContainsKey('Verbose'))
    {
        if($VerbosePreference -in 'Continue','Inquire')
        {
            $CallerPSBoundParameters['Verbose'] = [System.Management.Automation.SwitchParameter]::Present
            $VerbosePresent = $true
        }
    }
    else
    {
        $VerbosePresent = $true
    }

    $DebugPresent = $false
    if (-not $CallerPSBoundParameters.ContainsKey('Debug'))
    {
        if($debugPreference -in 'Continue','Inquire')
        {
            $CallerPSBoundParameters['Debug'] = [System.Management.Automation.SwitchParameter]::Present
            $DebugPresent = $true
        }
    }
    else
    {
        $DebugPresent = $true
    }

    if (-not $CallerPSBoundParameters.ContainsKey('ErrorAction'))
    {
        $CallerPSBoundParameters['ErrorAction'] = $errorActionPreference
    }

    if(Test-Path variable:\errorActionPreference)
    {
        $errorAction = $errorActionPreference
    }
    else
    {
        $errorAction = 'Continue'
    }

    if ($CallerPSBoundParameters['ErrorAction'] -eq 'SilentlyContinue')
    {
        $errorAction = 'SilentlyContinue'
    }

    if($CallerPSBoundParameters['ErrorAction'] -eq 'Ignore')
    {
        $CallerPSBoundParameters['ErrorAction'] = 'SilentlyContinue'
        $errorAction = 'SilentlyContinue'
    }

    if ($CallerPSBoundParameters['ErrorAction'] -eq 'Inquire')
    {
        $CallerPSBoundParameters['ErrorAction'] = 'Continue'
        $errorAction = 'Continue'
    }

    if (-not $CallerPSBoundParameters.ContainsKey('WarningAction'))
    {
        $CallerPSBoundParameters['WarningAction'] = $warningPreference
    }

    if(Test-Path variable:\warningPreference)
    {
        $warningAction = $warningPreference
    }
    else
    {
        $warningAction = 'Continue'
    }

    if ($CallerPSBoundParameters['WarningAction'] -in 'SilentlyContinue','Ignore')
    {
        $warningAction = 'SilentlyContinue'
    }

    if ($CallerPSBoundParameters['WarningAction'] -eq 'Inquire')
    {
        $CallerPSBoundParameters['WarningAction'] = 'Continue'
        $warningAction = 'Continue'
    }

    if($CallerPSBoundParameters)
    {
        $PSSwaggerJobParameters['Parameters'] = $CallerPSBoundParameters
    }

    $job = Start-PSSwaggerJob @PSSwaggerJobParameters

    if($job)
    {
        if($AsJob)
        {
            $job
        }
        else
        {
            try
            {
                Receive-Job -Job $job -Wait -Verbose:$VerbosePresent -Debug:$DebugPresent -ErrorAction $errorAction -WarningAction $warningAction

                if($CallerPSCmdlet)
                {
                    $CallerPSCmdlet.InvokeCommand.HasErrors = $job.State -eq 'Failed'
                }
            }
            finally
            {
                if($job.State -ne "Suspended" -and $job.State -ne "Stopped")
                {
                    Get-Job -Id $job.Id -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
                }
                else
                {
                    $job
                }
            }
        }
    }
}

$PSSwaggerJobAssemblyPath = $null

if(('Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerJob' -as [Type]) -and
   (Test-Path -Path [Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerJob].Assembly.Location -PathType Leaf))
{
    # This is for re-import scenario.
    $PSSwaggerJobAssemblyPath = [Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerJob].Assembly.Location
}
else
{
    $PSSwaggerJobFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'PSSwaggerJob.cs'
    if(Test-Path -Path $PSSwaggerJobFilePath -PathType Leaf)
    {
        $PSSwaggerJobSourceString = Get-Content -Path $PSSwaggerJobFilePath | Out-String

        $RequiredAssemblies = @(
            [System.Management.Automation.PSCmdlet].Assembly.FullName,
            [System.ComponentModel.AsyncCompletedEventArgs].Assembly.FullName,
            [System.Linq.Enumerable].Assembly.FullName,
            [System.Collections.StructuralComparisons].Assembly.FullName
        )

        $TempPath = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
        $null = New-Item -Path $TempPath -ItemType Directory -Force
        $PSSwaggerJobAssemblyPath = Join-Path -Path $TempPath -ChildPath 'PSSwaggerJob.dll'

        Add-Type -ReferencedAssemblies $RequiredAssemblies `
                 -TypeDefinition $PSSwaggerJobSourceString `
                 -OutputAssembly $PSSwaggerJobAssemblyPath `
                 -Language CSharp `
                 -WarningAction Ignore `
                 -IgnoreWarnings
    } 
}

if(Test-Path -LiteralPath $PSSwaggerJobAssemblyPath -PathType Leaf)
{
    # It is required to import the generated assembly into the module scope 
    # to register the PSSwaggerJobSourceAdapter with the PowerShell Job infrastructure.
    Import-Module -Name $PSSwaggerJobAssemblyPath
}

if(-not ('Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerJob' -as [Type]))
{
    Write-Error -Message "Unable to add PSSwaggerJob type."
}