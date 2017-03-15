Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1")
Describe "Basic API" -Tag ScenarioTest {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.Basic.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "PsSwaggerTestBasic" `
                        -TestSpecFileName "PsSwaggerTestBasicSpec.json" -TestDataFileName "PsSwaggerTestBasicData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.Basic.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "PsSwaggerTestBasic" -TestRoutesFileName "PsSwaggerTestBasicRoutes.json"
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
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "All Operations: Basic" -Tag ScenarioTest {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.TypesTest.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "OperationTypes" `
                        -TestSpecFileName "OperationTypesSpec.json" -TestDataFileName "OperationTypesData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.TypesTest.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "OperationTypes" -TestMiddlewareFileNames "OperationTypesMiddleware.js" -TestRoutesFileName "OperationTypesRoutes.json"
    }

    Context "All Operations: Basic tests" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.TypesTest.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.TypesTest.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.TypesTest.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Verify create operation" {
            $id = [guid]::NewGuid().Guid | out-string
            $flavor = 'strawberry'
            $result = New-Cupcake -Id $id -Details (New-CupcakeObject -Id $id -Flavor $flavor)
            $result -ne $null | should be $true
            $result.Id | should be $id
            $result.Flavor | should be $flavor
        }

        It "Verify update operation" {
            $id = '1'
            $flavor = 'strawberry'
            $result = Set-Cupcake -Id $id -Details (New-CupcakeObject -Id $id -Flavor $flavor)
            $result -ne $null | should be $true
            $result.Id | should be $id
            $result.Flavor | should be $flavor
        }

        It "Verify get operation" {
            $id = '2'
            $result = Get-Cupcake -Id $id
            $result -ne $null | should be $true
            $result.Id | should be $id
            $result.Flavor | should be 'vanilla'
        }

        It "Verify delete operation" {
            $id = [guid]::NewGuid().Guid | out-string
            $flavor = 'strawberry'
            New-Cupcake -Id $id -Details (New-CupcakeObject -Id $id -Flavor $flavor)
            { Get-Cupcake -Id $id } | should not throw 'NotFound'
            Remove-Cupcake -Id $id
            { Get-Cupcake -Id $id } | should throw 'NotFound'
        }

        It "Verify list operation" {
            $results = Get-Cupcake
            $results.Count -gt 1 | should be $true
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "Get/List tests" -Tag ScenarioTest {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.GetList.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "GetListTests" `
                        -TestSpecFileName "GetListTestsSpec.json" -TestDataFileName "GetListTestsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.GetList.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "GetListTests" -TestRoutesFileName "GetListTestsRoutes.json"
    }

    Context "Get/List tests" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.GetList.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.GetList.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.GetList.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Get has subset of List parameters, Get should be default" {
            (Get-Command Get-Cat).DefaultParameterSet | should be 'Cat_Get'
        }

        It "List and Get are unique parameter sets, but List is chosen as the default" {
            (Get-Command Get-Dog).DefaultParameterSet | should be 'Dog_List'
        }

        It "List has no parameters and no corresponding Get" {
            $results = Get-Tags
            $results.Length | should be 2
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}