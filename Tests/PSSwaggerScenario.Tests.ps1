Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1")
Describe "Basic API" -Tag ScenarioTest {
    BeforeAll {
        Compile-TestAssembly -TestAssemblyFullPath (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -TestCSharpFilePath (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "TestCredentials.cs") `
            -CompilationUtilsPath (Join-Path "$PSScriptRoot" ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Utils.ps1") -UseAzureCSharpGenerator $false -Verbose
        
        # TODO: Pass all these locations dynamically - See issues/17
        # Ensure PSSwagger isn't loaded (including the one installed on the machine, if any)
        Get-Module PSSwagger | Remove-Module
        $testSpec = "PsSwaggerTestBasicSpec.json"
        $testData = "PsSwaggerTestBasicData.json"
        $testRoutes = "PsSwaggerTestBasicRoutes.json"

        # Import PSSwagger
        Import-Module "$PSScriptRoot\..\PSSwagger\PSSwagger.psd1" -Force

        $generatedModulesPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Generated"
        $testCaseDataLocation = "$PSScriptRoot\Data\PsSwaggerTestBasic"

        # Note: This only works if these tests are never run in parallel, but our current usage of json-server is the same way, so...
        $global:testDataSpec = ConvertFrom-Json ((Get-Content (Join-Path $testCaseDataLocation $testSpec)) -join [Environment]::NewLine) -ErrorAction Stop
        
        # Generate module
        Write-Host "Removing old module, if any"
        if (Test-Path (Join-Path $generatedModulesPath "Generated.Basic.Module")) {
            Remove-Item (Join-Path $generatedModulesPath "Generated.Basic.Module") -Recurse -Force
        }

        Write-Host "Generating module"
        New-PSSwaggerModule -SwaggerSpecPath "$testCaseDataLocation\$testSpec" -Path "$generatedModulesPath" -ModuleName "Generated.Basic.Module" -Verbose -SkipAssemblyGeneration
        if (-not $?) {
            throw 'Failed to generate module. Expected: Success'
        }

        # Import generated module
        Write-Host "Importing module"
        Import-Module "$PSScriptRoot\..\PSSwagger\Generated.Azure.Common.Helpers" -Force
        Import-Module "$PSScriptRoot\Generated\Generated.Basic.Module"
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        # Copy json-server data since it's updated live
        Copy-Item "$testCaseDataLocation\$testData" "$PSScriptRoot\NodeModules\db.json" -Force

        # Start json-server
        # TODO: Pick a port in a certain range that's open instead of hardcoding to 3000, replace the URI in Swagger spec  - See issues/16
        # Snapshot the node processes before starting json-server so we can stop the right one later
        # Not sure if we need it, but we'll also keep the returned process to stop later as well (which does not, by itself, stop json-server)
        $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
        if ($nodeProcesses -eq $null) {
            $nodeProcesses = @()
        } elseif ($nodeProcesses.Count -eq 1) {
            $nodeProcesses = @($nodeProcesses)
        }

        if ('Core' -eq $PSEdition) {
            $jsonServerProcess = Start-Process -FilePath "$PSScriptRoot\NodeModules\json-server.cmd" -ArgumentList "--watch `"$PSScriptRoot\NodeModules\db.json`" --routes `"$testCaseDataLocation\$testRoutes`"" -PassThru
        } else {
            $jsonServerProcess = Start-Process -FilePath "$PSScriptRoot\NodeModules\json-server.cmd" -ArgumentList "--watch `"$PSScriptRoot\NodeModules\db.json`" --routes `"$testCaseDataLocation\$testRoutes`"" -PassThru -WindowStyle Hidden
        }

        # Wait for local json-server to start on full CLR
        if ('Core' -ne $PSEdition) {
            while (-not (Test-NetConnection -ComputerName localhost -Port 3000)) {
                Write-Verbose -Message "Waiting for server to start..." -Verbose
                Start-Sleep -s 1
            }
        }

        $nodeProcessToStop = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {-not $nodeProcesses.Contains($_)}
        while ($nodeProcessToStop -eq $null) {
            $nodeProcessToStop = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {-not $nodeProcesses.Contains($_)}
        }

        Write-Host "json-server started at: $($nodeProcessToStop.ID)"
    }

    Context "Basic API tests" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.Basic.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.Basic.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.Basic.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Basic test" {
            Get-Cupcake -Flavor "chocolate"
            New-Cupcake -Flavor "vanilla"
        }
    }

    AfterAll {
        # Stop json-server
        Write-Host "Stopping process: $($jsonServerProcess.ID)"
        $jsonServerProcess | Stop-Process
        Write-Host "Stopping process: $($nodeProcessToStop.ID)"
        $nodeProcessToStop | Stop-Process
    }
}