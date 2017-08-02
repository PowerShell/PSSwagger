#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Tests
#
#########################################################################################
Describe "Tests for New-PSSwaggerMetadataFile cmdlet" -Tag @('PSMeta', 'ScenarioTest') {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'PSSwagger') -Force
        $TestsDataPath = Join-Path -Path $PSScriptRoot -ChildPath 'data'
        $PSMetaDataTestPath = Join-Path -Path $TestsDataPath -ChildPath 'psmetadatatest'
        $SwaggerSpecPath = Join-Path -Path $PSMetaDataTestPath -ChildPath 'psmetadatatest.json'
        $PSMetaFilePath = Join-Path -Path $PSMetaDataTestPath -ChildPath 'psmetadatatest.psmeta.json'

        if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
            Remove-Item -Path $PSMetaFilePath -Force
        }
        New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath

        $PSMetaJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $PSMetaFilePath) -join [Environment]::NewLine) -ErrorAction Stop
        $SwaggerJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
    }

    Context "Validate generated .psmeta.json file contents" {
        It "Test x-ps-code-generation-settings properties" {
            $PSCodeGenerationSettings = [ordered]@{
                codeGenerator         = 'CSharp'
                nameSpacePrefix       = 'Microsoft.PowerShell.'
                noAssembly            = $false
                powerShellCorePath    = ''
                includeCoreFxAssembly = $false
                testBuild             = $false
                confirmBootstrap      = $false
                path                  = '.'
                symbolPath            = '.'
                serviceType           = ''
                customAuthCommand     = ''
                hostOverrideCommand   = ''
                noAuthChallenge       = ''
            }

            $PSCodeGenerationSettings.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $PSMetaJsonObject.info.'x-ps-code-generation-settings' -Name $_.Name | Should Not BeNullOrEmpty
                $PSMetaJsonObject.info.'x-ps-code-generation-settings'."$($_.Name)" | Should Be $_.Value
            }
        }

        It "Test x-ps-module-info properties" {
            $PSModuleInfo = [ordered]@{
                name                 = 'DocumentDB'
                moduleVersion        = '0.0.1'
                guid                 = 'f43aa500-a891-486b-8088-c55dbedae72a'
                description          = 'Azure DocumentDB Database Service Resource Provider REST API'
                author               = 'support@swagger.io'
                companyName          = ''
                CopyRight            = 'Apache 2.0'
                licenseUri           = 'http://www.apache.org/licenses/LICENSE-2.0.html'
                projectUri           = 'http://www.swagger.io/support'
                helpInfoUri          = ''
                iconUri              = ''
                releaseNotes         = ''
                defaultCommandPrefix = ''
                tags                 = @()
            }

            $PSModuleInfo.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $PSMetaJsonObject.info.'x-ps-module-info' -Name $_.Name | Should Not BeNullOrEmpty
                switch ($_.Name) {
                    'guid' {
                        $guid = New-Object -TypeName 'System.Guid'
                        [guid]::TryParse($PSMetaJsonObject.info.'x-ps-module-info'.guid, [ref]$guid) | Should Be $true
                    }
                    'tags' {$jsonObject.info.'x-ps-module-info'.tags.count | Should Be 0 }
                    Default {$PSMetaJsonObject.info.'x-ps-module-info'."$($_.Name)" | Should Be $_.Value }
                }
            }
        }

        It "Test existence of x-ps-parameter-info property for each global parameters" {
            $SwaggerJsonObject.parameters.PSObject.Properties | ForEach-Object {
                Get-Member -InputObject $PSMetaJsonObject.parameters -Name $_.Name | Should Not BeNullOrEmpty
                Get-Member -InputObject $PSMetaJsonObject.parameters."$($_.Name)" -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            }
        }

        It "Test all properties of x-ps-parameter-info for all global parameters" {
            $SwaggerJsonObject.parameters.PSObject.Properties | ForEach-Object {
                $globalParameterDetails = $_.Value
                $parameterKeyName = $_.Name
                $PSMetaJsonObject.parameters."$parameterKeyName".'x-ps-parameter-info'.Name | Should Be $($globalParameterDetails.Name -replace '-', '')
                $PSMetaJsonObject.parameters."$parameterKeyName".'x-ps-parameter-info'.Description | Should Be $globalParameterDetails.Description
            }
        }

        It "Test existence of 'x-ps-cmdlet-infos' property for all definitions" {
            $SwaggerJsonObject.definitions.PSObject.Properties | ForEach-Object {
                Get-Member -InputObject $PSMetaJsonObject.definitions -Name $_.Name | Should Not BeNullOrEmpty
                Get-Member -InputObject $PSMetaJsonObject.definitions."$($_.Name)" -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
            }
        }

        It "Test all properties of 'x-ps-cmdlet-infos' for a single definition" {
            $DatabaseAccount_x_ps_cmdlet_info = @{
                Name                 = 'New-DatabaseAccountObject'
                Description          = 'A DocumentDB database account.'
                DefaultParameterSet  = "DatabaseAccount"
                GenerateCommand      = $true
                GenerateOutputFormat = $true
            }
            $PSMetaJsonObject.definitions.DatabaseAccount.'x-ps-cmdlet-infos'.Count | Should Be 1
            $DatabaseAccount_x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $PSMetaJsonObject.definitions.DatabaseAccount.'x-ps-cmdlet-infos'[0] -Name $_.Name | Should Not BeNullOrEmpty
                $PSMetaJsonObject.definitions.DatabaseAccount.'x-ps-cmdlet-infos'[0]."$($_.Name)" | Should Be $_.Value
            }
        }

        It "Test 'x-ps-parameter-info' and its properties for all definitions" {
            $SwaggerJsonObject.definitions.PSObject.Properties | ForEach-Object {
                $definitionName = $_.Name
                $_.Value.properties.PSObject.Properties | ForEach-Object {                    
                    $propertyDetails = $_.Value
                    $propertyName = $_.Name
                    if ($propertyDetails -and (Get-Member -InputObject $propertyDetails -Name 'Description')) {
                        $parameterObject = $PSMetaJsonObject.definitions."$definitionName".Properties."$($_.Name)"
                        Get-Member -InputObject $parameterObject -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty

                        Get-Member -InputObject $parameterObject.'x-ps-parameter-info' -Name 'Name' | Should Not BeNullOrEmpty
                        $parameterObject.'x-ps-parameter-info'.Name | Should Be $propertyName

                        Get-Member -InputObject $parameterObject.'x-ps-parameter-info' -Name 'Description' | Should Not BeNullOrEmpty
                        $parameterObject.'x-ps-parameter-info'.Description | Should Be $propertyDetails.Description
                    }
                }
            }
        }

        It "Test 'x-ps-output-format-info' and its properties for all definitions" {
            $SwaggerJsonObject.definitions.PSObject.Properties | ForEach-Object {
                $definitionName = $_.Name
                $_.Value.properties.PSObject.Properties | ForEach-Object {          
                    $propertyDetails = $_.Value
                    if ($propertyDetails -and (Get-Member -InputObject $propertyDetails -Name 'Description')) {
                        $parameterObject = $PSMetaJsonObject.definitions."$definitionName".Properties."$($_.Name)"
                        Get-Member -InputObject $parameterObject -Name 'x-ps-output-format-info' | Should Not BeNullOrEmpty

                        Get-Member -InputObject $parameterObject.'x-ps-output-format-info' -Name 'Include' | Should Not BeNullOrEmpty
                        Get-Member -InputObject $parameterObject.'x-ps-output-format-info' -Name 'Position' | Should Not BeNullOrEmpty
                        Get-Member -InputObject $parameterObject.'x-ps-output-format-info' -Name 'Width' | Should Not BeNullOrEmpty
                    }
                }
            }
        }

        It "Test existence of 'x-ps-cmdlet-infos' property for all paths" {
            $SwaggerJsonObject.paths.PSObject.Properties | ForEach-Object {
                $relativeIndividualEndpoint = $_.Name
                $pathObject = $_.Value
                $pathObject.PSObject.Properties | ForEach-Object {
                    $operationType = $_.Name
                    if ($operationType -ne 'parameters') {
                        Get-Member -InputObject $PSMetaJsonObject.paths."$relativeIndividualEndpoint"."$operationType" -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
                    }
                }
            }
        }

        It "Test existence of 'x-ps-cmdlet-infos' with two elements for CreateAndUpdate operation" {
            $relativeIndividualEndpoint = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}"
            $operationType = 'put'
                        
            $New_x_ps_cmdlet_info = @{
                Name                = 'New-DatabaseAccount'
                Description         = 'Creates or updates an Azure DocumentDB database account.'
                DefaultParameterSet = 'DatabaseAccounts_CreateOrUpdate'
                GenerateCommand     = $true
            }

            $Set_x_ps_cmdlet_info = @{
                Name                = 'Set-DatabaseAccount'
                Description         = 'Creates or updates an Azure DocumentDB database account.'
                DefaultParameterSet = 'DatabaseAccounts_CreateOrUpdate'
                GenerateCommand     = $true
            }
            
            $x_ps_cmdlet_infosObject = $PSMetaJsonObject.paths."$relativeIndividualEndpoint"."$operationType".'x-ps-cmdlet-infos'
            $x_ps_cmdlet_infosObject.Count | Should Be 2

            $New_x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $x_ps_cmdlet_infosObject[0] -Name $_.Name | Should Not BeNullOrEmpty
                $x_ps_cmdlet_infosObject[0]."$($_.Name)" | Should Be $_.Value
            }

            $Set_x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $x_ps_cmdlet_infosObject[1] -Name $_.Name | Should Not BeNullOrEmpty
                $x_ps_cmdlet_infosObject[1]."$($_.Name)" | Should Be $_.Value
            }
        }

        It "Test 'x-ps-cmdlet-infos' for a two swagger operations with same cmdlet name" {

            $operationType = 'get'

            # List operation id from different path
            $list_RelativeIndividualEndpoint = '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}'
            $List_x_ps_cmdlet_info = @{
                Name                = 'Get-DatabaseAccount'
                Description         = 'Retrieves the properties of an existing Azure DocumentDB database account.'
                DefaultParameterSet = 'DatabaseAccounts_List'
                GenerateCommand     = $true
            }
            $x_ps_cmdlet_infosObject = $PSMetaJsonObject.paths."$list_RelativeIndividualEndpoint"."$operationType".'x-ps-cmdlet-infos'
            $x_ps_cmdlet_infosObject.Count | Should Be 1

            $List_x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $x_ps_cmdlet_infosObject[0] -Name $_.Name | Should Not BeNullOrEmpty
                $x_ps_cmdlet_infosObject[0]."$($_.Name)" | Should Be $_.Value
            }

            # Get operation id from different path
            $get_RelativeIndividualEndpoint = '/subscriptions/{subscriptionId}/providers/Microsoft.DocumentDB/databaseAccounts'
            $get_x_ps_cmdlet_info = @{
                Name                = 'Get-DatabaseAccount'
                Description         = 'Lists all the Azure DocumentDB database accounts available under the subscription.'
                DefaultParameterSet = 'DatabaseAccounts_List'
                GenerateCommand     = $true
            }

            $x_ps_cmdlet_infosObject = $PSMetaJsonObject.paths."$get_RelativeIndividualEndpoint"."$operationType".'x-ps-cmdlet-infos'
            $x_ps_cmdlet_infosObject.Count | Should Be 1

            $get_x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $x_ps_cmdlet_infosObject[0] -Name $_.Name | Should Not BeNullOrEmpty
                $x_ps_cmdlet_infosObject[0]."$($_.Name)" | Should Be $_.Value
            }
        }

        It "Test all properties of 'x-ps-parameter-info' for a swagger operation" {
            $operationType = 'get'
            $get_RelativeIndividualEndpoint = '/subscriptions/{subscriptionId}/providers/Microsoft.DocumentDB/databaseAccounts'
            $paramObject = $PSMetaJsonObject.paths."$get_RelativeIndividualEndpoint"."$operationType".parameters.DatabaseAccountsListParameter
            
            Get-Member -InputObject $paramObject -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            $paramObject.'x-ps-parameter-info'.name | Should Be 'DatabaseAccountsListParameter'
            $paramObject.'x-ps-parameter-info'.description | Should Be 'Parameter description.'
        }

        It "Test all properties of 'x-ps-parameter-info' for path common parameters" {
            $operationType = 'get'
            $get_RelativeIndividualEndpoint = '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}'
            $paramObject = $PSMetaJsonObject.paths."$get_RelativeIndividualEndpoint".parameters.EndpointCommonParameter
            
            Get-Member -InputObject $paramObject -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            $paramObject.'x-ps-parameter-info'.name | Should Be 'EndpointCommonParameter'
            $paramObject.'x-ps-parameter-info'.description | Should Be 'Common parameter for all operations of an individual endpoint.'
        }

        It "Test New-PSSwaggerMetadataFile cmdlet with -Force parameter" {
            Test-Path -Path $PSMetaFilePath -PathType Leaf | Should Be $true
            { New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath } | Should Throw
            { New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath -Force } | Should Not Throw
        }

        It "Test New-PSSwaggerMetadataFile cmdlet with -WhatIf parameter" {            
            if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
                Remove-Item -Path $PSMetaFilePath -Force
            }

            { New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath -WhatIf } | Should Not Throw
            Test-Path -Path $PSMetaFilePath -PathType Leaf | Should Be $false
        }

        It "Test New-PSSwaggerMetadataFile cmdlet with ValueFromPipeline functionality" {
            if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
                Remove-Item -Path $PSMetaFilePath -Force
            }

            { $SwaggerSpecPath | New-PSSwaggerMetadataFile } | Should Not Throw
            Test-Path -Path $PSMetaFilePath -PathType Leaf | Should Be $true
        }

        It "Test New-PSSwaggerMetadataFile cmdlet with ValueFromPipelineByPropertyName functionality" {
            if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
                Remove-Item -Path $PSMetaFilePath -Force
            }
            $PSObject = New-Object -TypeName 'PSObject'
            Add-Member -InputObject $PSObject -MemberType NoteProperty -Name SpecificationPath -Value $SwaggerSpecPath
            Add-Member -InputObject $PSObject -MemberType NoteProperty -Name 'SomeOtherProperty' -Value 'SomeValue'

            { $PSObject | New-PSSwaggerMetadataFile } | Should Not Throw
            Test-Path -Path $PSMetaFilePath -PathType Leaf | Should Be $true
        }
    }
}

