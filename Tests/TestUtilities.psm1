#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Tests
#
#########################################################################################
# Ensures a package source exists for the location "http://nuget.org/api/v2/"
function Test-NugetPackageSource {
    $bestNugetLocation = "http://nuget.org/api/v2/"
    $nugetPackageSource = Get-PackageSource | Where-Object {($_.ProviderName -eq "NuGet") -and ($_.Location -eq $bestNugetLocation) } | Select-Object -First 1
    Write-Verbose "Attempted to find NuGet package source. Got: $nugetPackageSource"
    if ($nugetPackageSource -eq $null) {
        Write-Verbose "No NuGet package source found for location $bestNugetLocation. Registering source PSSwaggerNuget."
        $nugetPackageSource = Register-PackageSource "PSSwaggerNuget" -Location $bestNugetLocation -ProviderName "NuGet" -Trusted -Force
    }

    return $nugetPackageSource
}

# Ensures a given package exists. Caller should validate if returned module is null or not (null indicates the package failed to install)
function Test-Package {
    param(
        [string]$packageName,
        [string]$packageSourceName,
        [string]$providerName = "NuGet",
        [string]
        [AllowEmptyString()]
        $requiredVersion = ""
    )

    $getParams = @{
        Name = $packageName
        ProviderName = $providerName
        ErrorAction = 'Ignore'
    }
    if ($requiredVersion) {
        $getParams['RequiredVersion'] = $requiredVersion
    }
    $package = Get-Package @getParams | Select-Object -First 1
    if ($package -eq $null) {
        Write-Verbose "Trying to install missing package $packageName from source $packageSourceName"
        $installParams = @{
            Name = $packageName
            ProviderName = $providerName
            Source = $packageSourceName
            Force = $true
        }
        if ($requiredVersion) {
            $installParams['RequiredVersion'] = $requiredVersion
        }
		
        $null = Install-Package @installParams
        $package = Get-Package @getParams | Select-Object -First 1
    }

    $package
}

function Invoke-NewPSSwaggerModuleCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $NewPSSwaggerModuleParameters,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeAssembly
    )

    Initialize-PSSwaggerDependencies -AllFrameworks -AcceptBootstrap -Azure
    
    $NewPSSwaggerModuleParameters['ErrorAction'] = 'SilentlyContinue'
    if ($IncludeAssembly) {
        $NewPSSwaggerModuleParameters['NoAssembly'] = $false
        $NewPSSwaggerModuleParameters['ConfirmBootstrap'] = $true
    }
    elseif (-not $NewPSSwaggerModuleParameters.ContainsKey('AssemblyFileName'))  {
        $NewPSSwaggerModuleParameters['NoAssembly'] = $true
    }

    if ((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
        if ($IncludeAssembly) {
            $NewPSSwaggerModuleParameters['IncludeCoreFxAssembly'] = $true
            $NewPSSwaggerModuleParameters['PowerShellCorePath'] = Join-Path -Path $PSHOME -ChildPath 'PowerShell.exe'
        }

        $ParametersString = ''
        $NewPSSwaggerModuleParameters.GetEnumerator() | ForEach-Object {
            if ($_.Value -eq $true) {
                $ParametersString += " -$($_.Name)"
            }
            elseif ($_.Value -ne $false) {
                $ParametersString += " -$($_.Name) '$($_.Value)'"
            }
        }
        # For now this hides Exception and ErrorObject
        $command = "& {
            `$env:PSModulePath=`$env:PSModulePath_Backup;
            New-PSSwaggerModule $ParametersString -ErrorVariable evtemp
            foreach (`$ev in `$evtemp) {
                `$returnEv = `$false
                `$evEncoded = 'ErrorVariable: '
                if (`$ev.FullyQualifiedErrorId) {
                    `$evEncoded += 'ErrorId='
                    `$evEncoded += `$ev.FullyQualifiedErrorId
                    `$evEncoded += ';'
                    `$returnEv = `$true
                }

                if (`$ev.CategoryInfo) {
                    `$evEncoded += 'ErrorCategory='
                    `$evEncoded += `$ev.CategoryInfo.Category
                    `$evEncoded += ';'
                    `$returnEv = `$true
                }

                if (`$returnEv) {
                    `$evEncoded
                }
            }
        }"
        $result = & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\PowerShell.exe" -command $command
        if ($PSBoundParameters.ContainsKey("ErrorVariable")) {
            foreach ($resultLine in $result) {
                if ($resultLine.StartsWith("ErrorVariable: ")) {
                    $errorVariableInfoTokenPairs = $resultLine.Substring(15).Split(';')
                    $errorId = ''
                    $errorCategory = ''
                    for ($i = 0; $i -lt $errorVariableInfoTokenPairs.Length; $i++) {
                        $errorVariableInfoTokens = $errorVariableInfoTokenPairs[$i].Split('=')
                        if ($errorVariableInfoTokens[0] -eq 'ErrorId') {
                            $errorId = $errorVariableInfoTokens[1]
                        } elseif ($errorVariableInfoTokens[0] -eq 'ErrorCategory') {
                            $errorCategory = $errorVariableInfoTokens[1]
                        }
                    }

                    Write-Error -Message 'New-PSSwaggerModule remote error' -ErrorId $errorId -Category $errorCategory
                }
            }
        }
        $result
    }
    else {
        New-PSSwaggerModule @NewPSSwaggerModuleParameters
    }
}

function Remove-TestErrorId {
    [CmdletBinding()]
    param(
        [string]$FullyQualifiedErrorId
    )

    $errorIds = $FullyQualifiedErrorId.Split(',')
    $NewFullyQualifiedErrorId = ''
    for ($i = 0; $i -lt $errorIds.Length; $i++) {
        if ($errorIds[$i] -ne 'Invoke-NewPSSwaggerModuleCommand') {
            $NewFullyQualifiedErrorId += "$($errorIds[$i]),"
        }
    }

    return $NewFullyQualifiedErrorId.Substring(0, $NewFullyQualifiedErrorId.Length - 1)
}
function Initialize-Test {
    [CmdletBinding()]
    param(
        [string]$GeneratedModuleName,
        [string]$TestApiName,
        [string]$TestSpecFileName,
        [string]$TestDataFileName,
        [string]$PsSwaggerPath,
        [string]$TestRootPath,
        [string]$GeneratedModuleVersion = "0.0.1",
        [switch]$UseAzureCSharpGenerator,
        [switch]$CopyUtilityModuleToOutput,
        [string]$DefaultCommandPrefix = ""
    )

    # TODO: Pass all these locations dynamically - See issues/17
    $generatedModulesPath = Join-Path -Path "$TestRootPath" -ChildPath "Generated"
    $testCaseDataLocation = Join-Path -Path "$TestRootPath" -ChildPath "Data" | Join-Path -ChildPath "$TestApiName"

    # Note: This only works if these tests are never run in parallel, but our current usage of json-server is the same way, so...
    $global:testDataSpec = ConvertFrom-Json ((Get-Content (Join-Path -Path $testCaseDataLocation -ChildPath $TestSpecFileName)) -join [Environment]::NewLine) -ErrorAction Stop
        
    # Generate module
    Write-Verbose "Removing old module, if any"
    if (Test-Path (Join-Path $generatedModulesPath $GeneratedModuleName)) {
        Remove-Item (Join-Path $generatedModulesPath $GeneratedModuleName) -Recurse -Force
    }

    # Module generation part needs to happen in full powershell
    Write-Verbose "Generating module"
    if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
        & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\PowerShell.exe" -command "& {`$env:PSModulePath=`$env:PSModulePath_Backup;
            Import-Module (Join-Path `"$PsSwaggerPath`" `"PSSwagger.psd1`") -Force;
            Initialize-PSSwaggerDependencies -AllFrameworks -AcceptBootstrap -Azure:`$$UseAzureCSharpGenerator;
            New-PSSwaggerModule -SpecificationPath (Join-Path -Path `"$testCaseDataLocation`" -ChildPath $TestSpecFileName) -Path "$generatedModulesPath" -Name $GeneratedModuleName -Version $GeneratedModuleVersion -Verbose -NoAssembly -UseAzureCSharpGenerator:`$$UseAzureCSharpGenerator -CopyUtilityModuleToOutput:`$$CopyUtilityModuleToOutput -ConfirmBootstrap -DefaultCommandPrefix $DefaultCommandPrefix;
        }"
    } else {
        Import-Module (Join-Path "$PsSwaggerPath" "PSSwagger.psd1") -Force
        New-PSSwaggerModule -SpecificationPath (Join-Path -Path "$testCaseDataLocation" -ChildPath $TestSpecFileName) -Path "$generatedModulesPath" -Name $GeneratedModuleName -Version $GeneratedModuleVersion -Verbose -NoAssembly -UseAzureCSharpGenerator:$UseAzureCSharpGenerator -CopyUtilityModuleToOutput:$CopyUtilityModuleToOutput -ConfirmBootstrap -DefaultCommandPrefix $DefaultCommandPrefix
    }
    
    if ($TestDataFileName) {
        # Copy json-server data since it's updated live
        Copy-Item "$testCaseDataLocation\$TestDataFileName" "$TestRootPath\NodeModules\db.json" -Force
    }
}

