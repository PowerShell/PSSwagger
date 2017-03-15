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
        [$paramType]
        $paramName,

'@

$RootModuleContents = @'
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename $ModuleName.Resources.psd1
. (Join-Path -Path "`$PSScriptRoot" -ChildPath "Utils.ps1")

if ('Core' -eq (Get-PSEdition)) {
    `$clr = 'coreclr'
} else {
    `$clr = 'fullclr'
}

`$dllFullName = Join-Path -Path `$PSScriptRoot -ChildPath 'ref' | Join-Path -ChildPath `$clr | Join-Path -ChildPath '$Namespace.dll'
`$isAzureCSharp = `$$UseAzureCSharpGenerator
if (-not (Test-Path -Path `$dllFullName)) {
    `$message = `$LocalizedData.CompilingBinaryComponent -f (`$dllFullName)
    Write-Verbose -Message `$message
    `$generatedCSharpFilePath = (Join-Path -Path "`$PSScriptRoot" -ChildPath "Generated.Csharp")
    if (-not (Test-Path -Path `$generatedCSharpFilePath)) {
        throw `$LocalizedData.CSharpFilesNotFound -f (`$generatedCSharpFilePath)
    }

    `$allCSharpFiles = Get-ChildItem -Path `$generatedCSharpFilePath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    `$fileHashFullPath = Join-Path -Path "`$PSScriptRoot" -ChildPath "$fileHashesFileName"
    if (-not (Test-Path -Path `$fileHashFullPath)) {
        `$message = `$LocalizedData.MissingFileHashesFile
        throw `$message
    }

    if ("$jsonFileHash" -ne (Get-CustomFileHash -Path `$fileHashFullPath -Algorithm $jsonFileHashAlgorithm).Hash) {
        `$message = `$LocalizedData.CatalogHashNotValid
        throw `$message
    }

    `$fileHashes = ConvertFrom-Json -InputObject (Get-Content -Path `$fileHashFullPath | Out-String)
    `$algorithm = `$fileHashes.Algorithm
    `$allCSharpFiles | ForEach-Object {
        `$fileName = "`$_".Replace("`$generatedCSharpFilePath","").Trim("\").Trim("/")
        `$hash = `$(`$fileHashes.`$fileName)
        if ((Get-CustomFileHash -Path `$_ -Algorithm `$algorithm).Hash -ne `$hash) {
            `$message = `$LocalizedData.HashValidationFailed
            throw `$message
        }
    }

    `$message = `$LocalizedData.HashValidationSuccessful
    Write-Verbose -Message `$message -Verbose

    Initialize-LocalTools -Precompiling
    `$success = Invoke-AssemblyCompilation -CSharpFiles `$allCSharpFiles -CodeCreatedByAzureGenerator:`$isAzureCSharp $requiredVersionParameter
    if (-not `$success) {
        `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
        throw `$message
    }

    `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
    Write-Verbose -Message `$message
}

# Load extra refs
Get-AzureRMDllReferences | ForEach-Object { Add-Type -Path `$_ -ErrorAction SilentlyContinue }
if ('Core' -ne (Get-PSEdition)) {
    Add-Type -Path (Get-MicrosoftRestAzureReference -Framework 'net45' -ClrPath (Join-Path -Path "`$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "`$clr"))
}

Get-ChildItem -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "`$clr" | Join-Path -ChildPath "*.dll") -File | ForEach-Object { Add-Type -Path `$_.FullName -ErrorAction SilentlyContinue }

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName\*.ps1" -Recurse -File | ForEach-Object { . `$_.FullName}
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
    param($paramblockWithAsJob
    )
    $body

    $PathFunctionCommonBody
}
'@

$helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@


$functionBodyStr = @'

    `$ErrorActionPreference = 'Stop'
    `$serviceCredentials = Get-AzServiceCredential
    `$subscriptionId = Get-AzSubscriptionId
    `$ResourceManagerUrl = Get-AzResourceManagerUrl
    `$delegatingHandler = Get-AzDelegatingHandler

    $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler$apiVersion

    if(Get-Member -InputObject $clientName -Name 'SubscriptionId' -MemberType Property)
    {
        $clientName.SubscriptionId = `$SubscriptionId
    }
    $clientName.BaseUri = `$ResourceManagerUrl

    $parameterSetBasedMethodStr else {
        Write-Verbose -Message 'Failed to map parameter set to operation method.'
        throw 'Module failed to find operation to execute.'
    }
'@

$parameterSetBasedMethodStrIfCase = @'
if ('$operationId' -eq `$PsCmdlet.ParameterSetName) {
        Write-Verbose -Message 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($requiredParamList)
    }
'@

$parameterSetBasedMethodStrElseIfCase = @'
 elseif ('$operationId' -eq `$PsCmdlet.ParameterSetName ) {
        Write-Verbose -Message 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($requiredParamList)
    }
'@

$PathFunctionCommonBody = @'
Write-Verbose -Message "Waiting for the operation to complete."

    $PSSwaggerJobScriptBlock = {
        [CmdletBinding()]
        param(    
            [Parameter(Mandatory = $true)]
            [System.Threading.Tasks.Task]
            $TaskResult
        )

        $ErrorActionPreference = 'Stop'
        
        $null = $TaskResult.AsyncWaitHandle.WaitOne()
        
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
    }

    $PSCommonParameters = Get-PSCommonParameters -CallerPSBoundParameters $PSBoundParameters

    if($AsJob)
    {
        $ScriptBlockParameters = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,object]'
        $ScriptBlockParameters['TaskResult'] = $TaskResult
        $ScriptBlockParameters['AsJob'] = $AsJob
        $PSCommonParameters.Keys | ForEach-Object { $ScriptBlockParameters[$_] = $PSCommonParameters[$_] }

        Invoke-SwaggerCommandUtility -ScriptBlock $PSSwaggerJobScriptBlock `
                                     -CallerPSBoundParameters $ScriptBlockParameters `
                                     -CallerPSCmdlet $PSCmdlet `
                                     @PSCommonParameters
    }
    else
    {
        Invoke-Command -ScriptBlock $PSSwaggerJobScriptBlock `
                       -ArgumentList $taskResult `
                       @PSCommonParameters
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

    `$PSBoundParameters.Keys | ForEach-Object { 
        `$Object.`$_ = `$PSBoundParameters[`$_]
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
