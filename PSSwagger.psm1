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
        [Parameter(Mandatory = $true)]
        [string] $swaggerSpecPath,

        [Parameter(Mandatory = $true)]
        [string] $path,

        [Parameter(Mandatory = $true)]
        [string] $moduleName

        )

    if (-not (Test-path $swaggerSpecPath))
    {
        throw "Swagger file $swaggerSpecPath does not exist. Check the path"
    }

    if ($path.EndsWith($moduleName))
    {
        throw "PATH does not need to end with ModuleName. ModuleName will be appended to the path"
    }

    $outputDirectory = join-path $path $moduleName
    if (Test-Path $outputDirectory)
    {
        throw "Directory $outputDirectory exists. Remove this directory and try again."
    }
    $null = New-Item -ItemType Directory $outputDirectory -ErrorAction Stop

    $namespace = "Microsoft.PowerShell.$moduleName"
    GenerateCsharpCode -swaggerSpecPath $swaggerSpecPath -path $outputDirectory -moduleName $moduleName -nameSpace $namespace
    GenerateModuleManifest -path $outputDirectory -moduleName $moduleName -rootModule "$moduleName.psm1"

    $modulePath = Join-Path $outputDirectory "$moduleName.psm1"

    $cmds = [System.Collections.ObjectModel.Collection[string]]::new()

    $jsonObject = ConvertFrom-Json ((Get-Content $swaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
    $jsonObject.Paths.PSObject.Properties | % {
        $jsonPathObject = $_.Value
        $jsonPathObject.psobject.Properties | % {
               $cmd = GenerateCommand $_.Value
               Write-Verbose $cmd
               $cmds.Add($cmd)
            } # jsonPathObject
    } # jsonObject

    $cmds | Out-File $modulePath -Encoding ASCII
}

#region Cmdlet Generation Helpers

<#
.DESCRIPTION
  Generates a cmdlet given a JSON custom object (from paths)
#>
function GenerateCommand([PSObject] $jsonPathItemObject)
{
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
}
'@

$commandName = ProcessOperationId $jsonPathItemObject.operationId
$description = $jsonPathItemObject.description
$commandHelp = $executionContext.InvokeCommand.ExpandString($helpDescStr)

[string]$paramHelp = ""
$paramblock,$paramHelp = ProcessParameters $jsonPathItemObject.parameters

$executionContext.InvokeCommand.ExpandString($advFnSignature)

}
<#
.DESCRIPTION
  Returns a string that can be used in a parameter block.
#>
function ProcessParameters
{
    param(
    [object[]] $parametersSpec)
    
    $parameterDefString = @'
    
    [Parameter(Mandatory = $isParamMandatory)]
    [$paramType] $paramName,
'@

$helpParamStr = @'

.PARAMETER $paramName
    $pDescription

'@

    $paramBlockToReturn = ""
    [string]$tempParamHelp = ""
    
    $parametersSpec | % {
        # TODO: What to do with $ref
        if ($_.Name)
        {            
            $isParamMandatory = '$false'
            $paramName = '$' + $_.Name
            $paramType = if ($_.type) { $_.type } else { "object" }
            if ($_.required) { $isParamMandatory = '$true' }
            $paramBlockToReturn  += $executionContext.InvokeCommand.ExpandString($parameterDefString)
            if ($_.description)
            {
                $pDescription = $_.description
                #$tempParamHelp += $executionContext.InvokeCommand.ExpandString($helpParamStr)
                $tempParamHelp += @"

.PARAMETER $($_.Name)
    $pDescription

"@
            }
        }       
    } # $parametersSpec

    $paramBlockToReturn.TrimEnd(",")
    $tempParamHelp
}

<#
.DESCRIPTION
  Converts an operation id to a reasonably good cmdlet name