function Start-JsonServer {
    [CmdletBinding()]
    param(
        [string]$TestRootPath,
        [string]$TestApiName,
        [string]$TestRoutesFileName,
        [string[]]$TestMiddlewareFileNames,
        [string]$CustomServerParameters
    )

    $testCaseDataLocation = Join-Path -Path "$TestRootPath" -ChildPath "Data" | Join-Path -ChildPath "$TestApiName"

    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses -eq $null) {
        $nodeProcesses = @()
    } elseif ($nodeProcesses.Count -eq 1) {
        $nodeProcesses = @($nodeProcesses)
    }

    foreach ($nodeProcess in $nodeProcesses) {
        Write-Verbose -Message ($nodeProcess | Out-String)
    }

    $argList = "--watch `"$PSScriptRoot\NodeModules\db.json`""
    if ($TestRoutesFileName) {
        $argList += " --routes `"$testCaseDataLocation\$TestRoutesFileName`""
    }

    if ($TestMiddlewareFileNames) {
        $middlewares = $TestMiddlewareFileNames | ForEach-Object { "`"$testCaseDataLocation\$_`"" }
        $argList += " --middlewares $($middlewares -join ' ')"
    }

    if ($CustomServerParameters) {
        $argList += " $CustomServerParameters"
    }

    Write-Host "Starting json-server: $PSScriptRoot\NodeModules\json-server.cmd $argList"
    if ('Core' -eq $PSEdition) {
        $jsonServerProcess = Start-Process -FilePath "$PSScriptRoot\NodeModules\json-server.cmd" -ArgumentList $argList -PassThru
    } else {
        $jsonServerProcess = Start-Process -FilePath "$PSScriptRoot\NodeModules\json-server.cmd" -ArgumentList $argList -PassThru -WindowStyle Hidden
    }

    # Wait for local json-server to start 
    Write-Verbose -Message "Waiting for server to start..."
    while (-not (Test-Connection -ComputerName localhost -Port 3000)) {
        Start-Sleep -s 1
    }

    Write-Verbose -Message "Server started"
    $nodeProcessToStop = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {-not $nodeProcesses.Contains($_)}
    while ($nodeProcessToStop -eq $null) {
        $nodeProcessToStop = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {-not $nodeProcesses.Contains($_)}
    }

    Write-Verbose -Message "Node process: $($nodeProcessToStop | Out-String)"

    $props = @{
        ServerProcess = $jsonServerProcess;
        NodeProcess = $nodeProcessToStop
    }

    return New-Object -TypeName PSObject -Property $props
}

function Test-Connection {
    [CmdletBinding()]
    param(
        [string]
        $ComputerName,

        [int]
        $Port
    )

    if ('Core' -ne $PSEdition) {
        return (Test-NetConnection -ComputerName localhost -Port 3000).TcpTestSucceeded
    } else {
        $conn = New-Object -TypeName System.Net.Sockets.TcpClient
        $task = $conn.ConnectAsync($ComputerName, $Port)
        $null = $task.AsyncWaitHandle.WaitOne()
        return $conn.Connected
    }
}

function Stop-JsonServer {
    [CmdletBinding()]
    param(
        [System.Diagnostics.Process]$JsonServerProcess,
        [System.Diagnostics.Process]$NodeProcess
    )
    if ($JsonServerProcess) {
        Write-Host "Stopping process: $($JsonServerProcess.ID)"
        $JsonServerProcess | Stop-Process
    }
    if ($NodeProcess) {
        Write-Host "Stopping process: $($NodeProcess.ID)"
        $NodeProcess | Stop-Process
    }
}