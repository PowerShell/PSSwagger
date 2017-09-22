#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################
$script:EnableTracer = $true
Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1")
Describe "Basic API" -Tag ScenarioTest {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.Basic.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "PsSwaggerTestBasic" `
                        -TestSpecFileName "PsSwaggerTestBasicSpec.json" -TestDataFileName "PsSwaggerTestBasicData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.Basic.Module")
        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "PsSwaggerTestBasic" -TestRoutesFileName "PsSwaggerTestBasicRoutes.json" -Verbose
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "Basic API tests" {
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
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.TypesTest.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "OperationTypes" `
                        -TestSpecFileName "OperationTypesSpec.json" -TestDataFileName "OperationTypesData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.TypesTest.Module")
        
        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "OperationTypes" -TestMiddlewareFileNames "OperationTypesMiddleware.js" -TestRoutesFileName "OperationTypesRoutes.json"
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "All Operations: Basic tests" {
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
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.GetList.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "GetListTests" `
                        -TestSpecFileName "GetListTestsSpec.json" -TestDataFileName "GetListTestsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.GetList.Module")

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "GetListTests" -TestRoutesFileName "GetListTestsRoutes.json"
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "Get/List tests" {
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
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.Optional.Module" -GeneratedModuleVersion "0.0.2" -TestApiName "OptionalParametersTests" `
                        -TestSpecFileName "OptionalParametersTestsSpec.json" -TestDataFileName "OptionalParametersTestsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.Optional.Module")
        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "OptionalParametersTests" -TestRoutesFileName "OptionalParametersTestsRoutes.json"
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "Optional parameter tests" {
        It "Generates cmdlet using optional query parameters (flavor only)" {
            $results = Get-Cupcake -Flavor "chocolate"
            $results.Length | should be 2
        }

        It "Generates cmdlet using optional query parameters (maker only)" {
            $results = Get-Cupcake -Maker "bob"
            $results.Length | should be 2
        }

        It "Generates cmdlet using optional query parameters (flavor and maker)" {
            $results = Get-Cupcake -Flavor "chocolate" -Maker "bob"
            $results.Length | should be 1
        }

        It "Generates cmdlet using optional path parameters" {
            $results = Get-CupcakeByMaker -Flavor "chocolate" -Maker "bob"
            $results.Length | should be 1
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

Describe "ParameterTypes tests" -Tag @('ParameterTypes','ScenarioTest') {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.ParamTypes.Module" -GeneratedModuleVersion "0.0.2" -TestApiName "ParameterTypes" `
                        -TestSpecFileName "ParameterTypesSpec.json" -TestDataFileName "ParameterTypesData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.ParamTypes.Module")

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "ParameterTypes"
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "ParameterTypes tests" {
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
            $results = Get-Dinosaur -TestGlobalParameter "test" -SubscriptionId "test" -ApiVersion "test"
            $results.Length | should be 1
        }

        It "Test dummy definition references" {
            $ModuleName = 'Generated.ParamTypes.Module'
            $ev = $null
            $CommandList = Get-Command -Module $ModuleName -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $CommandList.Name -contains 'Get-OpWithDummyRef' | Should be $True

            $commandsSyntax = Get-Command -Module $ModuleName -Name 'Get-OpWithDummyRef' -Syntax -ErrorVariable ev
            $ev | Should BeNullOrEmpty

            $command = Get-Command -Name 'Get-OpWithDummyRef' -Module $ModuleName
            $command.OutputType | Should BeNullOrEmpty
            $command.Parameters.ContainsKey('Parameters') | Should Be $True
            $command.Parameters.Parameters.ParameterType.Name | Should be 'DefWithDummyRef'

            $command2 = Get-Command -Name 'New-DefWithDummyRefObject' -Module $ModuleName
            $command2.Parameters.ContainsKey('Definition') | Should Be $True
            $command2.Parameters.Definition.ParameterType.Name | Should be 'object'
        }

        It "Test CSharp reserved keywords as definition or type names" {
            $ModuleName = 'Generated.ParamTypes.Module'
            $ev = $null
            $CommandList = Get-Command -Module $ModuleName -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $CommandNames = @('New-NamespaceModelObject', 'New-NamespaceListObject', 'Get-PathWithReservedKeywordType')

            $CommandNames | ForEach-Object {
                $CommandList.Name -contains $_ | Should be $True
            }

            $commandsSyntax = Get-Command -Module $ModuleName -Name $CommandNames -Syntax -ErrorVariable ev
            $ev | Should BeNullOrEmpty

            $command = Get-Command -Name 'Get-PathWithReservedKeywordType' -Module $ModuleName
            $command.OutputType[0].Type.Name | Should Be 'NamespaceModel'            
            $command.Parameters.ContainsKey('Parameters') | Should Be $True
            $command.Parameters.Parameters.ParameterType.Name | Should be 'NamespaceList'
            $command.Parameters.ContainsKey('ParameterWithReservedKeywordType') | Should Be $True
            $command.Parameters.ParameterWithReservedKeywordType.ParameterType.Name | Should be 'NamespaceModel'

            $command2 = Get-Command -Name 'New-NamespaceModelObject' -Module $ModuleName
            $command2.Parameters.ContainsKey('ProvisioningState') | Should Be $True
            $command2.Parameters.ProvisioningState.ParameterType.Name | Should be 'EnumModel'

            $command3 = Get-Command -Name 'New-NamespaceListObject' -Module $ModuleName
            $command3.Parameters.ContainsKey('Value') | Should Be $True
            $command3.Parameters.Value.ParameterType.Name | Should be 'NamespaceModel[]'
        }

        It "Test Definition commands 'New-<NestedDefinition>Object' for nested definitions" {
            $ModuleName = 'Generated.ParamTypes.Module'
            $ev = $null
            $CommandList = Get-Command -Module $ModuleName -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            
            $CommandNames = @('New-FieldDefinitionObject',
                              'New-NamespaceNestedTypeObject',
                              'New-KeyCredentialObject')
            $CommandNames | ForEach-Object {
                $CommandList.Name -CContains $_ | Should be $True
            }
        }

        It "Test 'Synopsis' and 'Description' help contents of generated commands" {
            $HelpInfo1 = Get-Help -Name 'Get-Cupcake'
            $HelpInfo1.Description.Text | Should BeExactly 'Make a cupcake or update an existing one.'
            $HelpInfo1.Synopsis | Should BeExactly 'List all cupcakes matching parameters'

            $HelpInfo2 = Get-Help -Name 'New-DefWithDummyRefObject'
            $ExpectedText = 'The workflow properties.'
            $HelpInfo2.Description.Text | Should BeExactly $ExpectedText
            $HelpInfo2.Synopsis | Should BeExactly $ExpectedText
        }

        It 'Test parameter types with array of items in AdditionalProperties json schema' {
            $ModuleName = 'Generated.ParamTypes.Module'
            $ev = $null
            $null = Get-Command -Module $ModuleName -Syntax -ErrorVariable ev
            $ev | Should BeNullOrEmpty

            $OperationCommandInfo = Get-Command -name Get-EffectiveNetworkSecurityGroup -Module $ModuleName
            $OperationCommandInfo.Parameters.OperationTagMap.ParameterType.ToString() | Should BeExactly 'System.Collections.Generic.IDictionary`2[System.String,System.Collections.Generic.IList`1[System.String]]'
            
            $NewObjectCommandInfo = Get-Command -Name New-EffectiveNetworkSecurityGroupObject -Module $ModuleName
            $NewObjectCommandInfo.Parameters.TagMap.ParameterType.ToString() | Should BeExactly 'System.Collections.Generic.Dictionary`2[System.String,System.Collections.Generic.List`1[System.String]]'
        }

        It 'Test parameter types with references to enum definition type' {
            $ModuleName = 'Generated.ParamTypes.Module'

            # Swagger operation command with parameter type reference to enum definition type
            $OperationCommandInfo = Get-Command -Name Get-PathWithEnumDefinitionType -Module $ModuleName

            $OperationCommandInfo.Parameters.PolicyNameEnumParameter.ParameterType.ToString() | Should BeExactly 'System.String'
            @('AppGwSslPolicy20150501', 'AppGwSslPolicy20170401','AppGwSslPolicy20170401S') | ForEach-Object {
                $OperationCommandInfo.Parameters.PolicyNameEnumParameter.Attributes.ValidValues -contains $_ | Should Be $true
            }

            # Swagger definition command with parameter type reference to enum definition type
            $NewObjectCommandInfo = Get-Command -Name New-ApplicationGatewaySslPolicyObject -Module $ModuleName

            $NewObjectCommandInfo.Parameters.PolicyType.ParameterType.ToString() | Should BeExactly 'System.String'
            @('Predefined','Custom') | ForEach-Object {
                $NewObjectCommandInfo.Parameters.PolicyType.Attributes.ValidValues -contains $_ | Should Be $true
            }

            $NewObjectCommandInfo.Parameters.DisabledSslProtocols.ParameterType.ToString() | Should BeExactly 'System.String[]'
            @('TLSv1_0','TLSv1_1', 'TLSv1_2') | ForEach-Object {
                $NewObjectCommandInfo.Parameters.DisabledSslProtocols.Attributes.ValidValues -contains $_ | Should Be $true
            }

            $NewObjectCommandInfo.Parameters.PolicyName.ParameterType.ToString() | Should BeExactly 'System.String'
            @('AppGwSslPolicy20150501', 'AppGwSslPolicy20170401','AppGwSslPolicy20170401S') | ForEach-Object {
                $NewObjectCommandInfo.Parameters.PolicyName.Attributes.ValidValues -contains $_ | Should Be $true
            }

            $NewObjectCommandInfo.Parameters.MinProtocolVersion.ParameterType.ToString() | Should BeExactly 'System.String'
            @('TLSv1_0','TLSv1_1', 'TLSv1_2') | ForEach-Object {
                $NewObjectCommandInfo.Parameters.MinProtocolVersion.Attributes.ValidValues -contains $_ | Should Be $true
            }
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }
}

Describe "AzureExtensions" {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.AzExt.Module" -GeneratedModuleVersion "1.3.3.7" -TestApiName "AzureExtensions" `
                        -TestSpecFileName "AzureExtensionsSpec.json" -TestDataFileName "AzureExtensionsData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.AzExt.Module")
        
        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AzureExtensions" -TestRoutesFileName "AzureExtensionsRoutes.json"
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "AzureExtensions" {
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
            $results = Group-TestsNoHyphen -Parm "test"
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

        It "Test x-ms-client-name for definition parameters" {
            $cmdInfo = Get-Command New-VirtualMachineObject -ErrorVariable ev
            $ev | Should BeNullOrEmpty
            $cmdInfo.Parameters.ContainsKey('ClientNameForSku') | should be $true
        }

        It "'New-<Definition>Object' should not be generated for definitions used as x-ms-client-flatten" {
            $cmdInfo = Get-Command New-CheckNameAvailabilityInputObject -ErrorVariable ev -ErrorAction SilentlyContinue
            $cmdInfo = Should BeNullOrEmpty
            $ev.FullyQualifiedErrorId | Should Be 'CommandNotFoundException,Microsoft.PowerShell.Commands.GetCommandCommand'
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
            if (Test-Path (Join-Path $Path $ModuleName)) {
                Remove-Item (Join-Path $Path $ModuleName) -Recurse -Force
            }

            Import-Module $PsSwaggerPath -Force
            if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
                & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -command "& {`$env:PSModulePath=`$env:PSModulePath_Backup;
                    Import-Module (Join-Path `"$PsSwaggerPath`" `"PSSwagger.psd1`") -Force -ArgumentList `$true;
                    New-PSSwaggerModule -SpecificationPath $SwaggerSpecPath -Name $ModuleName -UseAzureCsharpGenerator -Path $Path -NoAssembly -Verbose -ConfirmBootstrap;
                }"
            } else {
                New-PSSwaggerModule -SpecificationPath $SwaggerSpecPath -Name $ModuleName -UseAzureCsharpGenerator -Path $Path -NoAssembly -Verbose -ConfirmBootstrap
            }
        
            $ModulePath = Join-Path -Path $Path -ChildPath $ModuleName
            # Destroy the full and core CLR requirements so that AzureRM modules aren't required
            # For now, composite swagger specs don't work without the -UseAzureCsharpGenerator flag because of AutoRest naming inconsistency
            "" | Out-File -FilePath (Join-Path -Path $ModulePath -ChildPath "0.0.1" | Join-Path -ChildPath "Test-CoreRequirements.ps1")
            "" | Out-File -FilePath (Join-Path -Path $ModulePath -ChildPath "0.0.1" | Join-Path -ChildPath "Test-FullRequirements.ps1")

            Get-Module -ListAvailable -Name $ModulePath | Should BeOfType 'System.Management.Automation.PSModuleInfo'

            # Import generated module
            Write-Verbose "Importing $ModuleName module"
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

Describe "AllOfDefinition" -Tag @('AllOf','ScenarioTest')  {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.AllOfDefinition.Module" -TestApiName "AllOfDefinition" `
                        -TestSpecFileName "AllOfDefinitionSpec.json"  `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
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

Describe "AuthTests" -Tag @('Auth','ScenarioTest') {
    BeforeAll {
        # Generate all auth modules
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.BasicAuthTest.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "AuthTests" `
                        -TestSpecFileName "BasicAuthSpec.json" -TestDataFileName "AuthTestData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot
         Initialize-Test -GeneratedModuleName "Generated.BasicAuthTestNoChallenge.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "AuthTests" `
                        -TestSpecFileName "BasicAuthSpecNoChallenge.json" -TestDataFileName "AuthTestData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot
        Initialize-Test -GeneratedModuleName "Generated.ApiKeyHeaderTest.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "AuthTests" `
                        -TestSpecFileName "ApiKeyHeaderSpec.json" -TestDataFileName "AuthTestData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot
        Initialize-Test -GeneratedModuleName "Generated.ApiKeyQueryTest.Module" -GeneratedModuleVersion "0.0.1" -TestApiName "AuthTests" `
                        -TestSpecFileName "ApiKeyQuerySpec.json" -TestDataFileName "AuthTestData.json" `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot
        
        # Import generated modules
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.BasicAuthTest.Module")
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.BasicAuthTestNoChallenge.Module")
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.ApiKeyHeaderTest.Module") -Prefix "ApiKeyHeader"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.ApiKeyQueryTest.Module") -Prefix "ApiKeyQuery"

        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "Basic Authentication" {
        It "Succeeds with correct credentials" {
            # Generate credential
            $username = "username"
            $password = ConvertTo-SecureString "password" -AsPlainText -Force
            $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

            # Run test
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\BasicAuth.js" # Contains function to verify a hardcoded basic auth header
                Get-Response -Credential $creds -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Succeeds with correct credentials and no challenge" {
            # Generate credential
            $username = "username"
            $password = ConvertTo-SecureString "passwordAlt" -AsPlainText -Force
            $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

            # Run test
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddlewareNoChallenge.js' `
                                              -CustomServerParameters "--auth .\BasicAuthAltCreds.js" # Contains function to verify a hardcoded basic auth header
                Get-ResponseUnchallenged -Credential $creds -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Fails with incorrect username" {
            # Generate credential
            $username = "username1"
            $password = ConvertTo-SecureString "password" -AsPlainText -Force
            $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

            # Run test
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\BasicAuth.js" # Contains function to verify a hardcoded basic auth header
                { Get-Response -Credential $creds -Property "test" } | should throw 'Unauthorized'
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Fails with incorrect password" {
            # Generate credential
            $username = "username"
            $password = ConvertTo-SecureString "password1" -AsPlainText -Force
            $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

            # Run test
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\BasicAuth.js" # Contains function to verify a hardcoded basic auth header
                { Get-Response -Credential $creds -Property "test" } | should throw 'Unauthorized'
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Allows overriding security requirement at operation level" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\ApiKeyWithQuery.js" # Contains function to verify a hardcoded API key in the query
                Get-ResponseWithApiKey -APIKey "abc123" -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Allows clearing security requirement at operation level" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js'
                Get-ResponseNoAuth -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }
    }

    Context "API key with header" {
        It "Succeeds with key" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\ApiKeyWithHeader.js" # Contains function to verify a hardcoded API key in the header
                Get-ApiKeyHeaderResponse -APIKey "abc123" -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Fails with incorrect key" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\ApiKeyWithHeader.js" # Contains function to verify a hardcoded API key in the header
                { Get-ApiKeyHeaderResponse -APIKey "abc12345" -Property "test" } | should throw 'Unauthorized'
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }
    }

    Context "API key with query" {
        It "Succeeds with key" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\ApiKeyWithQuery.js" # Contains function to verify a hardcoded API key in the query
                Get-ApiKeyQueryResponse -APIKey "abc123" -Property "test"
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }

        It "Fails with incorrect key" {
            try {
                $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName "AuthTests" -TestMiddlewareFileNames 'AuthTestMiddleware.js' `
                                              -CustomServerParameters "--auth .\ApiKeyWithQuery.js" # Contains function to verify a hardcoded API key in the query
                { Get-ApiKeyQueryResponse -APIKey "abc12345" -Property "test" } | should throw 'Unauthorized'
            }
            finally {
                Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
            }
        }
    }
}

Describe "PSMetadataTests" -Tag @('PSMetadata','ScenarioTest')  {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger" | Join-Path -ChildPath "PSSwaggerUtility" | `
                       Join-Path -ChildPath "PSSwaggerUtility.psd1") -Force
        Initialize-Test -GeneratedModuleName "Generated.PSMetadataTest.Module" -TestApiName "psmetadatatest" `
                        -TestSpecFileName "PsMetadataModuleTest.json"  `
                        -PsSwaggerPath (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | `
                       Join-Path -ChildPath "Generated.PSMetadataTest.Module")
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            {
                Initialize-PSSwaggerDependencies -AcceptBootstrap
                Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
                [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
                [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
            }
        }
    }

    Context "PSMetadataTest" {
        It "Override cmdlet name" {
            Get-Command Get-Cupcake -Module Generated.PSMetadataTest.Module -ErrorAction Ignore | should BeNullOrEmpty
            Get-Command List-Cupcakes -Module Generated.PSMetadataTest.Module | should not BeNullOrEmpty
        }
    }
}

Describe "Header scenario tests" -Tag @('Header','ScenarioTest')  {
    BeforeAll {
        $PsSwaggerPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "PSSwagger"
        Import-Module $PsSwaggerPath -Force

        $SwaggerSpecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Data' | Join-Path -ChildPath 'ParameterTypes' | Join-Path -ChildPath 'ParameterTypesSpec.json'
        $GeneratedPath = Join-Path -Path $PSScriptRoot -ChildPath 'Generated'
        $ModuleName = 'HeaderScenarioTestModule'
        $GeneratedModuleBase = Join-Path -Path $GeneratedPath -ChildPath $ModuleName
        if (Test-Path -Path $GeneratedModuleBase -PathType Container) {
            Remove-Item -Path $GeneratedModuleBase -Recurse -Force
        }
    }
    
    It "Validate custom header content in the PSSwagger generated files" {
        $ModuleVersion = '1.1.1.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion
        $Header = '__Custom_HEADER_Content__'
        if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
            & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\PowerShell.exe" -command "& {`$env:PSModulePath=`$env:PSModulePath_Backup;
                Import-Module '$PsSwaggerPath' -Force -ArgumentList `$true;
                New-PSSwaggerModule -SpecificationPath '$SwaggerSpecPath' -Name $ModuleName -Version '$ModuleVersion' -UseAzureCsharpGenerator -Path '$GeneratedPath' -NoAssembly -Verbose -ConfirmBootstrap -Header '$Header';
            }"
        } else {
            New-PSSwaggerModule -SpecificationPath $SwaggerSpecPath -Name $ModuleName -Version $ModuleVersion -UseAzureCsharpGenerator -Path $GeneratedPath -NoAssembly -Verbose -ConfirmBootstrap -Header $Header
        }

        Test-Path -Path $GeneratedModuleVersionPath -PathType Container | Should Be $true
        $FileList = Get-ChildItem -Path $GeneratedModuleVersionPath -File
        $GeneratedPowerShellCommandsPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath 'Generated.PowerShell.Commands'
        $FileList += Get-ChildItem -Path $GeneratedPowerShellCommandsPath -File -Recurse
        $FileList | ForEach-Object {
            (Get-Content -Path $_.FullName) -contains $Header | Should Be $true
        }
    }

    It "Validate header comment from x-ms-code-generation-settings in the PSSwagger generated files" {
        $ModuleVersion = '2.2.2.2'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion
        if((Get-Variable -Name PSEdition -ErrorAction Ignore) -and ('Core' -eq $PSEdition)) {
            & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\PowerShell.exe" -command "& {`$env:PSModulePath=`$env:PSModulePath_Backup;
                Import-Module '$PsSwaggerPath' -Force -ArgumentList `$true;
                New-PSSwaggerModule -SpecificationPath '$SwaggerSpecPath' -Name $ModuleName -Version '$ModuleVersion' -UseAzureCsharpGenerator -Path '$GeneratedPath' -NoAssembly -Verbose -ConfirmBootstrap;
            }"
        } else {
            New-PSSwaggerModule -SpecificationPath $SwaggerSpecPath -Name $ModuleName -Version $ModuleVersion -UseAzureCsharpGenerator -Path $GeneratedPath -NoAssembly -Verbose -ConfirmBootstrap
        }
        
        Test-Path -Path $GeneratedModuleVersionPath -PathType Container | Should Be $true
        $ExpectedHeaderContent = 'Header content from swagger spec'        
        $FileList = Get-ChildItem -Path $GeneratedModuleVersionPath -File
        $GeneratedPowerShellCommandsPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath 'Generated.PowerShell.Commands'
        $FileList += Get-ChildItem -Path $GeneratedPowerShellCommandsPath -File -Recurse
        $FileList | ForEach-Object {
            (Get-Content -Path $_.FullName) -contains $ExpectedHeaderContent | Should Be $true
        }
    }
}

Describe "Pre-compiled SDK Assmebly scenario tests" -Tag @('SDKAssembly','ScenarioTest')  {    
    BeforeAll {
        $PsSwaggerPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "PSSwagger"
        Import-Module $PsSwaggerPath -Force
        $SwaggerSpecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Data' | Join-Path -ChildPath 'ParameterTypes' | Join-Path -ChildPath 'ParameterTypesSpec.json'
        $GeneratedPath = Join-Path -Path $PSScriptRoot -ChildPath 'Generated'
        $ModuleName = 'GeneratedModuleForSdkAssemblyScenario'
        $GeneratedModuleBase = Join-Path -Path $GeneratedPath -ChildPath $ModuleName
        if (Test-Path -Path $GeneratedModuleBase -PathType Container) {
            Remove-Item -Path $GeneratedModuleBase -Recurse -Force
        }

        # Generating the first version, so that PSSwagger generated the SDK Assembly, 
        # later this assembly will be used for testing the precompiled SDK assembly scenarios.
        $ModuleVersion = '1.1.1.1'
        $params = @{
            SpecificationPath       = $SwaggerSpecPath
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            ConfirmBootstrap        = $true
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $params -IncludeAssembly

        $GeneratedModuleRefPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion | Join-Path -ChildPath ref
        $GeneratedModuleFullClrPath = Join-Path -Path $GeneratedModuleRefPath -ChildPath fullclr
        $NameSpace = "Microsoft.PowerShell.$ModuleName.v$("$ModuleVersion" -replace '\.','')"
        $ClientTypeName = 'ParameterTypesSpec'
        $AssemblyName = "$NameSpace.dll"
        Test-Path -Path $GeneratedModuleFullClrPath -PathType Container | Should Be $true
    }

    It 'Validate module generation using pre-compiled SDK assembly and full client type name' {
        $ModuleVersion = '2.2.1.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        if (Test-Path -Path $GeneratedModuleVersionPath -PathType Container) {
            Remove-Item -Path $GeneratedModuleVersionPath -Recurse -Force
        }

        $null = New-Item -Path $GeneratedModuleVersionPath -Type Directory -Force
        Copy-Item -Path $GeneratedModuleRefPath -Destination $GeneratedModuleVersionPath -Recurse -Force

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            ClientTypeName          = "$NameSpace.$ClientTypeName"
            ModelsName              = 'Models'
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'

        $ev | Where-Object {$_.PSTypeNames -contains 'System.Management.Automation.ErrorRecord'} | Should BeNullOrEmpty
        
        # Test module manifest
        $CurrentVersionManifestPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath "$ModuleName.psd1"
        Test-ModuleManifest -Path $CurrentVersionManifestPath -ErrorAction SilentlyContinue -ErrorVariable 'ev2' | Should Not BeNullOrEmpty
        $ev2 | Should BeNullOrEmpty
    }

    It 'Validate module generation using pre-compiled SDK assembly without client type name' {
        $ModuleVersion = '1.1.1.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        $ev | Where-Object {$_.PSTypeNames -contains 'System.Management.Automation.ErrorRecord'} | Should BeNullOrEmpty
        
        # Test module manifest
        $CurrentVersionManifestPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath "$ModuleName.psd1"
        Test-ModuleManifest -Path $CurrentVersionManifestPath -ErrorAction SilentlyContinue -ErrorVariable 'ev2' | Should Not BeNullOrEmpty
        $ev2 | Should BeNullOrEmpty
    }

    It 'Validate module generation using pre-compiled SDK assembly with client type name' {
        $ModuleVersion = '1.1.1.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            ClientTypeName          = $ClientTypeName
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        $ev | Where-Object {$_.PSTypeNames -contains 'System.Management.Automation.ErrorRecord'} | Should BeNullOrEmpty
        
        # Test module manifest
        $CurrentVersionManifestPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath "$ModuleName.psd1"
        Test-ModuleManifest -Path $CurrentVersionManifestPath -ErrorAction SilentlyContinue -ErrorVariable 'ev2' | Should Not BeNullOrEmpty
        $ev2 | Should BeNullOrEmpty
    }

    It 'Validate module generation of pre-compiled SDK assembly scenario with incorrect assembly file name' {
        $ModuleVersion = '1.1.1.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = "IncorrectAssemblyName.dll"
            ClientTypeName          = $ClientTypeName
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        (Remove-TestErrorId -FullyQualifiedErrorId $ev.FullyQualifiedErrorId) | Should Be 'AssemblyNotFound,New-PSSwaggerModule'
    }

    It 'Should fail when client type name is not found in pre-compiled SDK assembly scenario' {
        $ModuleVersion = '3.3.3.0'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        if (Test-Path -Path $GeneratedModuleVersionPath -PathType Container) {
            Remove-Item -Path $GeneratedModuleVersionPath -Recurse -Force
        }

        $CurrentVersionRefPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath ref
        $null = New-Item -Path $CurrentVersionRefPath -Type Directory -Force
        Copy-Item -Path $GeneratedModuleFullClrPath -Destination $CurrentVersionRefPath -Recurse -Force

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            ClientTypeName          = $ClientTypeName
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        (Remove-TestErrorId -FullyQualifiedErrorId $ev.FullyQualifiedErrorId) | Should Be 'UnableToExtractDetailsFromSdkAssembly,Update-PathFunctionDetails'
    }

    It 'Should fail when incorrect namespace in client type name is specified in pre-compiled SDK assembly scenario' {
        $ModuleVersion = '3.3.3.1'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        if (Test-Path -Path $GeneratedModuleVersionPath -PathType Container) {
            Remove-Item -Path $GeneratedModuleVersionPath -Recurse -Force
        }

        $CurrentVersionRefPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath ref
        $null = New-Item -Path $CurrentVersionRefPath -Type Directory -Force
        Copy-Item -Path $GeneratedModuleFullClrPath -Destination $CurrentVersionRefPath -Recurse -Force

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            ClientTypeName          = "Incorrect.NameSpec.$ClientTypeName"
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        (Remove-TestErrorId -FullyQualifiedErrorId $ev.FullyQualifiedErrorId) | Should Be 'UnableToExtractDetailsFromSdkAssembly,Update-PathFunctionDetails'
    }

    It 'Should fail when incorrect client type name is specified in pre-compiled SDK assembly scenario' {
        $ModuleVersion = '3.3.3.2'
        $GeneratedModuleVersionPath = Join-Path -Path $GeneratedModuleBase -ChildPath $ModuleVersion

        if (Test-Path -Path $GeneratedModuleVersionPath -PathType Container) {
            Remove-Item -Path $GeneratedModuleVersionPath -Recurse -Force
        }

        $CurrentVersionRefPath = Join-Path -Path $GeneratedModuleVersionPath -ChildPath ref
        $null = New-Item -Path $CurrentVersionRefPath -Type Directory -Force
        Copy-Item -Path $GeneratedModuleFullClrPath -Destination $CurrentVersionRefPath -Recurse -Force

        $NewPSSwaggerModule_params = @{
            SpecificationPath       = $SwaggerSpecPath
            AssemblyFileName        = $AssemblyName
            ClientTypeName          = 'IncorrectClientName'
            Name                    = $ModuleName
            Version                 = $ModuleVersion
            UseAzureCsharpGenerator = $true
            Path                    = $GeneratedPath
            Verbose                 = $true
        }
        Invoke-NewPSSwaggerModuleCommand -NewPSSwaggerModuleParameters $NewPSSwaggerModule_params -ErrorVariable 'ev' -ErrorAction 'SilentlyContinue'
        (Remove-TestErrorId -FullyQualifiedErrorId $ev.FullyQualifiedErrorId) | Should Be 'UnableToExtractDetailsFromSdkAssembly,Update-PathFunctionDetails'
    }
}