#>
function ProcessOperationId
{
    param([string] $opId)
    
    $cmdNounMap = @{"Create" = "New"; "Activate" = "Enable"; "Delete" = "Remove";
                    "List"   = "Get"}
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
            for(; $idx -lt $opIdValues[1].Length; $idx++) { if (([int]$opIdValues[1][$idx] -ge 65) -and ([int]$opIdValues[1][$idx] -le 90)) {break;} }
            $cmdNoun = $cmdNoun + $opIdValues[1].Substring($idx)
            $cmdVerb = $opIdValues[1].Substring(0,$idx)
            if ($cmdNounMap.ContainsKey($cmdVerb)) { $cmdVerb = $cmdNounMap[$cmdVerb] }          

            Write-Verbose "Using Noun $cmdNoun. Using Verb $cmdVerb"
        }
    }
    return "$cmdVerb-$cmdNoun"
}

#endregion

#region Module Generation Helpers

function GenerateCsharpCode
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $swaggerSpecPath,

        [Parameter(Mandatory = $true)]
        [string] $path,

        [Parameter(Mandatory = $true)]
        [string] $moduleName,

        [Parameter(Mandatory = $true)]
        [string] $nameSpace
        
        )

    Write-Verbose "Generating CSharp Code using AutoRest"

    $autoRestExePath = get-command autorest.exe | % source
    if (-not $autoRestExePath)
    {
        throw "Unable to find AutoRest.exe in PATH environment. Ensure the PATH is updated."
    }

    $outputDirectory = $path
    $outAssembly = join-path $outputDirectory azure.csharp.ps.generated.dll
    $net45Dir = join-path $outputDirectory "Net45"
    $generatedCSharpPath = Join-Path $outputDirectory "Generated.Csharp"
    $startUpScriptFile = (join-path $outputDirectory $moduleName) + ".StartupScript.ps1"
    $moduleManifestFile = (join-path $outputDirectory $moduleName) + ".psd1"

    if (Test-Path $outAssembly)
    {
        del $outAssembly -Force
    }

    if (Test-Path $net45Dir)
    {
        del $net45Dir -Force -Recurse
    }

    & $autoRestExePath -input $swaggerSpecPath -CodeGenerator CSharp -OutputDirectory $generatedCSharpPath -NameSpace $nameSpace
    if ($LastExitCode)
    {
        throw "AutoRest resulted in an error"
    }

    Write-Verbose "Generating assembly from the CSharp code"

    $srcContent = dir $generatedCSharpPath  -Filter *.cs -Recurse -Exclude Program.cs,TemporaryGeneratedFile* | ? DirectoryName -notlike '*Azure.Csharp.Generated*' | % { "// File $($_.FullName)"; get-content $_.FullName }
    $oneSrc = $srcContent -join "`n"

    $refassemlbiles = @("System.dll","System.Core.dll","System.Net.Http.dll",
                    "System.Net.Http.WebRequest","System.Runtime.Serialization.dll","System.Xml.dll",
                    "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Microsoft.Rest.ClientRuntime.dll",
                    "$PSScriptRoot\Generated.Azure.Common.Helpers\Net45\Newtonsoft.Json.dll")

    Add-Type -TypeDefinition $oneSrc -ReferencedAssemblies $refassemlbiles -OutputAssembly $outAssembly
}

function GenerateModuleManifest
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $path,

        [Parameter(Mandatory = $true)]
        [string] $moduleName,

        [Parameter(Mandatory = $true)]
        [string] $rootModule
    )

    $startUpScriptFile = (join-path $path $moduleName) + ".StartupScript.ps1"
    $moduleManifestFile = (join-path $path $moduleName) + ".psd1"
    
    @'
    Add-Type -LiteralPath "$PSScriptRoot\azure.csharp.ps.generated.dll"
'@ | out-file -Encoding Ascii $startUpScriptFile

    New-ModuleManifest -Path $moduleManifestFile -Guid (New-Guid) -Author (whoami) -ScriptsToProcess ($moduleName + ".StartupScript.ps1") -RequiredModules "Generated.Azure.Common.Helpers" -RootModule "$rootModule"
}

#endregion