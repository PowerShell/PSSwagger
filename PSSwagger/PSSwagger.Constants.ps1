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

    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)]$ValidateSetDefinition
    [$paramType]
    $paramName,

'@

    $RootModuleContents = @'
Microsoft.PowerShell.Core\Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename $ModuleName.Resources.psd1

if ('Core' -eq `$PSEdition) {
    `$clr = 'coreclr'
} else {
    `$clr = 'fullclr'
}

`$dllFullName = Join-Path -Path `$PSScriptRoot -ChildPath 'ref' | Join-Path -ChildPath `$clr | Join-Path -ChildPath '$Namespace.dll'
`$isAzureCSharp = `$$UseAzureCSharpGenerator
if (-not (Test-Path -Path `$dllFullName)) {
    `$message = `$LocalizedData.CompilingBinaryComponent -f (`$dllFullName)
    Write-Verbose -Message `$message -Verbose
    . (Join-Path -Path "`$PSScriptRoot" -ChildPath "Utils.ps1")
    `$generatedCSharpFilePath = (Join-Path -Path "`$PSScriptRoot" -ChildPath "Generated.Csharp")
    `$allCSharpFiles = Get-ChildItem -Path `$generatedCSharpFilePath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    if (-not (Test-Path -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "$fileHashesFileName"))) {
        `$message = `$LocalizedData.MissingFileHashesFile
        throw `$message
    }

    if ("$jsonFileHash" -ne (Get-FileHash -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "$fileHashesFileName") -Algorithm $jsonFileHashAlgorithm).Hash) {
        `$message = `$LocalizedData.CatalogHashNotValid
        throw `$message
    }

    `$fileHashes = ConvertFrom-Json -InputObject (Get-Content -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "$fileHashesFileName") | Out-String)
    `$algorithm = `$fileHashes.Algorithm
    `$allCSharpFiles | ForEach-Object {
        `$fileName = "`$_".Replace("`$generatedCSharpFilePath","").Trim("\").Trim("/")
        `$hash = `$(`$fileHashes.`$fileName)
        if ((Get-FileHash -Path `$_ -Algorithm `$algorithm).Hash -ne `$hash) {
            `$message = `$LocalizedData.HashValidationFailed
            throw `$message
        }
    }

    `$allCSharpFiles = Get-ChildItem -Path `$generatedCSharpFilePath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object -Property DirectoryName -notlike '*Azure.Csharp.Generated*'
    `$success = Invoke-AssemblyCompilation -CSharpFiles `$allCSharpFiles -CodeCreatedByAzureGenerator:`$isAzureCSharp -CopyExtraReferences
    if (-not `$success) {
        `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
        throw `$message
    }
}

# Load extra refs
Get-ChildItem -Path (Join-Path -Path "`$PSScriptRoot" -ChildPath "ref" | Join-Path -ChildPath "`$clr" | Join-Path -ChildPath "*.dll") -File | ForEach-Object { Add-Type -Path `$_.FullName -ErrorAction SilentlyContinue }

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName" -Recurse -Filter *.ps1 -File | ForEach-Object { . `$_.FullName}
'@

    $advFnSignature = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
   $outputTypeBlock[CmdletBinding()]
   param($paramblock
   )

   $body
}
'@

    $helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

    $functionBodyStr = @'
 `Begin
    {
        `$serviceCredentials = Get-AzServiceCredential
        `$subscriptionId = Get-AzSubscriptionId
        `$ResourceManagerUrl = Get-AzResourceManagerUrl
    }

    Process
    {
        `$delegatingHandler = Get-AzDelegatingHandler

        $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler$apiVersion

        if(Get-Member -InputObject $clientName -Name 'SubscriptionId' -MemberType Property)
        {
            $clientName.SubscriptionId = `$SubscriptionId
        }
        $clientName.BaseUri = `$ResourceManagerUrl

        Write-Verbose -Message 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($requiredParamList)
        Write-Verbose -Message "Waiting for the operation to complete."
        `$null = `$taskResult.AsyncWaitHandle.WaitOne()
        Write-Debug -Message "`$(`$taskResult | Out-String)"

        if(`$taskResult.IsFaulted)
        {
            Write-Verbose -Message 'Operation failed.'
            Throw "`$(`$taskResult.Exception.InnerExceptions | Out-String)"
        } 
        elseif (`$taskResult.IsCanceled)
        {
            Write-Verbose -Message 'Operation got cancelled.'
            Throw 'Operation got cancelled.'
        }
        else
        {
            Write-Verbose -Message 'Operation completed successfully.'

            if(`$taskResult.Result -and 
               (Get-Member -InputObject `$taskResult.Result -Name 'Body') -and
               `$taskResult.Result.Body) 
            {
                `$responseStatusCode = `$taskResult.Result.Response.StatusCode.value__
                $responseBody
            }
        }
    }

    End
    {
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