Describe "Tests for New-PSSwaggerMetadataFile cmdlet with x-ms-paths extension in swagger doc" -Tag @('PSMeta', 'x-ms-paths', 'ScenarioTest') {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -Force
        $PSMetaDataTestPath = Join-Path -Path $PSScriptRoot -ChildPath "data" | Join-Path -ChildPath "AzureExtensions"
        $SwaggerSpecPath = Join-Path -Path $PSMetaDataTestPath -ChildPath "AzureExtensionsSpec.json"
        $PSMetaFilePath = Join-Path -Path $PSMetaDataTestPath -ChildPath "AzureExtensionsSpec.psmeta.json"

        if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
            Remove-Item -Path $PSMetaFilePath -Force
        }
        New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath

        $PSMetaJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $PSMetaFilePath) -join [Environment]::NewLine) -ErrorAction Stop
        $SwaggerJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $SwaggerSpecPath) -join [Environment]::NewLine) -ErrorAction Stop
    }

    Context "Validate generated .psmeta.json file contents" {
        It "Test existence of all paths of x-ms-paths in psmeta file" {
            $SwaggerJsonObject.'x-ms-paths'.PSObject.Properties | ForEach-Object {
                $relativeIndividualEndpoint = $_.Name
                $pathObject = $_.Value
                $pathObject.PSObject.Properties | ForEach-Object {
                    $operationType = $_.Name
                    if ($operationType -ne 'parameters') {
                        Get-Member -InputObject $PSMetaJsonObject.'x-ms-paths'."$relativeIndividualEndpoint"."$operationType" -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
                    }
                }
            }
        }

        It "Test 'x-ps-cmdlet-infos' for a swagger operation in x-ms-paths" {
            $relativeIndividualEndpoint = '/subscriptions/{subscriptionId}/providers/Microsoft.Search/checkNameAvailability'
            $operationType = 'post'
                        
            $x_ps_cmdlet_info = @{
                Name                = 'Test-ServiceNameAvailability'
                Description         = 'Checks whether or not the given Search service name is available for use. Search service names must be globally unique since they are part of the service URI (https://<name>.search.windows.net).'
                DefaultParameterSet = 'Services_CheckNameAvailability'
                GenerateCommand     = $true
            }
            
            $x_ps_cmdlet_infosObject = $PSMetaJsonObject.'x-ms-paths'."$relativeIndividualEndpoint"."$operationType".'x-ps-cmdlet-infos'
            $x_ps_cmdlet_infosObject.Count | Should Be 1

            $x_ps_cmdlet_info.GetEnumerator() | ForEach-Object {
                Get-Member -InputObject $x_ps_cmdlet_infosObject[0] -Name $_.Name | Should Not BeNullOrEmpty
                $x_ps_cmdlet_infosObject[0]."$($_.Name)" | Should Be $_.Value
            }
        }

        It "Test 'x-ps-parameter-info' for a swagger operation in x-ms-paths" {
            $operationType = 'get'
            $get_RelativeIndividualEndpoint = '/cupcakes?flavor={flavor}'
            $paramObject = $PSMetaJsonObject.'x-ms-paths'."$get_RelativeIndividualEndpoint"."$operationType".parameters.flavor
            
            Get-Member -InputObject $paramObject -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            $paramObject.'x-ps-parameter-info'.name | Should Be 'Flavor'
            $paramObject.'x-ps-parameter-info'.description | Should Be 'x-ms-paths test'
        }
    }
}

