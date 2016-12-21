
#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# PSSwagger Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
  Decodes the swagger spec and generates PowerShell cmdlets.

.PARAMETER  SwaggerSpecPath
  Full Path to a Swagger based JSON spec.

.PARAMETER  Path
  Full Path to a file where the commands are exported to.
#>
function Export-CommandFromSwagger
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerPath')]
        [String] 
        $SwaggerSpecPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'SwaggerURI')]
        [Uri]
        $SwaggerSpecUri,

        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleName,

        [Parameter()]
        [switch]
        $UseAzureCsharpGenerator
    )

    if ($PSCmdlet.ParameterSetName -eq 'SwaggerURI')
    {
        # Ensure that if the URI is coming from github, it is getting the raw content
        if($SwaggerSpecUri.Host -eq 'github.com'){
            $SwaggerSpecUri = "https://raw.githubusercontent.com$($SwaggerSpecUri.AbsolutePath)"
            Write-Verbose "Converting SwaggerSpecUri to raw github content $SwaggerSpecUri" -Verbose
        }

        $SwaggerSpecPath = [io.path]::GetTempFileName() + ".json"
        Write-Verbose "Swagger spec from $SwaggerSpecURI is downloaded to $SwaggerSpecPath"
        
        $ev = $null
        Invoke-WebRequest -Uri $SwaggerSpecUri -OutFile $SwaggerSpecPath -ErrorVariable ev
        if($ev) {
            return 
        }
    }

    if (-not (Test-path $SwaggerSpecPath))
    {
        throw "Swagger file $SwaggerSpecPath does not exist. Check the path"
    }

    $outputDirectory = $Path
    if (-not $Path.EndsWith($ModuleName, [System.StringComparison]::OrdinalIgnoreCase))
    {
        $outputDirectory = Join-Path -Path $Path -ChildPath $ModuleName
    }

    $null = New-Item -ItemType Directory $outputDirectory -Force -ErrorAction Stop

    $jsonObject = ConvertFrom-Json ((Get-Content $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop

    # Populate the metadata, definitions and parameters from the provided Swagger specification
    $SwaggerSpecDefinitionsAndParameters = Get-SwaggerSpecDefinitionsAndParameters -SwaggerSpecJsonObject $jsonObject -ModuleName $ModuleName

    $namespace = $SwaggerSpecDefinitionsAndParameters['Namespace']
    ConvertTo-CsharpCode -SwaggerSpecPath $SwaggerSpecPath `
                         -Path $outputDirectory `
                         -ModuleName $ModuleName `
                         -NameSpace $namespace `
                         -UseAzureCsharpGenerator:$UseAzureCsharpGenerator

    $modulePath = Join-Path $outputDirectory "$ModuleName.psm1"

    $cmds = New-Object -TypeName System.Collections.ObjectModel.Collection[string]

    # Handle the paths
    $jsonObject.Paths.PSObject.Properties | ForEach-Object {
        $jsonPathObject = $_.Value
        $jsonPathObject.psobject.Properties | ForEach-Object {
               $cmd = New-SwaggerSpecCommand $_.Value -UseAzureCsharpGenerator:$UseAzureCsharpGenerator -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters
               if($cmd) {
                   Write-Verbose $cmd
                   $cmds.Add($cmd)
               }
            } # jsonPathObject
    } # jsonObject

    $cmds | Out-File $modulePath -Encoding ASCII

    New-ModuleManifestUtility -Path $outputDirectory -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters
}

#region Cmdlet Generation Helpers

<#
.DESCRIPTION
  Generates a cmdlet given a JSON custom object (from paths)
#>
function New-SwaggerSpecCommand
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $UseAzureCsharpGenerator,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $SwaggerSpecDefinitionsAndParameters 
    )

$helpDescStr = @'
.DESCRIPTION
    $description
'@

$advFnSignature = @'
<#
$commandHelp
$paramHelp
#>
function $commandName
{
   [CmdletBinding()]
   param($paramblock
   )

   $body
}
'@

$parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)]
    [$paramType] $paramName,
'@

$helpParamStr = @'

.PARAMETER $parameterName
    $pDescription

'@

