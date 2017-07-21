Describe "Build" {
    BeforeAll {
        # Import PSSwagger.LiveTestFramework
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath .. | Join-Path -ChildPath .. | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwagger.Common.Helpers" | Join-Path -ChildPath "PSSwagger.Common.Helpers.psd1")
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath .. | Join-Path -ChildPath "PSSwagger.LiveTestFramework.psd1")
    }

    BeforeEach {
        $s = New-PSSession -ComputerName localhost
        $rootPath = Join-Path -Path $PSScriptRoot -ChildPath .. | Join-Path -ChildPath ..
        Invoke-Command -Session $s -ScriptBlock { param($rootPath) Import-Module -Name (Join-Path -Path $rootPath -ChildPath .. | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwagger.Common.Helpers" | Join-Path -ChildPath "PSSwagger.Common.Helpers.psd1") } -Args $rootPath
        Invoke-Command -Session $s -ScriptBlock { param($rootPath) Import-Module -Name (Join-Path -Path $rootPath -ChildPath "PSSwagger.LiveTestFramework.psd1")} -Args $rootPath
    }

    AfterEach {
        $s | Remove-PSSession
    }

    Context "Test building using Add-Type" {
        It "Compiles library with minimum parameters" {
            Invoke-Command -Session $s -ScriptBlock { Add-PSSwaggerLiveTestLibType -BootstrapConsent }
            $t = Invoke-Command -Session $s -ScriptBlock { [AppDomain]::CurrentDomain.GetAssemblies() | %{ $_.GetTypes() } | Where-Object { $_.Name -eq 'LiveTestServer' } }
            $t | should not benullorempty
        }

        It "Compiles library with custom output directory and name" {
            $customOutputDir = Join-Path -Path $PSScriptRoot -ChildPath 'mybin' | Join-Path -ChildPath 'fullclr'
            $customFileName = 'Lib.dll'
            $expectedOutputPath = Join-Path -Path $customOutputDir -ChildPath $customFileName
            if (Test-Path -Path $expectedOutputPath)
            {
                Remove-Item -Path $expectedOutputPath
            }
            Invoke-Command -Session $s -ScriptBlock { param($customOutputDir, $customFileName) Add-PSSwaggerLiveTestLibType -BootstrapConsent -OutputDirectory $customOutputDir -OutputFileName $customFileName -SaveAssembly } -Args $customOutputDir,$customFileName
            Get-Item -Path $expectedOutputPath -ErrorAction Ignore | should not benullorempty
        }

        It "Compiles library with debug symbols" {
            $expectedOutputPath = Invoke-Command -Session $s -ScriptBlock {
                $testModule = Get-Module PSSwagger.LiveTestFramework
                Join-Path -Path $testModule.ModuleBase -ChildPath 'bin' | Join-Path -ChildPath 'fullclr' | Join-Path -ChildPath 'PSSwagger.LTF.Lib.dll'
            }
            $debugPath = Join-Path -Path $PSScriptRoot -ChildPath 'debug'
            if (Test-Path -Path $expectedOutputPath)
            {
                Remove-Item -Path $expectedOutputPath
            }
            if (Test-Path -Path $debugPath)
            {
                Remove-Item -Path $debugPath -Recurse
            }

            Invoke-Command -Session $s -ScriptBlock { param($debugPath) Add-PSSwaggerLiveTestLibType -BootstrapConsent -DebugSymbolDirectory $debugPath -SaveAssembly } -Args $debugPath
            Get-Item -Path $expectedOutputPath -ErrorAction Ignore | should not benullorempty
            $csFiles = Get-ChildItem -Path (Join-Path -Path $debugPath -ChildPath "*.cs") -Recurse -File -ErrorAction Ignore
            $pdbFiles = Get-ChildItem -Path (Join-Path -Path $debugPath -ChildPath "*.pdb") -Recurse -File -ErrorAction Ignore
            $csFiles | should not benullorempty
            $pdbFiles | should not benullorempty
        }

        It "Compiles console server with minimum parameters" {
            Invoke-Command -Session $s -ScriptBlock { Add-PSSwaggerLiveTestServerType -BootstrapConsent }
        }

        It "Compiles console server with custom output directory and name" {
            $customOutputDir = Join-Path -Path $PSScriptRoot -ChildPath 'mybinserver' | Join-Path -ChildPath 'fullclr'
            $customFileName = 'Server.exe'
            $expectedOutputPath = Join-Path -Path $customOutputDir -ChildPath $customFileName
            if (Test-Path -Path $expectedOutputPath)
            {
                Remove-Item -Path $expectedOutputPath
            }
            
            Invoke-Command -Session $s -ScriptBlock { param($customOutputDir, $customFileName) Add-PSSwaggerLiveTestLibType -BootstrapConsent -OutputDirectory $customOutputDir -SaveAssembly;Add-PSSwaggerLiveTestServerType -BootstrapConsent -OutputDirectory $customOutputDir -OutputFileName $customFileName -SaveAssembly } -Args $customOutputDir,$customFileName
            Get-Item -Path $expectedOutputPath -ErrorAction Ignore | should not benullorempty
        }

        It "Compiles console server with debug symbols" {
            $expectedOutputPath = Invoke-Command -Session $s -ScriptBlock {
                $testModule = Get-Module PSSwagger.LiveTestFramework
                Join-Path -Path $testModule.ModuleBase -ChildPath 'bin' | Join-Path -ChildPath 'fullclr' | Join-Path -ChildPath 'PSSwagger.LTF.ConsoleServer.exe'
            }
            $debugPath = Join-Path -Path $PSScriptRoot -ChildPath 'debug'
            if (Test-Path -Path $expectedOutputPath)
            {
                Remove-Item -Path $expectedOutputPath
            }
            if (Test-Path -Path $debugPath)
            {
                Remove-Item -Path $debugPath -Recurse
            }

            Invoke-Command -Session $s -ScriptBlock { param($debugPath) Add-PSSwaggerLiveTestServerType -BootstrapConsent -DebugSymbolDirectory $debugPath -SaveAssembly } -Args $debugPath
            Get-Item -Path $expectedOutputPath -ErrorAction Ignore | should not benullorempty
            $csFiles = Get-ChildItem -Path (Join-Path -Path $debugPath -ChildPath "*.cs") -Recurse -File -ErrorAction Ignore
            $pdbFiles = Get-ChildItem -Path (Join-Path -Path $debugPath -ChildPath "*.pdb") -Recurse -File -ErrorAction Ignore
            $csFiles | should not benullorempty
            $pdbFiles | should not benullorempty
            $csFiles -isnot [System.Array] | should be true
            $pdbFiles -isnot [System.Array] | should be true
        }
    }
}