Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1")
Describe "Basic API" -Tag ScenarioTest {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.Basic.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "PsSwaggerTestBasic" `
                        -TestSpecFileName "PsSwaggerTestBasicSpec.json" -TestDataFileName "PsSwaggerTestBasicData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot -UseAzureCSharpGenerator

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
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot -UseAzureCSharpGenerator

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

        It "Verify Path level common parameters" {
            @('Get-CupCake2','New-CupCake2','Remove-CupCake2', 'Set-CupCake2') | ForEach-Object {
                $Command = Get-Command $_
                $Command.Parameters.ContainsKey('Id') | Should be $true
            }
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
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot -UseAzureCSharpGenerator

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
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot -UseAzureCSharpGenerator

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
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot -UseAzureCSharpGenerator

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

        It "Test global parameters" {
            $results = Get-Cookie -TestGlobalParameter "test"
            $results.Length | should be 1
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "AzureExtensions" {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.AzExt.Module" -GeneratedModuleVersion "1.3.3.7" -TestApiName "AzureExtensions" `
                        -TestSpecFileName "AzureExtensionsSpec.json" -TestDataFileName "AzureExtensionsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.AzExt.Module")
        
        # Load the test assembly after the generated module, since the generated module is kind enough to load the required dlls for us
        try {
            $null = Add-Type -Path (Join-Path "$PSScriptRoot" "PSSwagger.TestUtilities" | Join-Path -ChildPath "$global:testRunGuid.dll") -PassThru
        } catch {
            throw "$($_.Exception.LoaderExceptions)"
        }

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AzureExtensions" -TestRoutesFileName "AzureExtensionsRoutes.json"
    }

    Context "AzureExtensions" {
        # Mocks
        Mock Get-AzServiceCredential -ModuleName Generated.AzExt.Module {
            return New-Object -TypeName PSSwagger.TestUtilities.TestCredentials
        }

        Mock Get-AzSubscriptionId -ModuleName Generated.AzExt.Module {
            return "Test"
        }

        Mock Get-AzResourceManagerUrl -ModuleName Generated.AzExt.Module {
            return "$($global:testDataSpec.schemes[0])://$($global:testDataSpec.host)"
        }

        It "Test flattened parameters" {
            New-Cupcake -Id "3" -Flavor "strawberry"
            $results = Get-Cupcake
            $results.Count | should be 3
        }

        It "Test multi-level flattened parameters" {
            New-CupcakeBatch -Id "2" -Flavor "strawberry"
            $results = Get-CupcakeBatch
            $results.Count | should be 2
        }

        It "Test basic parameter group" {
            # As long as this makes a proper request, the results don't matter
            $results = Path-GroupTestParameter -Parm "test" -Parm2 "test2"
        }

        It "Test parameter group of mixed local and global" {
            $results = Mixed-GroupTestParameter -Parm "test" -MethodParameter "test2"
        }

        It "Test parameter group with postfix instead of name" {
            $results = Postfix-GroupTest -Parm "test"
        }

        It "Test parameter group with neither postfix nor name" {
            $results = No-GroupTestPostfixTest -Parm "test"
        }

        It "Test parameter group when operation ID has no hyphens" {
            $results = GroupTestsNoHyphen -Parm "test"
        }

        It "Test parameter group with flattened parameters" {
            $results = Flattened-GroupTestParm -Id "1000" -Flavor "chocolate"
        }

        It "Test when multiple parameter groups exist" {
            $results = Multiple-GroupTestGroup -parm "test" -parm2 "test2"
        }

        It "Test long running operation with AsJob" {
            $cmdInfo = Get-Command New-VirtualMachine -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $cmdInfo.Parameters.ContainsKey('AsJob') | should be $true
        }

        It "Test non long running operation with no AsJob" {
            $cmdInfo = Get-Command Get-Cupcake -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $cmdInfo.Parameters.ContainsKey('AsJob') | should be $false
        }

        It "Test x-ms-paths generated cmdlets" {
            $results = Get-CupcakeById -Id 1
            $results.Count | should be 1

            $results = Get-CupcakeByFlavor -Flavor 'vanilla'
            $results.Count | should be 1
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "Composite Swagger Tests" -Tag @('Composite','ScenarioTest') {
    Context "Module generation for composite swagger specs" {
        It "New-PSSwaggerModule with composite swagger spec" {            
            $ModuleName = 'CompositeSwaggerModule'
            $PsSwaggerPath = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger"
            $Path = Join-Path -Path $PSScriptRoot -ChildPath 'Generated'
            $SwaggerSpecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Data' | Join-Path -ChildPath 'CompositeSwaggerTest' | Join-Path -ChildPath 'composite-swagger.json'
            # Module generation part needs to happen in full powershell
            Write-Verbose "Generating $ModuleName module"
            Import-Module $PsSwaggerPath -Force
            New-PSSwaggerModule -SwaggerSpecPath $SwaggerSpecPath -Name $ModuleName -UseAzureCsharpGenerator -Path $Path -NoAssembly -Verbose

            $ModulePath = Join-Path -Path $Path -ChildPath $ModuleName
            Get-Module -ListAvailable -Name $ModulePath | Should BeOfType 'System.Management.Automation.PSModuleInfo'

            # Import generated module
            Write-Verbose "Importing $ModuleName module"
            Import-Module (Join-Path -Path $PsSwaggerPath -ChildPath "Generated.Azure.Common.Helpers") -Force
            $ev = $null
            Import-Module $ModulePath -Force -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            Get-Module -Name $ModuleName | Should BeOfType 'System.Management.Automation.PSModuleInfo'

            $CommandList = Get-Command -Module $ModuleName -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $CommandList.Name -contains 'New-ProductObject' | Should be $True
            $CommandList.Name -contains 'New-Product2Object' | Should be $True
            $commandList.Count | Should be 7

            $commandsSyntax = Get-Command -Module $ModuleName -Syntax -ErrorVariable ev
            $ev | Should BeNullOrEmpty

            # Validate expanded parameter types with referenced definition
            $command = Get-Command -Name New-ProductObject -Module $ModuleName            
            $command.Parameters.IntParamName.ParameterType.Name | Should be 'Int64'
            
            $command.Parameters.Tags.ParameterType.Name | Should be 'string'
            $command.Parameters.StartDate.ParameterType.Name | Should be 'string'
            $command.Parameters.EndDate.ParameterType.Name | Should be 'string'
            $command.Parameters.ContainerUrl.ParameterType.Name | Should be 'uri'
        }
    }
}

Describe "AllOfDefinition" {
    BeforeAll {
        Initialize-Test -GeneratedModuleName "Generated.AllOfDefinition.Module" -TestApiName "AllOfDefinition" `
                        -TestSpecFileName "AllOfDefinitionSpec.json"  `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "Generated.Azure.Common.Helpers" | `
                       Join-Path -ChildPath "Generated.Azure.Common.Helpers.psd1") -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.AllOfDefinition.Module")
    }

    Context "AllOfDefinition" {
        It "Test subclass object creation" {
            $guitar = New-GuitarObject -ISTuned
            Get-Member -InputObject $guitar -Name 'ISTuned' | should be $true
            Get-Member -InputObject $guitar -Name 'Id' | should be $null
            Get-Member -InputObject $guitar -Name 'NumberOfStrings' | should be $true
            $guitar.ISTuned | should be $true
            $guitar.NumberOfStrings | should be $null
        }
    }
}