$functionBodyStr = @'

    `$serviceCredentials =  Get-AzServiceCredential
    `$subscriptionId = Get-AzSubscriptionId
    `$delegatingHandler = Get-AzDelegatingHandler

    $clientName = New-Object -TypeName $fullModuleName -ArgumentList `$serviceCredentials,`$delegatingHandler
    $apiVersion
    $clientName.SubscriptionId = `$subscriptionId
    
    Write-Verbose 'Performing operation $methodName on $clientName.'
    `$taskResult = $clientName.$operations.$methodName($requiredParamList)
    Write-Verbose "Waiting for the operation to complete."
    `$taskResult.AsyncWaitHandle.WaitOne() | out-null
    Write-Debug "`$(`$taskResult | Out-String)"

    if(`$taskResult.IsFaulted) {
       Write-Verbose 'Operation failed.'
       Throw "`$(`$taskResult.Exception.InnerExceptions | Out-String)"
    } elseif (`$taskResult.IsCanceled) {
       Write-Verbose 'Operation got cancelled.'
       Throw 'Operation got cancelled.'
    } else {
        Write-Verbose 'Operation completed successfully.'

        if(`$taskResult.Result -and `$taskResult.Result.Body) {
            Write-Verbose -Message "`$(`$taskResult.Result.Body | Out-String)"
            `$taskResult.Result.Body
        }
    }
    
'@
 
    $commandName = Get-SwaggerCommandName $JsonPathItemObject
    $description = ""
    if((Get-Member -InputObject $JsonPathItemObject -Name 'Description') -and $JsonPathItemObject.Description) {
        $description = $JsonPathItemObject.Description
    }
    $commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

    [string]$paramHelp = ""
    $paramblock = ""
    $requiredParamList = @()
    $optionalParamList = @()
    $body = ""

    # Handle the function parameters
    #region Function Parameters

    $JsonPathItemObject.parameters | ForEach-Object {
        if((Get-Member -InputObject $_ -Name 'Name') -and $_.Name)
        {
            $isParamMandatory = '$false'
            $parameterName = Remove-SpecialCharecters -Name $_.Name
            $paramName = "`$$parameterName" 
            $paramType = if ( (Get-Member -InputObject $_ -Name 'Type') -and $_.Type) { $_.Type } else { "object" }
            if ($_.Required)
            { 
                $isParamMandatory = '$true'
                $requiredParamList += $paramName
            }
            else
            {
                $optionalParamList += $paramName
            }

            $paramblock += $executionContext.InvokeCommand.ExpandString($parameterDefString)

            if ((Get-Member -InputObject $_ -Name 'Description') -and $_.Description)
            {
                $pDescription = $_.Description
                $paramHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
            }
        }
        elseif((Get-Member -InputObject $_ -Name '$ref') -and ($_.'$ref'))
        {
        }
    }# $parametersSpec

    $paramblock = $paramBlock.TrimEnd(",")
    $requiredParamList = $requiredParamList -join ', '
    $optionalParamList = $optionalParamList -join ', '

    #endregion Function Parameters

    # Handle the function body
    #region Function Body
    $infoVersion = $SwaggerSpecDefinitionsAndParameters['infoVersion']
    $modulePostfix = $SwaggerSpecDefinitionsAndParameters['infoName']
    $fullModuleName = $SwaggerSpecDefinitionsAndParameters['namespace'] + '.' + $modulePostfix
    $clientName = '$' + $modulePostfix
    $apiVersion = ''
    if (-not $UseAzureCsharpGenerator)
    {
        $apiVersion = '{0}.ApiVersion = "{1}"' -f $clientName,$infoVersion
    }

    $operationName = $JsonPathItemObject.operationId.Split('_')[0]
    $operationType = $JsonPathItemObject.operationId.Split('_')[1]
    $operations = $operationName 
    if ((-not $UseAzureCsharpGenerator) -and (Test-OperationNameInDefinitionList -Name $operationName -SwaggerSpecDefinitionsAndParameters $SwaggerSpecDefinitionsAndParameters))
    { 
        $operations = $operations + 'Operations'
    }
    $methodName = $operationType + 'WithHttpMessagesAsync'
    $operationVar = '$' + $operationName

    $body = $executionContext.InvokeCommand.ExpandString($functionBodyStr)

    #endregion Function Body

    $executionContext.InvokeCommand.ExpandString($advFnSignature)
}