Describe "Tests for New-PSSwaggerMetadataFile cmdlet with composite swagger document" -Tag @('PSMeta', 'Composite', 'ScenarioTest') {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "PSSwagger") -Force
        $PSMetaDataTestPath = Join-Path -Path $PSScriptRoot -ChildPath "data" | Join-Path -ChildPath "CompositeSwaggerTest"
        $SwaggerSpecPath = Join-Path -Path $PSMetaDataTestPath -ChildPath "composite-swagger.json"
        $PSMetaFilePath = Join-Path -Path $PSMetaDataTestPath -ChildPath "composite-swagger.psmeta.json"

        if (Test-Path -Path $PSMetaFilePath -PathType Leaf) {
            Remove-Item -Path $PSMetaFilePath -Force
        }
        New-PSSwaggerMetadataFile -SpecificationPath $SwaggerSpecPath

        $PSMetaJsonObject = ConvertFrom-Json -InputObject ((Get-Content -Path $PSMetaFilePath) -join [Environment]::NewLine) -ErrorAction Stop
    }

    Context "Validate generated .psmeta.json file contents" {
        It "Test 'x-ps-module-info' for a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.info -Name 'x-ps-module-info' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-code-generation-settings' for a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.info -Name 'x-ps-code-generation-settings' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-cmdlet-info' for two paths from two different specs of a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.paths.'/subscriptions/{subscriptionId}/resource'.get -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.paths.'/subscriptions/{subscriptionId}/resource2?api-version={apiVersion}'.get -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-parameter-info' for two paths from two different specs of a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.paths.'/subscriptions/{subscriptionId}/resource'.put.parameters.subscriptionId -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.paths.'/subscriptions/{subscriptionId}/resource2?api-version={apiVersion}'.put.parameters.subscriptionId -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-cmdlet-info' for two definitions from two different specs of a composite swagger spec" {            
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product' -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product2' -Name 'x-ps-cmdlet-infos' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-parameter-info' for two definitions from two different specs of a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product'.properties.startDate -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product2'.properties.product_id -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-output-format-info' for two definitions from two different specs of a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product'.properties.startDate -Name 'x-ps-output-format-info' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.definitions.'Product2'.properties.product_id -Name 'x-ps-output-format-info' | Should Not BeNullOrEmpty
        }

        It "Test 'x-ps-parameter-info' for two global parameters from two different specs of a composite swagger spec" {
            Get-Member -InputObject $PSMetaJsonObject.parameters.'ApiVersionParameter' -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
            Get-Member -InputObject $PSMetaJsonObject.parameters.'SubscriptionIdParamterer' -Name 'x-ps-parameter-info' | Should Not BeNullOrEmpty
        }
    }
}

