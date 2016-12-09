$Global:testCaseParameters = @{}
function Clean-FileContent {
    param(
        [string[]]$Lines
    )

    Write-Verbose "Removing leading and trailing whitespace. Removing empty lines."
    $Lines | %{ $_.Trim() } | Where-Object { $_.Length -gt 0 } | Out-String
}

function Remove-ModuleUnderTest {
    Get-Module PSSwagger | Remove-Module
}

function Import-ModuleFromSource {
    $moduleUnderTest = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\")
    Write-Verbose "Test module path: $moduleUnderTest"
    if (-not ($env:PSModulePath.Split(";").Contains($moduleUnderTest))) {
        $env:PSModulePath += ";" + $moduleUnderTest
    }
    Write-Verbose "PSModulePath in current session: $env:PSModulePath"
    Import-Module PSSwagger
}

Describe 'ProcessSpecialCharecters' -Tag UnitTest {
    BeforeAll {
        # 1. Remove all modules matching the test module's name (e.g. if PSSwagger is installed on the dev machine) (TODO: Deal with loaded dependencies if necessary)
        # 2. Import the module under test
        Remove-ModuleUnderTest
        Import-ModuleFromSource
    }

    InModuleScope PSSwagger {
        It 'Removes special characters' {
            ProcessSpecialCharecters "abc123!@#,./ÄABC 	" | Should Be 'abcABC'
        }

        It 'Null input' {
            ProcessSpecialCharecters $null | Should Be ""
        }
    }
}

Describe 'ProcessOperationId' -Tag UnitTest {
    BeforeAll {
        # 1. Remove all modules matching the test module's name (e.g. if PSSwagger is installed on the dev machine) (TODO: Deal with loaded dependencies if necessary)
        # 2. Import the module under test
        Remove-ModuleUnderTest
        Import-ModuleFromSource
    }

    InModuleScope PSSwagger {
        It 'Operation ID is of form: noun_knownVerb' {
            ProcessOperationId "Batch_List" | Should Be "GetAll-Batch"
        }
        It 'Operation ID is of form: noun_knownVerbModifier' {
            ProcessOperationId "Batch_ListByGroup" | Should Be "GetAll-BatchByGroup"
        }
        It 'Operation ID is of form: noun_approvedVerb' {
            ProcessOperationId "Batch_New" | Should Be "New-Batch"
        }
        It 'Operation ID is of form: noun_approvedVerbModifier' {
            ProcessOperationId "Batch_NewByGroup"  | Should Be "New-BatchByGroup"
        }
        It 'Operation ID is of form: noun_approvedVerbModifier AND verb is lowercase' {
            ProcessOperationId "Batch_newByGroup"  | Should Be "New-BatchByGroup"
        }
        It 'Operation ID is of form: noun_knownVerb AND verb is lowercase' {
            ProcessOperationId "Batch_list" | Should Be "GetAll-Batch"
        }
    }
}

Describe 'ProcessDefinitions' -Tag UnitTest {
    BeforeAll {
        # 1. Remove all modules matching the test module's name (e.g. if PSSwagger is installed on the dev machine) (TODO: Deal with loaded dependencies if necessary)
        # 2. Import the module under test
        Remove-ModuleUnderTest
        Import-ModuleFromSource
    }

    BeforeEach {
        # Ensure the globals required by PSSwagger are initialized
        $Global:parameters = @{}
    }
    AfterEach {
        # Clean up globals after each test
        Clear-Variable -Name "parameters" -Scope Global
    }

    InModuleScope PSSwagger {
        It 'Basic definitions test can be processed' {
            $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\DefinitionsTest.json") -join [Environment]::NewLine) -ErrorAction Stop
            ProcessDefinitions -definitions $jsonObject.definitions
            $Global:parameters['definitionList'].Contains("AutoStorageBaseProperties") | Should Be $true
            $Global:parameters['definitionList'].Contains("BatchAccountBaseProperties") | Should Be $true
            $Global:parameters['definitionList'].Contains("BatchAccountCreateParameters") | Should Be $true
            $Global:parameters['definitionList'].Contains("AutoStorageProperties") | Should Be $true
            $Global:parameters['definitionList'].Contains("BatchAccountProperties") | Should Be $true
        }
    }
}

