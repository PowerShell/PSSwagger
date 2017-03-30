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

        It "Module medatata test" {
            $ModuleInfo = Get-Module 'Generated.Basic.Module'
            $ModuleInfo.Description | Should be 'Very basic API for PSSwagger testing.'
            $ModuleInfo.Author | Should be 'support@swagger.io'
            $ModuleInfo.CopyRight | Should be 'Apache 2.0'

            if($PSVersionTable.PSVersion -ge '5.0.0')
            {
                $ModuleInfo.PrivateData.PSData.LicenseUri | Should be 'http://www.apache.org/licenses/LICENSE-2.0.html'
                $ModuleInfo.PrivateData.PSData.ProjectUri | Should be 'http://www.swagger.io/support'
            }
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
            $results = Get-Tag
            $results.Length | should be 2
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "Optional parameter tests" -Tag ScenarioTest {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.Optional.Module" -GeneratedModuleVersion "0.0.2" -TestApiName "OptionalParametersTests" `
                        -TestSpecFileName "OptionalParametersTestsSpec.json" -TestDataFileName "OptionalParametersTestsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.Optional.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "OptionalParametersTests" -TestRoutesFileName "OptionalParametersTestsRoutes.json"
    }

    Context "Optional parameter tests" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.Optional.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.Optional.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.Optional.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Generates cmdlet using optional query parameters (flavor only)" {
            $results = Get-Cupcake -Flavor "chocolate"
            $results.Length | should be 2
        }

        It "Generates cmdlet using optional query parameters (maker only)" {
            $results = Get-Cupcake -Maker "bob"
            $results.Length | should be 2
        }

        It "Generates cmdlet using optional path parameters" {
            Get-CupcakeByMaker -Flavor "chocolate" -Maker "bob"
        }

        It "Sets default value when specified in spec" {
            $results = Get-CupcakeWithDefault -Maker "bob"
            $results.Length | should be 1
        }

        It "Generates datetime parameter with default correctly" {
            $results = Get-Letter -SentDate ([DateTime]::Parse("2017-03-22T13:25:43.511Z"))
            $results.Length | should be 2
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "ParameterTypes tests" {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.ParmTypes.Module" -GeneratedModuleVersion "0.0.2" -TestApiName "ParameterTypes" `
                        -TestSpecFileName "ParameterTypesSpec.json" -TestDataFileName "ParameterTypesData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.ParmTypes.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "ParameterTypes"
    }

    Context "ParameterTypes tests" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.ParmTypes.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.ParmTypes.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.ParmTypes.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Test expected parameter types" {
            $commandInfo = Get-Command Get-Cupcake
            $commandParameters = $commandInfo.Parameters
            $commandParameters.ContainsKey('AgeInYears') | should be $true
            $commandParameters['AgeInYears'].ParameterType | should be "System.Nullable[int]"
            $commandParameters.ContainsKey('Flavor') | should be $true
            $commandParameters['Flavor'].ParameterType | should be "string"
            $commandParameters.ContainsKey('Price') | should be $true
            $commandParameters['Price'].ParameterType | should be "System.Nullable[double]"
            $commandParameters.ContainsKey('MatrixCode') | should be $true
            $commandParameters['MatrixCode'].ParameterType | should be "byte[]"
            $commandParameters.ContainsKey('Password') | should be $true
            $commandParameters['Password'].ParameterType | should be "string"
            $commandParameters.ContainsKey('MatrixIdentity') | should be $true
            $commandParameters['MatrixIdentity'].ParameterType | should be "byte[]"
            $commandParameters.ContainsKey('MadeOn') | should be $true
            $commandParameters['MadeOn'].ParameterType | should be "System.Nullable[DateTime]"
            $commandParameters.ContainsKey('MadeOnDateTime') | should be $true
            $commandParameters['MadeOnDateTime'].ParameterType | should be "System.Nullable[DateTime]"
            $commandParameters.ContainsKey('PriceInEuros') | should be $true
            $commandParameters['PriceInEuros'].ParameterType | should be "System.Nullable[double]"
            $commandParameters.ContainsKey('AgeInDays') | should be $true
            $commandParameters['AgeInDays'].ParameterType | should be "System.Nullable[int]" # AutoRest issue - why is this Int32?
            $commandParameters.ContainsKey('Poisoned') | should be $true
            $commandParameters['Poisoned'].ParameterType | should be "switch"

            $commandParameters.ContainsKey('Enumparameter') | should be $true
            $commandParameters['Enumparameter'].ParameterType | should be "string"
            $ValidateSetAttribute = $commandParameters['Enumparameter'].Attributes | Where-Object {"$($_.GetType())" -eq 'ValidateSet'}
            $ValidateSetAttribute.ValidValues -contains "resourceType eq 'Test.Namespace/ServiceNameA'" | should be $true
            $ValidateSetAttribute.ValidValues -contains "resourceType eq 'Test.Namespace/ServiceNameZ'" | should be $true
            $ValidateSetAttribute.ValidValues -contains "OtherValidValue" | should be $true
        }

        It "Test default parameter values" {
            $results = Get-Cupcake
            $results.Length | should be 1
        }

        It "Test non-default parameter values" {
            $aByte = [System.Text.Encoding]::UTF8.GetBytes("a")
            $testBytes = [System.Text.Encoding]::UTF8.GetBytes("test")
            $results = Get-Cupcake -AgeInYears 2 -AgeInDays 730 -Flavor "chocolate" -Price 15.95 -PriceInEuros 14.75 -MatrixIdentity $aByte -MatrixCode $testBytes -MadeOn ([DateTime]::Parse("2017-03-23")) -MadeOnDateTime ([DateTime]::Parse("2017-03-23T13:25:43.511Z")) -Password "test2" -Poisoned
            $results.Length | should be 2
        }

        It "Test OData parameters" {
            Get-Cupcake -Filter "filter" -Expand "expand" -Select "select"
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}