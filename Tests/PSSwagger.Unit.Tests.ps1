#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Tests
#
#########################################################################################
Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1") -DisableNameChecking
Describe "PSSwagger Unit Tests" -Tag @('BVT', 'DRT', 'UnitTest', 'P0') {

    BeforeAll {
        $PSSwaggerModulePath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath 'PSSwagger'
        $PSSwaggerModuleInfo = Import-Module -Name $PSSwaggerModulePath -Force -ArgumentList $true -PassThru
    }

    InModuleScope PSSwagger {
        Context "Get-PathCommandName Unit Tests" {
            It "Get-PathCommandName should return command names with proper verb for VM_CreateOrUpdateWithNounSuffix operationid" {
                $CommandNames = Get-PathCommandName -OperationId VM_CreateOrUpdateWithNounSuffix | Foreach-Object { $_.name }
                $CommandNames -CContains 'New-VMWithNounSuffix' | Should Be $True
                $CommandNames -CContains 'Set-VMWithNounSuffix' | Should Be $True
            }

            It "Get-PathCommandName should return command names with proper verb for VM_createorupdatewithnounsuffix operationid" {
                $CommandNames = Get-PathCommandName -OperationId VM_createorupdatewithnounsuffix | Foreach-Object { $_.name }
                $CommandNames -CContains 'New-VMWithnounsuffix' | Should Be $True
                $CommandNames -CContains 'Set-VMWithnounsuffix' | Should Be $True
            }

            It "Get-PathCommandName should return command name with proper verb for VM_createOrWithNounSuffix operationid" {
                Get-PathCommandName -OperationId VM_createOrWithNounSuffix | Foreach-Object { $_.name } | Should BeExactly 'New-VMOrWithNounSuffix'
            }

            It "Get-PathCommandName should return command name with proper verb for VM_migrateWithNounSuffix operationid" {
                Get-PathCommandName -OperationId VM_migrateWithNounSuffix | Foreach-Object { $_.name } | Should BeExactly 'Move-VMWithNounSuffix'
            }

            It "Get-PathCommandName should return command name with proper verb for CreateFooResource operationid" {
                Get-PathCommandName -OperationId CreateFooResource | Foreach-Object { $_.name } | Should BeExactly 'New-FooResource'
            }

            It "Get-PathCommandName should return command names with proper verb for createorupdatebarResource operationid" {
                $CommandNames = Get-PathCommandName -OperationId createorupdatebarResource | Foreach-Object { $_.name }
                $CommandNames -CContains 'New-BarResource' | Should BeExactly $True
                $CommandNames -CContains 'Set-BarResource' | Should BeExactly $True
            }

            It "Get-PathCommandName should return command name with proper verb for anotherFooResource_createFoo operationid" {
                Get-PathCommandName -OperationId anotherFooResource_createFoo | Foreach-Object { $_.name } | Should BeExactly 'New-AnotherFooResource'
            }

            It "Get-PathCommandName should return command name with proper verb for FooResource_createresource operationid" {
                Get-PathCommandName -OperationId FooResource_createresource | Foreach-Object { $_.name } | Should BeExactly 'New-FooResource'
            }

            It "Get-PathCommandName should return proper command name for abcd operationid" {
                Get-PathCommandName -OperationId abcd | Foreach-Object { $_.name } | Should BeExactly 'Abcd'
            }

            It "Get-PathCommandName with NetworkInterfaces_ListVirtualMachineScaleSetVMNetworkInterfaces" {
                Get-PathCommandName -OperationId NetworkInterfaces_ListVirtualMachineScaleSetVMNetworkInterfaces | Foreach-Object { $_.name } | Should BeExactly 'Get-VirtualMachineScaleSetVMNetworkInterface'
            }

            It "Get-PathCommandName with Databases_Pause" {
                Get-PathCommandName -OperationId Databases_Pause | ForEach-Object { $_.name } | Should BeExactly 'Suspend-Database'
            }
        }

        Context 'Get-XDGDirectory Unit Tests (Linux) (Default)' {
            Mock Get-OperatingSystemInfo -ModuleName PSSwaggerUtility {
                return @{
                    IsCore    = $true
                    IsLinux   = $true
                    IsMacOS   = $false
                    IsWindows = $false
                }
            }

            Mock Get-EnvironmentVariable -ModuleName PSSwaggerUtility {
                if ('HOME' -eq $Name) {
                    return '/hometest'
                }

                return $null
            }

            It "Linux + Shared" {
                Get-XDGDirectory -DirectoryType Shared | should beexactly '/usr/local/share'
            }

            It "Linux + Cache" {
                $dir = Get-XDGDirectory -DirectoryType Cache
                # When test is run on Windows, let's replace the '\' with '/'
                # Could do this vice versa, but then the expected value looks funny!
                $dir = $dir.Replace('\', '/')
                $dir | should beexactly '/hometest/.cache'
            }

            It "Linux + Data" {
                $dir = Get-XDGDirectory -DirectoryType Data
                # When test is run on Windows, let's replace the '\' with '/'
                # Could do this vice versa, but then the expected value looks funny!
                $dir = $dir.Replace('\', '/')
                $dir | should beexactly '/hometest/.local/share'
            }

            It "Linux + Config" {
                $dir = Get-XDGDirectory -DirectoryType Config
                # When test is run on Windows, let's replace the '\' with '/'
                # Could do this vice versa, but then the expected value looks funny!
                $dir = $dir.Replace('\', '/')
                $dir | should beexactly '/hometest/.config'
            }
        }

        Context 'Get-XDGDirectory Unit Tests (Linux) (Custom)' {
            Mock Get-OperatingSystemInfo -ModuleName PSSwaggerUtility {
                return @{
                    IsCore    = $true
                    IsLinux   = $true
                    IsMacOS   = $false
                    IsWindows = $false
                }
            }

            Mock Get-EnvironmentVariable -ModuleName PSSwaggerUtility {
                if ('HOME' -eq $Name) {
                    return '/hometest'
                }
                elseif ('XDG_CACHE_HOME' -eq $Name) {
                    return '/cacheHome'
                }
                elseif ('XDG_CONFIG_HOME' -eq $Name) {
                    return '/configHome'
                }
                elseif ('XDG_DATA_HOME' -eq $Name) {
                    return '/dataHome'
                }

                return $null
            }

            It "Linux + Shared" {
                Get-XDGDirectory -DirectoryType Shared | should beexactly '/usr/local/share'
            }

            It "Linux + Cache" {
                Get-XDGDirectory -DirectoryType Cache | should beexactly '/cacheHome'
            }

            It "Linux + Data" {
                Get-XDGDirectory -DirectoryType Data | should beexactly '/dataHome'
            }

            It "Linux + Config" {
                Get-XDGDirectory -DirectoryType Config | should beexactly '/configHome'
            }
        }

        Context 'Get-XDGDirectory Unit Tests (Windows)' {
            Mock Get-OperatingSystemInfo -ModuleName PSSwaggerUtility {
                return @{
                    IsCore    = $true
                    IsLinux   = $false
                    IsMacOS   = $false
                    IsWindows = $true
                }
            }

            It "Windows + Shared" {
                $expectedPath = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell'
                Get-XDGDirectory -DirectoryType Shared | should beexactly $expectedPath
            }

            It "Windows + Cache" {
                $expectedPath = [System.IO.Path]::GetTempPath()
                Get-XDGDirectory -DirectoryType Cache | should beexactly $expectedPath
            }

            It "Windows + Data" {
                $expectedPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell'
                Get-XDGDirectory -DirectoryType Data | should beexactly $expectedPath
            }

            It "Windows + Config" {
                $expectedPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell'
                Get-XDGDirectory -DirectoryType Config | should beexactly $expectedPath
            }
        }

        Context "Get-HeaderContent Unit Tests" {
            BeforeAll {
                $moduleInfo = Get-Module -Name PSSwagger
                $DefaultGeneratedFileHeaderString = $DefaultGeneratedFileHeader -f $moduleInfo.Version
                
                $InvalidHeaderFileExtensionPath = Join-Path -Path $PSScriptRoot -ChildPath '*.ps1'
                $UnavailableHeaderFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'NotExistingHeaderFile.txt'
                
                $FolderPathEndingWithDotTxt = Join-Path -Path $PSScriptRoot -ChildPath 'TestFoldeName.txt'
                $null = New-Item -Path $FolderPathEndingWithDotTxt -ItemType Directory -Force
                
                $ValidHeaderFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'TestHeader.txt'
                Out-File -FilePath $ValidHeaderFilePath -InputObject 'Content from Header file' -Force -WhatIf:$false -Confirm:$false
                $HeaderFileContent = Get-Content -Path $ValidHeaderFilePath -Raw
            }

            AfterAll {
                Get-Item -Path $FolderPathEndingWithDotTxt -ErrorAction SilentlyContinue | Remove-Item -Force
                Get-Item -Path $ValidHeaderFilePath -ErrorAction SilentlyContinue | Remove-Item -Force                
            }

            It "Get-HeaderContent should return null when header value is 'NONE'" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'NONE'}} | Should BeNullOrEmpty
            }

            It "Get-HeaderContent should return default header content when header value is empty" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = ''}} | Should BeExactly $DefaultGeneratedFileHeaderString
            }

            It "Get-HeaderContent should return default header content when header value is null" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = $null}} | Should BeExactly $DefaultGeneratedFileHeaderString
            }
            
            It "Get-HeaderContent should throw when the specified header file path is invalid" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = $InvalidHeaderFileExtensionPath}} -ErrorVariable ev -ErrorAction SilentlyContinue | Should BeNullOrEmpty
                $ev[0].FullyQualifiedErrorId | Should BeExactly 'InvalidHeaderFileExtension,Get-HeaderContent'
            }
            
            It "Get-HeaderContent should throw when the specified header file path is not found" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = $UnavailableHeaderFilePath}} -ErrorVariable ev -ErrorAction SilentlyContinue | Should BeNullOrEmpty
                $ev[0].FullyQualifiedErrorId | Should BeExactly 'HeaderFilePathNotFound,Get-HeaderContent'
            }
            
            It "Get-HeaderContent should throw when the specified header file path is not a file path" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = $FolderPathEndingWithDotTxt}} -ErrorVariable ev -ErrorAction SilentlyContinue | Should BeNullOrEmpty
                $ev[0].FullyQualifiedErrorId | Should BeExactly 'InvalidHeaderFilePath,Get-HeaderContent'
            }

            It "Get-HeaderContent should return content from the header file" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = $ValidHeaderFilePath}} | Should BeExactly $HeaderFileContent
            }

            It "Get-HeaderContent should return MICROSOFT_MIT header content with '-Header MICROSOFT_MIT'" {
                $ExpectedHeaderContent = $MicrosoftMitLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderString
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_MIT'}} | Should BeExactly $ExpectedHeaderContent
            }

            It "Get-HeaderContent should return MICROSOFT_MIT_NO_VERSION header content with '-Header MICROSOFT_MIT_NO_VERSION'" {
                $ExpectedHeaderContent = $MicrosoftMitLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderWithoutVersion
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_MIT_NO_VERSION'}} | Should BeExactly $ExpectedHeaderContent
            }

            It "Get-HeaderContent should return MICROSOFT_MIT_NO_CODEGEN header content with '-Header MICROSOFT_MIT_NO_CODEGEN'" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_MIT_NO_CODEGEN'}} | Should BeExactly $MicrosoftMitLicenseHeader
            }

            It "Get-HeaderContent should return MICROSOFT_APACHE header content with '-Header MICROSOFT_APACHE'" {
                $ExpectedHeaderContent = $MicrosoftApacheLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderString
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_APACHE'}} | Should BeExactly $ExpectedHeaderContent
            }

            It "Get-HeaderContent should return MICROSOFT_APACHE_NO_VERSION header content with '-Header MICROSOFT_APACHE_NO_VERSION'" {
                $ExpectedHeaderContent = $MicrosoftApacheLicenseHeader + [Environment]::NewLine + [Environment]::NewLine + $DefaultGeneratedFileHeaderWithoutVersion
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_APACHE_NO_VERSION'}} | Should BeExactly $ExpectedHeaderContent
            }

            It "Get-HeaderContent should return MICROSOFT_APACHE_NO_CODEGEN header content with '-Header MICROSOFT_APACHE_NO_CODEGEN'" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'MICROSOFT_APACHE_NO_CODEGEN'}} | Should BeExactly $MicrosoftApacheLicenseHeader
            }

            It 'Get-HeaderContent should escape <#' {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'Header content with <#'}} | Should BeExactly 'Header content with <`#'
            }

            It 'Get-HeaderContent should escape #>' {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'Header content with #>'}} | Should BeExactly 'Header content with #`>'
            }

            It 'Get-HeaderContent should replace -- with ==' {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'Header content with --'}} -WarningVariable wv -WarningAction SilentlyContinue | Should BeExactly 'Header content with =='
                $wv | Should not BeNullOrEmpty
                $wv.Message -match '==' | Should Be $true
            }

            It "Get-HeaderContent should escape '<#' and '#>', and replace '--' with '=='" {
                Get-HeaderContent -SwaggerDict @{Info = @{Header = 'Header content with <# PS comment #> and --.'}} -WarningAction SilentlyContinue | Should BeExactly 'Header content with <`# PS comment #`> and ==.'
            }
        }
        
        Context "Get-CSharpModelName Unit Tests" {
            It "Get-CSharpModelName should remove special characters" {
                Get-CSharpModelName -Name @"
                    SomeTypeWithSpecialCharacters ~!@#$%^&*()_+|}{:"<>?,./;'][\=-``
"@  | Should BeExactly 'SomeTypeWithSpecialCharacters'
            }
            It "Get-CSharpModelName should replace [] with Sequence" {
                Get-CSharpModelName -Name 'foo[]'  | Should BeExactly 'FooSequence'
            }
            It "Get-CSharpModelName should append 'Model' for C# reserved words" {
                Get-CSharpModelName -Name 'break'  | Should BeExactly 'BreakModel'
            }
        }

        Context "Convert-GenericTypeToString Unit Tests" {
            It "Convert-GenericTypeToString with 'System.Int32' type" {
                Convert-GenericTypeToString -Type ('System.Int32' -as [type]) | Should BeExactly 'System.Int32'
            }
            It "Convert-GenericTypeToString with 'System.String[]' type" {
                Convert-GenericTypeToString -Type ('System.String[]' -as [type]) | Should BeExactly 'System.String[]'
            }
            It "Convert-GenericTypeToString with 'System.Collections.Generic.List[string]' type" {
                Convert-GenericTypeToString -Type ('System.Collections.Generic.List[string]' -as [type]) | Should BeExactly 'System.Collections.Generic.List[System.String]'
            }
            It "Convert-GenericTypeToString with 'System.Collections.Generic.Dictionary[string, string]' type" {
                Convert-GenericTypeToString -Type ('System.Collections.Generic.Dictionary[string, string]' -as [type]) | Should BeExactly 'System.Collections.Generic.Dictionary[System.String,System.String]'
            }
        }
    }
    
    Context 'Get-ArmResourceIdParameterValue unit tests' {
        BeforeAll {
            . (Join-Path -Path $PSSwaggerModuleInfo.ModuleBase -ChildPath 'Get-ArmResourceIdParameterValue.ps1')
            $IdTemplate = '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}'
        }

        It 'Get-ArmResourceIdParameterValue with invalid token in ResourceId value' {
            $Id = '/subscriptions/362fb8f0-95fd-4f9a-9a4a-7cff0459a881/resourceGroups/testresourcegroup/providers/Microsoft.DocumentDB/databaseAccounts/contoso-databaseaccount'
            $ResourceIdParameterValues = Get-ArmResourceIdParameterValue -Id $Id -IdTemplate $IdTemplate
            $ResourceIdParameterValues | Should Not BeNullOrEmpty

            $ExpectedResourceIdParameterValues = @{
                'subscriptionId'    = '362fb8f0-95fd-4f9a-9a4a-7cff0459a881'
                'resourceGroupName' = 'testresourcegroup'
                'accountName'       = 'contoso-databaseaccount'
            }
            $ExpectedResourceIdParameterValues.GetEnumerator() | ForEach-Object {
                $ResourceIdParameterValues[$_.Name] | Should BeExactly $_.Value
            }                
        }

        It 'Get-ArmResourceIdParameterValue with invalid ResourceId value' {
            Get-ArmResourceIdParameterValue -Id '/InvalidId' -IdTemplate $IdTemplate -ErrorVariable ev -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            $ev[0].FullyQualifiedErrorId | Should BeExactly 'InvalidResourceIdValue,Get-ArmResourceIdParameterValue'
        }

        It 'Get-ArmResourceIdParameterValue with invalid token in ResourceId value' {
            $Id = '/subscriptions/362fb8f0-95fd-4f9a-9a4a-7cff0459a881/resourceGroupsInvalid/testresourcegroup/providers/Microsoft.DocumentDB/databaseAccounts/contoso-databaseaccount'
            Get-ArmResourceIdParameterValue -Id $Id -IdTemplate $IdTemplate -ErrorVariable ev -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            $ev[0].FullyQualifiedErrorId | Should BeExactly 'InvalidResourceIdValue,Get-ArmResourceIdParameterValue'
        }
    }
}