<#
.DESCRIPTION
  Converts an operation id to a reasonably good cmdlet name
#>
function Get-SwaggerCommandName
{
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]
        $JsonPathItemObject    
    )

    if((Get-Member -InputObject $JsonPathItemObject -Name 'x-ms-cmdlet-name') -and $JsonPathItemObject.'x-ms-cmdlet-name') { 
        return $JsonPathItemObject.'x-ms-cmdlet-name'
    }

    $opId = $JsonPathItemObject.OperationId
    $cmdNounMap = @{
                    Create = 'New'
                    Activate = 'Enable'
                    Delete = 'Remove'
                    List   = 'GetAll'
                }
    $opIdValues = $opId.Split('_')
    $cmdNoun = $opIdValues[0]
    $cmdVerb = $opIdValues[1]
    if (-not (get-verb $cmdVerb))
    {
        Write-Verbose "Verb $cmdVerb not an approved verb."
        if ($cmdNounMap.ContainsKey($cmdVerb))
        {
            Write-Verbose "Using Verb $($cmdNounMap[$cmdVerb]) in place of $cmdVerb."
            $cmdVerb = $cmdNounMap[$cmdVerb]
        }
        else
        {
            $idx=1
            for(; $idx -lt $opIdValues[1].Length; $idx++)
            { 
                if (([int]$opIdValues[1][$idx] -ge 65) -and ([int]$opIdValues[1][$idx] -le 90)) {
                    break
                }
            }
            
            $cmdNounSuffix = $opIdValues[1].Substring($idx)
            # Add command noun suffix only when the current noun is not ending with the same suffix. 
            if(-not $cmdNoun.EndsWith($cmdNounSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $cmdNoun = $cmdNoun + $opIdValues[1].Substring($idx)
            }
            
            $cmdVerb = $opIdValues[1].Substring(0,$idx)            
            if ($cmdNounMap.ContainsKey($cmdVerb)) { 
                $cmdVerb = $cmdNounMap[$cmdVerb]
            }          

            Write-Verbose "Using Noun $cmdNoun. Using Verb $cmdVerb"
        }
    }

    return "$cmdVerb-$cmdNoun"
}

function Get-SwaggerSpecDefinitionsAndParameters
{
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecJsonObject,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName
    )

    if(-not (Get-Member -InputObject $jsonObject -Name 'info')) {
        Throw "Invalid Swagger specification file. Info section doesn't exists."
    }

    $SwaggerSpecificationDetails = @{}    

    # Get info entries
    $info = $SwaggerSpecJsonObject.info 
    
    $infoVersion = '1-0-0'
    if((Get-Member -InputObject $info -Name 'Version') -and $info.Version) { 
        $infoVersion = $info.Version
    }

    $infoTitle = $info.title
    $infoName = ''
    if((Get-Member -InputObject $info -Name 'x-ms-code-generation-settings') -and $info.'x-ms-code-generation-settings'.Name) { 
        $infoName = $info.'x-ms-code-generation-settings'.Name
    }

    if (-not $infoName) {
         $infoName = $infoTitle
    }

    $SwaggerSpecificationDetails['infoVersion'] = $infoVersion
    $SwaggerSpecificationDetails['infoTitle'] = $infoTitle
    $SwaggerSpecificationDetails['infoName'] = $infoName
    $SwaggerSpecificationDetails['Version'] = ($infoVersion -split "-",4) -join '.' 
    $NamespaceVersionSuffix = "v$(($infoVersion -split '-',4) -join '')"
    $SwaggerSpecificationDetails['Namespace'] = "Microsoft.PowerShell.$ModuleName.$NamespaceVersionSuffix"
    $SwaggerSpecificationDetails['ModuleName'] = $ModuleName

    if(Get-Member -InputObject $jsonObject -Name 'parameters') {    
        # Get global parameters
        $globalParams = $SwaggerSpecJsonObject.parameters
        $globalParams.PSObject.Properties | ForEach-Object {
            $name = Remove-SpecialCharecters -Name $_.name
            $SwaggerSpecificationDetails[$name] = $globalParams.$name
        }
    }

    $definitionList = @{}
    if(Get-Member -InputObject $jsonObject -Name 'definitions') {
        # Get definitions list
        $definitions = $SwaggerSpecJsonObject.definitions
        $definitions.PSObject.Properties | ForEach-Object {
            $name = $_.name
            $definitionList.Add($name, $_)
        }
    }
    $SwaggerSpecificationDetails['definitionList'] = $definitionList

    return $SwaggerSpecificationDetails
}

