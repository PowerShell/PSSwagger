Import-Module (Join-Path "$PSScriptRoot" "TestUtilities.psm1") -DisableNameChecking
Describe "PSSwagger Unit Tests" -Tag @('BVT', 'DRT', 'UnitTest', 'P0') {

    BeforeAll {
        $PSSwaggerModulePath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath 'PSSwagger'
        Import-Module -Name $PSSwaggerModulePath -Force
    }

    InModuleScope PSSwagger {
        Context "Get-PathCommandName Unit Tests" {
            It "Get-PathCommandName should return command names with proper verb for VM_CreateOrUpdateWithNounSuffix operationid" {
                $CommandNames = Get-PathCommandName -OperationId VM_CreateOrUpdateWithNounSuffix
                $CommandNames -CContains 'New-VMWithNounSuffix' | Should Be $True
                $CommandNames -CContains 'Set-VMWithNounSuffix' | Should Be $True
            }

            It "Get-PathCommandName should return command names with proper verb for VM_createorupdatewithnounsuffix operationid" {
                $CommandNames = Get-PathCommandName -OperationId VM_createorupdatewithnounsuffix
                $CommandNames -CContains 'New-VMWithnounsuffix' | Should Be $True
                $CommandNames -CContains 'Set-VMWithnounsuffix' | Should Be $True
            }

            It "Get-PathCommandName should return command name with proper verb for VM_createOrWithNounSuffix operationid" {
                Get-PathCommandName -OperationId VM_createOrWithNounSuffix | Should BeExactly 'New-VMORWithNounSuffix'
            }

            It "Get-PathCommandName should return command name with proper verb for VM_migrateWithNounSuffix operationid" {
                Get-PathCommandName -OperationId VM_migrateWithNounSuffix | Should BeExactly 'Migrate-VMWithNounSuffix'
            }

            It "Get-PathCommandName should return command name with proper verb for CreateFooResource operationid" {
                Get-PathCommandName -OperationId CreateFooResource | Should BeExactly 'New-FooResource'
            }

            It "Get-PathCommandName should return command names with proper verb for createorupdatebarResource operationid" {
                $CommandNames = Get-PathCommandName -OperationId createorupdatebarResource
                $CommandNames -CContains 'New-BarResource' | Should BeExactly $True
                $CommandNames -CContains 'Set-BarResource' | Should BeExactly $True
            }

            It "Get-PathCommandName should return command name with proper verb for anotherFooResource_createFoo operationid" {
                Get-PathCommandName -OperationId anotherFooResource_createFoo | Should BeExactly 'New-AnotherFooResource'
            }

            It "Get-PathCommandName should return command name with proper verb for FooResource_createresource operationid" {
                Get-PathCommandName -OperationId FooResource_createresource | Should BeExactly 'New-FooResource'
            }

            It "Get-PathCommandName should return proper command name for abcd operationid" {
                Get-PathCommandName -OperationId abcd | Should BeExactly 'Abcd'
            }
        }
    }
}
