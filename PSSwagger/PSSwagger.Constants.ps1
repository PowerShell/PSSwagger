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

if ('Desktop' -eq `$PSEdition) {
    `$clr = 'fullclr'
} else {
    `$clr = 'coreclr'
}

`$dllFullName = Join-Path `$PSScriptRoot 'ref' | Join-Path -ChildPath `$clr | Join-Path -ChildPath '$Namespace.dll'
`$isAzureCSharp = `$$UseAzureCSharpGenerator
if (-not (Test-Path `$dllFullName)) {
    `$message = `$LocalizedData.CompilingBinaryComponent -f (`$dllFullName)
    Write-Verbose -Message `$message -Verbose
    . (Join-Path "`$PSScriptRoot" "CompilationUtils.ps1")
    `$generatedCSharpFilePath = (Join-Path "`$PSScriptRoot" "Generated.Csharp")
    `$catalogDetails = Test-FileCatalog -Path `$generatedCSharpFilePath -CatalogFilePath (Join-Path "`$PSScriptRoot" "$fileCatalogName") -Detailed
    if ('NotSigned' -ne (Get-AuthenticodeSignature -FilePath (Join-Path "`$PSScriptRoot" "`$(`$MyInvocation.MyCommand)")).Status) {
        if ('Valid' -ne (Get-AuthenticodeSignature -FilePath (Join-Path "`$PSScriptRoot" "$fileCatalogName")).Status) {
            `$message = `$LocalizedData.CatalogSignatureNotValid
            throw `$message 
        }
    }
    
    if ('Valid' -ne `$catalogDetails.Status) {
        `$message = `$LocalizedData.HashValidationFailed
        throw `$message
    }

    `$allCSharpFiles = Get-ChildItem -Path `$generatedCSharpFilePath -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | Where-Object DirectoryName -notlike '*Azure.Csharp.Generated*'
    `$success = Compile-CSharpCode -CSharpFiles `$allCSharpFiles -OutputAssembly `$dllFullName -AzureCSharpGenerator `$isAzureCSharp -CopyExtraReferences
    if (-not `$success) {
        `$message = `$LocalizedData.CompilationFailed -f (`$dllFullName)
        throw `$message
    }
}

# Load extra refs then the actual dll
Get-ChildItem -Path (Join-Path "`$PSScriptRoot" "ref" | Join-Path -ChildPath "`$clr") -Filter *.dll -File | ForEach-Object { Add-Type -Path `$_.FullName -ErrorAction SilentlyContinue }
Add-Type -Path `$dllFullName -PassThru

Get-ChildItem -Path "`$PSScriptRoot\$GeneratedCommandsName\*.ps1" -Recurse -File | ForEach-Object { . `$_.FullName}
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

        Write-Verbose 'Performing operation $methodName on $clientName.'
        `$taskResult = $clientName$operations.$methodName($requiredParamList)
        Write-Verbose "Waiting for the operation to complete."
        `$null = `$taskResult.AsyncWaitHandle.WaitOne()
        Write-Debug "`$(`$taskResult | Out-String)"

        if(`$taskResult.IsFaulted)
        {
            Write-Verbose 'Operation failed.'
            Throw "`$(`$taskResult.Exception.InnerExceptions | Out-String)"
        } 
        elseif (`$taskResult.IsCanceled)
        {
            Write-Verbose 'Operation got cancelled.'
            Throw 'Operation got cancelled.'
        }
        else
        {
            Write-Verbose 'Operation completed successfully.'

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
                    
                    Default {Write-Error "Status: `$responseStatusCode received."}
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