Describe "Tests for New-PSSwaggerModule with Swagger spec and its .psmeta.json file" -Tag @('PSMeta', 'Generation', 'ScenarioTest') {
    BeforeAll {
        $PSSwaggerPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "PSSwagger"
        $GeneratedModuleName = 'Generated.TestSwaggerSpecWithPSMetaFile.Module'
        Initialize-Test -GeneratedModuleName $GeneratedModuleName -TestApiName "psmetadatatest" `
                        -TestSpecFileName "TestSwaggerSpecWithPSMetaFile.json"  `
                        -TestDataFileName "TestSwaggerSpecWithPSMetaFileData.json" `
                        -PSSwaggerPath $PSSwaggerPath -TestRootPath $PSScriptRoot

        # Import generated module
        Write-Verbose "Importing modules"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Generated" | Join-Path -ChildPath $GeneratedModuleName) -Force

        $processes = Start-JsonServer -TestRootPath $PSScriptRoot -TestApiName 'psmetadatatest'
        if ($global:PSSwaggerTest_EnableTracing -and $script:EnableTracer) {
            $script:EnableTracer = $false
            Initialize-PSSwaggerDependencies -AcceptBootstrap
            Import-Module "$PSScriptRoot\PSSwaggerTestTracing.psm1"
            [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor((New-PSSwaggerTestClientTracing))
            [Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
        }
    }

    AfterAll {
        Stop-JsonServer -JsonServerProcess $processes.ServerProcess -NodeProcess $processes.NodeProcess
    }

    Context "Validate extended cmdlet name using .psmeta.json" {
        It "Validate extended cmdlet name with .psmeta.json file" {
            Get-Command -Name Get-DatabaseAccount -Module $GeneratedModuleName -ErrorAction Ignore | Should BeNullOrEmpty
            Get-Command -Name Get-PSMetaExtendedDatabaseAccount -Module $GeneratedModuleName | Should not BeNullOrEmpty
        }
    }

    Context "Validate flattening of complex parameter of swagger operation" {
        It "Validate flattening of complex parameter defined at swagger OPERATION level" {
            $CommandName = 'Get-PSMetaExtendedDatabaseAccount'
            Get-Command -ParameterName 'DatabaseAccountsGetParameter' -Name $CommandName -Module $GeneratedModuleName -ErrorAction Ignore | Should BeNullOrEmpty

            @('keyKind', 'RegenerateReason') | ForEach-Object {
                $ExpectedParameterName = $_
                Get-Command -ParameterName $ExpectedParameterName -Name $CommandName -Module $GeneratedModuleName | Where-Object {$_.Parameters.Keys -contains $ExpectedParameterName} | Should Not BeNullOrEmpty
            }
        }

        It "Validate flattening of complex parameter defined at swagger PATH/Endpoint level" {
            @('New-DatabaseAccount','Set-DatabaseAccount','Update-DatabaseAccount','Get-PSMetaExtendedDatabaseAccount') | ForEach-Object {
                $CommandName = $_
                Get-Command -ParameterName 'EndpointLevelQuotaParameter' -Name $CommandName -Module $GeneratedModuleName -ErrorAction Ignore | Should BeNullOrEmpty

                @('CommonDefParam1', 'CommonDefParam2') | ForEach-Object {
                    $ExpectedParameterName = $_
                    Get-Command -ParameterName $ExpectedParameterName -Name $CommandName -Module $GeneratedModuleName | Where-Object {$_.Parameters.Keys -contains $ExpectedParameterName} | Should Not BeNullOrEmpty
                }
            }
        }

        It "Validate flattening of complex parameter defined at swagger '#/parameters/'" {
            @('Get-PSMetaExtendedDatabaseAccount') | ForEach-Object {
                $CommandName = $_
                Get-Command -ParameterName 'QuotaParameters' -Name $CommandName -Module $GeneratedModuleName -ErrorAction Ignore | Should BeNullOrEmpty

                @('CapacityInGB', 'NumberOfStorageAccounts', 'Tags', 'Name', 'Location') | ForEach-Object {
                    $ExpectedParameterName = $_
                    Get-Command -ParameterName $ExpectedParameterName -Name $CommandName -Module $GeneratedModuleName | Where-Object {$_.Parameters.Keys -contains $ExpectedParameterName} | Should Not BeNullOrEmpty
                }
            }
        }

        It "Validate flattening of complex parameter by running the generated command" {
            Get-Command -ParameterName 'FlatCupCakeParameters' -Name 'Get-FlatCupCake' -Module $GeneratedModuleName -ErrorAction Ignore | Should BeNullOrEmpty

            @('AgeInDays', 'AgeInYears', 'Flavor') | ForEach-Object {
                $ExpectedParameterName = $_
                Get-Command -ParameterName $ExpectedParameterName -Name 'Get-FlatCupCake' -Module $GeneratedModuleName | Where-Object {$_.Parameters.Keys -contains $ExpectedParameterName} | Should Not BeNullOrEmpty
            }

            Get-FlatCupCake -AgeInYears 1 -AgeInDays 365 -Flavor mint-chocolate | Should Not BeNullOrEmpty
            Get-FlatCupCake -AgeInYears 2 -AgeInDays 36 -Flavor vanilla | Should BeNullOrEmpty
        }

        It "Validate 'New-<Type>Object' function generation for the complex types used for the global parameters" {
            Get-Command -Name New-QuotaParametersObject -Module $GeneratedModuleName | Should Not BeNullOrEmpty
        }
    }
}