Describe 'ProcessGlobalParams' -Tag UnitTest {
    BeforeAll {
        # 1. Remove all modules matching the test module's name (e.g. if PSSwagger is installed on the dev machine) (TODO: Deal with loaded dependencies if necessary)
        # 2. Import the module under test
        Remove-ModuleUnderTest
        Import-ModuleFromSource
    }

    BeforeEach {
        # Ensure the globals required by PSSwagger are initialized
        $Global:parameters = @{}
    }
    AfterEach {
        # Clean up globals after each test
        Clear-Variable -Name "parameters" -Scope Global
    }

    InModuleScope PSSwagger {
        It 'Basic parameters test can be processed' {
             $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\ParametersTest.json") -join [Environment]::NewLine) -ErrorAction Stop
             ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
             # TODO: Validate what's parsed from -globalParams, because it doesn't seem to do anything right now
             $Global:parameters['infoVersion'] | Should Be "2015-12-01"
             $Global:parameters['infoTitle'] | Should Be "BatchManagement"
             $Global:parameters['infoName'] | Should Be "BatchManagementClient"
        }

        It 'Title is used as name if name does not exist' {
             $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\ParametersTestNoCodeGenSettings.json") -join [Environment]::NewLine) -ErrorAction Stop
             ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
             # TODO: Validate what's parsed from -globalParams, because it doesn't seem to do anything right now
             $Global:parameters['infoVersion'] | Should Be "2015-12-01"
             $Global:parameters['infoTitle'] | Should Be "BatchManagement"
             $Global:parameters['infoName'] | Should Be "BatchManagement"
        }
    }
}

