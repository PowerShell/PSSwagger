#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Localized PSSwagger.Constants.ps1
#
#########################################################################################

$helpDescStr = @'
.DESCRIPTION
    $description
'@

$parameterAttributeString = '[Parameter(Mandatory = $isParamMandatory$ParameterSetPropertyString)]'

$parameterDefString = @'
    
        $AllParameterSetsString$ValidateSetDefinition
        $paramType$paramName$parameterDefaultValueOption,

'@

$parameterDefaultValueString = ' = $parameterDefaultValue'

$RootModuleContents = @'
param(
	[switch]
	`$AcceptBootstrap
)

`$script:ServiceClientTracer = `$null
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename $Name.Resources.psd1

if ((Get-OperatingSystemInfo).IsCore) {
    `$clr = 'coreclr'
    `$framework = 'netstandard1'
} else {
    `$clr = 'fullclr'
    `$framework = 'net4'
}

`$clrPath = Join-Path -Path `$PSScriptRoot -ChildPath 'ref' | Join-Path -ChildPath `$clr
`$dllFullName = Join-Path -Path `$clrPath -ChildPath '$Namespace.dll'
`$isAzureCSharp = `$$UseAzureCSharpGenerator
`$consent = `$false
if (-not (Test-Path -Path `$dllFullName)) {
    `$message = `$LocalizedData.CompilingBinaryComponent -f (`$dllFullName)
    Write-Verbose -Message `$message
    `$generatedCSharpFilePath = (Join-Path -Path "`$PSScriptRoot" -ChildPath "Generated.Csharp")
    if (-not (Test-Path -Path `$generatedCSharpFilePath)) {
        throw `$LocalizedData.CSharpFilesNotFound -f (`$generatedCSharpFilePath)
    }

    `$allCSharpFiles = Get-ChildItem -Path (Join-Path -Path `$generatedCSharpFilePath -ChildPath "*.Code.ps1") -Recurse -Exclude Program.cs,TemporaryGeneratedFile* -File | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    if ((Get-OperatingSystemInfo).IsWindows) {
        `$allCSharpFiles | ForEach-Object {
            `$sig = Get-AuthenticodeSignature -FilePath `$_.FullName 
            if (('NotSigned' -ne `$sig.Status) -and ('Valid' -ne `$sig.Status)) {
                throw `$LocalizedData.HashValidationFailed
            }
        }

        `$message = `$LocalizedData.HashValidationSuccessful
        Write-Verbose -Message `$message -Verbose
    }

    `$dependencies = Get-PSSwaggerExternalDependencies -Azure:`$isAzureCSharp -Framework `$framework
    `$consent = Initialize-PSSwaggerLocalTools -Azure:`$isAzureCSharp -Framework `$framework -AcceptBootstrap:`$AcceptBootstrap
    `$microsoftRestClientRuntimeAzureRequiredVersion = ''
    if (`$dependencies.ContainsKey('Microsoft.Rest.ClientRuntime.Azure')) {
        `$microsoftRestClientRuntimeAzureRequiredVersion = `$dependencies['Microsoft.Rest.ClientRuntime.Azure'].RequiredVersion
    }
    
    `$microsoftRestClientRuntimeRequiredVersion = `$dependencies['Microsoft.Rest.ClientRuntime'].RequiredVersion
    `$newtonsoftJsonRequiredVersion = `$dependencies['Newtonsoft.Json'].RequiredVersion

    `$success = Invoke-PSSwaggerAssemblyCompilation -CSharpFiles `$allCSharpFiles -NewtonsoftJsonRequiredVersion `$newtonsoftJsonRequiredVersion -MicrosoftRestClientRuntimeRequiredVersion `$microsoftRestClientRuntimeRequiredVersion -MicrosoftRestClientRuntimeAzureRequiredVersion "`$microsoftRestClientRuntimeAzureRequiredVersion" -ClrPath `$clrPath -BootstrapConsent:`$consent -CodeCreatedByAzureGenerator:`$isAzureCSharp
    if (-not `$success) {
        `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
        throw `$message
    }

    `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
    Write-Verbose -Message `$message
}



Get-ChildItem -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "`$clr" | Join-Path -ChildPath "*.dll") -File | ForEach-Object { Add-Type -Path `$_.FullName -ErrorAction SilentlyContinue }

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName\*.ps1" -Recurse -File | ForEach-Object { . `$_.FullName}

if(`$PSVersionTable.PSVersion -ge '5.0.0' -and (-not `$script:ServiceClientTracer)) {
    # Load and enable service client tracer
    `$script:ServiceClientTracer = New-PSSwaggerClientTracing
    Register-PSSwaggerClientTracing -TracerObject `$script:ServiceClientTracer
    `$PSModule = `$ExecutionContext.SessionState.Module
    `$PSModule.OnRemove = { 
        Unregister-PSSwaggerClientTracing -TracerObject `$script:ServiceClientTracer
        `$script:ServiceClientTracer = `$null
    }
}
'@

$advFnSignatureForDefintion = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
    param($paramblock
    )
    $body
}
'@

$AsJobParameterString = @'

        [Parameter(Mandatory = $false)]
        [switch]
        $AsJob
'@


$advFnSignatureForPath = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
    $outputTypeBlock[CmdletBinding(DefaultParameterSetName='$DefaultParameterSetName')]
    param($ParamBlockReplaceStr
    )
    $body

    $PathFunctionBody
}
'@

$helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

$oDataExpressionBlockStr = @'


    `$oDataQuery = ""
    $oDataExpression
    `$oDataQuery = `$oDataQuery.Trim("&")
'@

$parameterGroupCreateExpression = @'
`$$groupName = New-Object -TypeName $fullGroupName
'@

$parameterGroupPropertyExpression = @'
    if (`$PSBoundParameters.ContainsKey('$parameterGroupPropertyName')) { `$$groupName.$parameterGroupPropertyName = `$$parameterGroupPropertyName }
'@

$functionBodyStr = @'

    `$ErrorActionPreference = 'Stop'
    `$serviceCredentials = Get-AzServiceCredential
    `$subscriptionId = Get-AzSubscriptionId
    `$ResourceManagerUrl = Get-AzResourceManagerUrl
    `$delegatingHandler = Get-AzDelegatingHandler

    $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler$apiVersion

    $GlobalParameterBlock
    $clientName.BaseUri = `$ResourceManagerUrl$oDataExpressionBlock
    $parameterGroupsExpressionBlock

    $parameterSetBasedMethodStr else {
        Write-Verbose -Message 'Failed to map parameter set to operation method.'
        throw 'Module failed to find operation to execute.'
    }
'@

$parameterSetBasedMethodStrIfCase = @'
if ('$operationId' -eq `$PsCmdlet.ParameterSetName) {
$additionalConditionStart$methodBlock$additionalConditionEnd
    }
'@

$parameterSetBasedMethodStrElseIfCase = @'
 elseif ('$operationId' -eq `$PsCmdlet.ParameterSetName ) {
$additionalConditionStart$methodBlock$additionalConditionEnd
    }
'@

$methodBlockFunctionCall = @'
        Write-Verbose -Message 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($ParamList)
'@

$methodBlockCmdletCall = @'
        Write-Verbose -Message 'Calling cmdlet $Cmdlet.'
        $Cmdlet $CmdletArgs
        `$taskResult = `$null
'@

$getTaskResultBlockWithPaging = @'
$result = $null
        $ErrorActionPreference = 'Stop'
                    
        $null = $taskResult.AsyncWaitHandle.WaitOne()
                    
        Write-Debug -Message "$($taskResult | Out-String)"

        if($taskResult.IsFaulted)
        {
            Write-Verbose -Message 'Operation failed.'
            Throw "$($taskResult.Exception.InnerExceptions | Out-String)"
        } 
        elseif ($taskResult.IsCanceled)
        {
            Write-Verbose -Message 'Operation got cancelled.'
            Throw 'Operation got cancelled.'
        }
        else
        {
            Write-Verbose -Message 'Operation completed successfully.'

            if($taskResult.Result -and
                (Get-Member -InputObject $taskResult.Result -Name 'Body') -and
                $taskResult.Result.Body)
            {
                $result = $taskResult.Result.Body
                Write-Verbose -Message "$($result | Out-String)"
                if ($Paging) { @{ Page = $result } } else { $result }
            }
        }
'@

$getTaskResultBlockNoPaging = @'
$result = $null
        $ErrorActionPreference = 'Stop'
                    
        $null = $taskResult.AsyncWaitHandle.WaitOne()
                    
        Write-Debug -Message "$($taskResult | Out-String)"

        if($taskResult.IsFaulted)
        {
            Write-Verbose -Message 'Operation failed.'
            Throw "$($taskResult.Exception.InnerExceptions | Out-String)"
        } 
        elseif ($taskResult.IsCanceled)
        {
            Write-Verbose -Message 'Operation got cancelled.'
            Throw 'Operation got cancelled.'
        }
        else
        {
            Write-Verbose -Message 'Operation completed successfully.'

            if($taskResult.Result -and
                (Get-Member -InputObject $taskResult.Result -Name 'Body') -and
                $taskResult.Result.Body)
            {
                $result = $taskResult.Result.Body
                Write-Verbose -Message "$($result | Out-String)"
                $result
            }
        }
'@

$PathFunctionBodyAsJob = @'
Write-Verbose -Message "Waiting for the operation to complete."

    `$PSSwaggerJobScriptBlock = {
        [CmdletBinding()]
        param(    
            [Parameter(Mandatory = `$true)]
            [System.Threading.Tasks.Task]
            `$TaskResult
        )
        if (`$TaskResult) {
            $getTaskResult
            $pagingBlock
        }
    }

    `$PSCommonParameters = Get-PSCommonParameters -CallerPSBoundParameters `$PSBoundParameters

    if(`$AsJob)
    {
        `$ScriptBlockParameters = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,object]'
        `$ScriptBlockParameters['TaskResult'] = `$TaskResult
        `$ScriptBlockParameters['AsJob'] = `$AsJob
        `$PSCommonParameters.GetEnumerator() | ForEach-Object { `$ScriptBlockParameters[`$_.Name] = `$_.Value }

        Invoke-SwaggerCommandUtility -ScriptBlock `$PSSwaggerJobScriptBlock ``
                                     -CallerPSBoundParameters `$ScriptBlockParameters ``
                                     -CallerPSCmdlet `$PSCmdlet ``
                                     @PSCommonParameters
    }
    else
    {
        Invoke-Command -ScriptBlock `$PSSwaggerJobScriptBlock ``
                       -ArgumentList `$taskResult ``
                       @PSCommonParameters
    }
'@

$PathFunctionBodySynch = @'
if (`$TaskResult) {
        $getTaskResult
        $pagingBlock
    }
'@

$PagingBlockStrFunctionCall = @'
    
        if (-not `$Paging) {
            Write-Verbose -Message 'Flattening paged results.'
            while (`$result -and `$result.NextPageLink) {
                Write-Debug -Message "Retrieving next page: `$(`$result.NextPageLink)"
                `$taskResult = $clientName$pagingOperations.$pagingOperationName(`$result.NextPageLink)
                $getTaskResult
            }
        }
'@

$PagingBlockStrCmdletCall = @'
    
        if (-not `$Paging) {
            Write-Verbose -Message 'Flattening paged results.'
            while (`$result -and `$result.NextPageLink) {
                Write-Debug -Message "Retrieving next page: `$(`$result.NextPageLink)"
                $Cmdlet $CmdletArgs
            }
        }
'@

$ValidateSetDefinitionString = @'

        [ValidateSet($ValidateSetString)]
'@

$successReturn = @'
Write-Verbose "Operation completed with return code: `$responseStatusCode."
                        $result = $taskResult.Result.Body
                        Write-Verbose -Message "$($result | Out-String)"
                        $result
'@

$responseBodySwitchCase = @'
switch (`$responseStatusCode)
                {
                    {200..299 -contains `$responseStatusCode} {
                        $successReturn
                    }$failWithDesc
                    
                    Default {Write-Error -Message "Status: `$responseStatusCode received."}
                }
'@

$failCase = @'

                    {`$responseStatusCode} {
                        $responseStatusValue {$failureDescription}
                    }
'@

$outputTypeStr = @'
[OutputType([$fullPathDataType])]
    
'@

$createObjectStr = @'

    `$Object = New-Object -TypeName $DefinitionTypeName

    `$PSBoundParameters.GetEnumerator() | ForEach-Object { 
        `$Object.`$(`$_.Key) = `$_.Value
    }

    if(Get-Member -InputObject `$Object -Name Validate -MemberType Method)
    {
        `$Object.Validate()
    }

    return `$Object
'@

$ApiVersionStr = @'

    if(Get-Member -InputObject $clientName -Name 'ApiVersion' -MemberType Property)
    {
        $clientName.ApiVersion = "$infoVersion"
    }
'@

$GlobalParameterBlockStr = @'
    if(Get-Member -InputObject `$clientName -Name '$globalParameterName' -MemberType Property)
    {
        `$clientName.$globalParameterName = $globalParameterValue
    }
'@

$GeneratedCommandsName = 'Generated.PowerShell.Commands'

$FormatViewDefinitionStr = @'
<?xml version="1.0" encoding="utf-8" ?>
<Configuration>
    <ViewDefinitions>
        <View>
            <Name>{0}</Name>
            <ViewSelectedBy>
                <TypeName>{1}</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>{2}
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
{3}
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

$TableColumnItemStr = @'
                            <TableColumnItem>
                                <PropertyName>{0}</PropertyName>
                            </TableColumnItem>
'@

$TableColumnHeaderStr = @'
                    <TableColumnHeader>
                        <Width>{0}</Width>
                    </TableColumnHeader>
'@