function Remove-SpecialCharecters
{
    param([string] $Name)

    $pattern = '[^a-zA-Z]'
    return ($Name -replace $pattern, '')
}

function Test-OperationNameInDefinitionList
{
    param(
        [string] 
        $Name,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    $definitionList = $SwaggerSpecDefinitionsAndParameters['definitionList']
    if ($definitionList.ContainsKey($Name))
    {
        return $true
    }
    return $false
}

#endregion

#region Module Generation Helpers

function ConvertTo-CsharpCode
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $SwaggerSpecPath,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $ModuleName,

        [Parameter(Mandatory = $true)]
        [string] $Namespace,

        [Parameter()]
        [switch] $UseAzureCsharpGenerator        
        )

    Write-Verbose "Generating CSharp Code using AutoRest"

    $autoRestExePath = get-command autorest.exe | % source
    if (-not $autoRestExePath)
    {
        throw "Unable to find AutoRest.exe in PATH environment. Ensure the PATH is updated."
    }

    $outputDirectory = $Path
    $outAssembly = join-path $outputDirectory "$Namespace.dll"
    $net45Dir = join-path $outputDirectory "Net45"
    $generatedCSharpPath = Join-Path $outputDirectory "Generated.Csharp"
    $moduleManifestFile = (join-path $outputDirectory $ModuleName) + ".psd1"

    if (Test-Path $outAssembly)
    {
        del $outAssembly -Force
    }

    if (Test-Path $net45Dir)
    {
        del $net45Dir -Force -Recurse
    }

    $codeGenerator = "CSharp"
    
    $refassemlbiles = @("System.dll",
                        "System.Core.dll",
                        "System.Net.Http.dll",
                        "System.Net.Http.WebRequest",
                        "System.Runtime.Serialization.dll",
                        "System.Xml.dll",
                        "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Microsoft.Rest.ClientRuntime.dll",
                        "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Newtonsoft.Json.dll")

    if ($UseAzureCsharpGenerator) 
    { 
        $codeGenerator = "Azure.CSharp"
        $refassemlbiles += "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Microsoft.Rest.ClientRuntime.Azure.dll"
    }

    & $autoRestExePath -AddCredentials -input $SwaggerSpecPath -CodeGenerator $codeGenerator -OutputDirectory $generatedCSharpPath -NameSpace $Namespace
    if ($LastExitCode)
    {
        throw "AutoRest resulted in an error"
    }

    Write-Verbose "Generating assembly from the CSharp code"

    $srcContent = dir $generatedCSharpPath  -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | ? DirectoryName -notlike '*Azure.Csharp.Generated*' | % { "// File $($_.FullName)"; get-content $_.FullName }
    $oneSrc = $srcContent -join "`n"

    Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies $refassemlbiles -OutputAssembly $outAssembly

    if(Test-Path -Path $outAssembly -PathType Leaf){
        Write-Verbose -Message "Generated $outAssembly assembly"
    } else {
        Throw "Unable to generated $outAssembly assembly"
    }
}

function New-ModuleManifestUtility
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]        
        [PSCustomObject]
        $SwaggerSpecDefinitionsAndParameters
    )

    New-ModuleManifest -Path "$(Join-Path -Path $Path -ChildPath $SwaggerSpecDefinitionsAndParameters['ModuleName']).psd1" `
                       -ModuleVersion $SwaggerSpecDefinitionsAndParameters['Version'] `
                       -RequiredModules @('Generated.Azure.Common.Helpers') `
                       -RequiredAssemblies @("$($SwaggerSpecDefinitionsAndParameters['Namespace']).dll") `
                       -RootModule "$($SwaggerSpecDefinitionsAndParameters['ModuleName']).psm1" `
                       -FunctionsToExport '*'
}

# Utility to throw an errorrecord
function Write-TerminatingError
{
    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,
        
        [System.Object]
        $ExceptionObject,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
        
    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject    
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}

#endregion

Export-ModuleMember -Function Export-CommandFromSwagger