Describe 'GenerateCommand' -Tag UnitTest {
    BeforeAll {
        # 1. Remove all modules matching the test module's name (e.g. if PSSwagger is installed on the dev machine) (TODO: Deal with loaded dependencies if necessary)
        # 2. Import the module under test
        Remove-ModuleUnderTest
        Import-ModuleFromSource
    }

    BeforeEach {
        # Ensure the globals required by PSSwagger are initialized
        $Global:parameters = @{}
    }
    AfterEach {
        # Clean up globals after each test
        Clear-Variable -Name "parameters" -Scope Global
    }

    It 'Verify basic path without Azure C#' {
        $testCaseName = "VerifyBasicPath"
        $Global:testCaseParameters["VerifyBasicPath"] = @{Operation=$null;Name="";ActualBody="";TestCaseObject=$null;ExpectedBody=$null}
        $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\GenerateCommandTestPaths.json") -join [Environment]::NewLine) -ErrorAction Stop
        $Global:testCaseParameters["VerifyBasicPath"].TestCaseObject = $jsonObject
        InModuleScope PSSwagger {
            $jsonObject = $Global:testCaseParameters["VerifyBasicPath"].TestCaseObject
            ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
            ProcessDefinitions -definitions $jsonObject.definitions
        }
        $testPath = $jsonObject.Paths.PSObject.Properties | Where-Object {$testCaseName -eq $_.Name}
        if ($null -eq $testPath) {
            throw "Couldn't find test case $testCaseName"
        }

        $testPath | % {
                # The path (usually like /resource/parameter, but for tests, the test name)
                $name = $_.Name
                $_.Value.PSObject.Properties | % {
                    $Global:testCaseParameters["VerifyBasicPath"].Operation = $_.Value
                    $Global:testCaseParameters["VerifyBasicPath"].Name = $name
                    InModuleScope PSSwagger {
                        $name = $Global:testCaseParameters["VerifyBasicPath"].Name
                        $operation = $Global:testCaseParameters["VerifyBasicPath"].Operation.operationId
                        $expectedResultFileName = $name + "_" + $operation + ".psm1"
                        Write-Verbose "Testing path $name and operation $operation"
                        Write-Verbose "Expected result file: $expectedResultFileName"
                        $actualBody = GenerateCommand $Global:testCaseParameters["VerifyBasicPath"].Operation
                        Write-Verbose "Generated command:"
                        Write-Verbose $actualBody
                        $expectedBody = Get-Content "$PSScriptRoot\Data\$expectedResultFileName"
                        $Global:testCaseParameters["VerifyBasicPath"].ActualBody = $actualBody
                        $Global:testCaseParameters["VerifyBasicPath"].ExpectedBody = $expectedBody
                    }
                    
                    # Clean before comparing (remove leading and trailing whitespace, remove empty lines, concat it all)
                    $actualBody = Clean-FileContent ($Global:testCaseParameters["VerifyBasicPath"].ActualBody -split [Environment]::NewLine)
                    $expectedBody = Clean-FileContent $Global:testCaseParameters["VerifyBasicPath"].ExpectedBody
                    $actualBody | Should Be $expectedBody
                }
            }
    }

    It 'Verify basic path with Azure C#' {
        $testCaseName = "VerifyBasicPathAzure"
        $Global:testCaseParameters["VerifyBasicPathAzure"] = @{Operation=$null;Name="";ActualBody="";TestCaseObject=$null;ExpectedBody=$null}
        $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\GenerateCommandTestPaths.json") -join [Environment]::NewLine) -ErrorAction Stop
        $Global:testCaseParameters["VerifyBasicPathAzure"].TestCaseObject = $jsonObject
        InModuleScope PSSwagger {
            $jsonObject = $Global:testCaseParameters["VerifyBasicPathAzure"].TestCaseObject
            ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
        }
        $testPath = $jsonObject.Paths.PSObject.Properties | Where-Object {$testCaseName -eq $_.Name}
        if ($null -eq $testPath) {
            throw "Couldn't find test case $testCaseName"
        }
        Write-Verbose $testPath
        $testPath | % {
                # The path (usually like /resource/parameter, but for tests, the test name)
                $name = $_.Name
                $_.Value.PSObject.Properties | % {
                    $Global:testCaseParameters["VerifyBasicPathAzure"].Operation = $_.Value
                    $Global:testCaseParameters["VerifyBasicPathAzure"].Name = $name
                    InModuleScope PSSwagger {
                        $name = $Global:testCaseParameters["VerifyBasicPathAzure"].Name
                        $operation = $Global:testCaseParameters["VerifyBasicPathAzure"].Operation.operationId
                        $expectedResultFileName = $name + "_" + $operation + ".psm1"
                        Write-Verbose "Testing path $name and operation $operation"
                        Write-Verbose "Expected result file: $expectedResultFileName"
                        $actualBody = GenerateCommand $Global:testCaseParameters["VerifyBasicPathAzure"].Operation -UseAzureCsharpGenerator
                        Write-Verbose "Generated command:"
                        Write-Verbose $actualBody
                        $expectedBody = Get-Content "$PSScriptRoot\Data\$expectedResultFileName"
                        $Global:testCaseParameters["VerifyBasicPathAzure"].ActualBody = $actualBody
                        $Global:testCaseParameters["VerifyBasicPathAzure"].ExpectedBody = $expectedBody
                    }
                    
                    # Clean before comparing (remove leading and trailing whitespace, remove empty lines, concat it all)
                    $actualBody = Clean-FileContent ($Global:testCaseParameters["VerifyBasicPathAzure"].ActualBody -split [Environment]::NewLine)
                    $expectedBody = Clean-FileContent $Global:testCaseParameters["VerifyBasicPathAzure"].ExpectedBody
                    $actualBody | Should Be $expectedBody
                }
            }
    }

    It 'Verify no Azure with operation defined in schema' {
        $testCaseName = "VerifyNoAzureWithOperation"
        $Global:testCaseParameters["VerifyNoAzureWithOperation"] = @{Operation=$null;Name="";ActualBody="";TestCaseObject=$null;ExpectedBody=$null}
        $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\GenerateCommandTestPaths.json") -join [Environment]::NewLine) -ErrorAction Stop
        $Global:testCaseParameters["VerifyNoAzureWithOperation"].TestCaseObject = $jsonObject
        InModuleScope PSSwagger {
            $jsonObject = $Global:testCaseParameters["VerifyNoAzureWithOperation"].TestCaseObject
            ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
            $Global:parameters["definitionList"] = @{ "CatDog"=$null }
        }
        $testPath = $jsonObject.Paths.PSObject.Properties | Where-Object {$testCaseName -eq $_.Name}
        if ($null -eq $testPath) {
            throw "Couldn't find test case $testCaseName"
        }

        $testPath | % {
                # The path (usually like /resource/parameter, but for tests, the test name)
                $name = $_.Name
                $_.Value.PSObject.Properties | % {
                    $Global:testCaseParameters["VerifyNoAzureWithOperation"].Operation = $_.Value
                    $Global:testCaseParameters["VerifyNoAzureWithOperation"].Name = $name
                    InModuleScope PSSwagger {
                        $name = $Global:testCaseParameters["VerifyNoAzureWithOperation"].Name
                        $operation = $Global:testCaseParameters["VerifyNoAzureWithOperation"].Operation.operationId
                        $expectedResultFileName = $name + "_" + $operation + ".psm1"
                        Write-Verbose "Testing path $name and operation $operation"
                        Write-Verbose "Expected result file: $expectedResultFileName"
                        $actualBody = GenerateCommand $Global:testCaseParameters["VerifyNoAzureWithOperation"].Operation
                        Write-Verbose "Generated command:"
                        Write-Verbose $actualBody
                        $expectedBody = Get-Content "$PSScriptRoot\Data\$expectedResultFileName"
                        $Global:testCaseParameters["VerifyNoAzureWithOperation"].ActualBody = $actualBody
                        $Global:testCaseParameters["VerifyNoAzureWithOperation"].ExpectedBody = $expectedBody
                    }
                    
                    # Clean before comparing (remove leading and trailing whitespace, remove empty lines, concat it all)
                    $actualBody = Clean-FileContent ($Global:testCaseParameters["VerifyNoAzureWithOperation"].ActualBody -split [Environment]::NewLine)
                    $expectedBody = Clean-FileContent $Global:testCaseParameters["VerifyNoAzureWithOperation"].ExpectedBody
                    $actualBody | Should Be $expectedBody
                }
            }
    }

    It 'Verify all known Swagger data types in path parameters' {
        $testCaseName = "VerifyKnownDataTypes"
        $Global:testCaseParameters["VerifyKnownDataTypes"] = @{Operation=$null;Name="";ActualBody="";TestCaseObject=$null;ExpectedBody=$null}
        $jsonObject = ConvertFrom-Json ((Get-Content "$PSScriptRoot\Data\GenerateCommandTestPaths.json") -join [Environment]::NewLine) -ErrorAction Stop
        $Global:testCaseParameters["VerifyKnownDataTypes"].TestCaseObject = $jsonObject
        InModuleScope PSSwagger {
            $jsonObject = $Global:testCaseParameters["VerifyKnownDataTypes"].TestCaseObject
            ProcessGlobalParams -globalParams $jsonObject.parameters -info $jsonObject.info
        }
        $testPath = $jsonObject.Paths.PSObject.Properties | Where-Object {$testCaseName -eq $_.Name}
        if ($null -eq $testPath) {
            throw "Couldn't find test case $testCaseName"
        }
        Write-Verbose $testPath
        $testPath | % {
                # The path (usually like /resource/parameter, but for tests, the test name)
                $name = $_.Name
                $_.Value.PSObject.Properties | % {
                    $Global:testCaseParameters["VerifyKnownDataTypes"].Operation = $_.Value
                    $Global:testCaseParameters["VerifyKnownDataTypes"].Name = $name
                    InModuleScope PSSwagger {
                        $name = $Global:testCaseParameters["VerifyKnownDataTypes"].Name
                        $operation = $Global:testCaseParameters["VerifyKnownDataTypes"].Operation.operationId
                        $expectedResultFileName = $name + "_" + $operation + ".psm1"
                        Write-Verbose "Testing path $name and operation $operation"
                        Write-Verbose "Expected result file: $expectedResultFileName"
                        $actualBody = GenerateCommand $Global:testCaseParameters["VerifyKnownDataTypes"].Operation -UseAzureCsharpGenerator
                        Write-Verbose "Generated command:"
                        Write-Verbose $actualBody
                        $expectedBody = Get-Content "$PSScriptRoot\Data\$expectedResultFileName"
                        $Global:testCaseParameters["VerifyKnownDataTypes"].ActualBody = $actualBody
                        $Global:testCaseParameters["VerifyKnownDataTypes"].ExpectedBody = $expectedBody
                    }
                    
                    # Clean before comparing (remove leading and trailing whitespace, remove empty lines, concat it all)
                    $actualBody = Clean-FileContent ($Global:testCaseParameters["VerifyKnownDataTypes"].ActualBody -split [Environment]::NewLine)
                    $expectedBody = Clean-FileContent $Global:testCaseParameters["VerifyKnownDataTypes"].ExpectedBody
                    $actualBody | Should Be $expectedBody
                }
            }
    }
}