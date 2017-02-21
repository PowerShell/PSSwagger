Describe "Get-InternalFileHash Tests" -Tags "UnitTest" {
    BeforeAll {
        # TODO: Just make a temp document in temp folder with some random characters
        $testDocument = Join-Path -Path "$PSScriptRoot" -ChildPath "data"  | Join-Path -ChildPath "PsSwaggerTestBasic" | Join-Path -ChildPath "PsSwaggerTestBasicData.json"
        . "$PSScriptRoot\..\PSSwagger\Utils.ps1"
    }

    Context "Hash equivalency with built-in hash" {
        It "Should equal Get-FileHash with defaults" {
            if (('Core' -eq (Get-PSEdition)) -or ($PSVersionTable.PSVersion -ge '5.1')) {
                $builtInHash = Get-FileHash -Path $testDocument
                $customHash = Get-InternalFileHash -Path $testDocument
                Write-Verbose "Built-in hash: $($builtInHash.Hash)"
                Write-Verbose "Custom hash: $($customHash.Hash)"
                ($builtInHash.Hash -eq $customHash.Hash) | Should Be $true
            } else {
                Write-Warning 'Hash equivalency tests can only be run in PowerShell Core or PowerShell 5.1+'
            }
        }

        It "Should equal Get-FileHash for all supported algorithms" {
            if (('Core' -eq (Get-PSEdition)) -or ($PSVersionTable.PSVersion -ge '5.1')) {
                # Note that Get-CustomFileHash disables MACTripleDES
                if ('Core' -eq (Get-PSEdition)) {
                    $algorithms = @('SHA1','SHA256','SHA384','SHA512','MD5')
                } else {
                    $algorithms = @('SHA1','SHA256','SHA384','SHA512','MD5','RIPEMD160')
                }
                
                $algorithms | ForEach-Object {
                    $builtInHash = Get-FileHash -Path $testDocument -Algorithm $_
                    $customHash = Get-InternalFileHash -Path $testDocument -Algorithm $_
                    Write-Verbose "Algorithm under test: $_"
                    Write-Verbose "Built-in hash: $($builtInHash.Hash)"
                    Write-Verbose "Custom hash: $($customHash.Hash)"
                    ($builtInHash.Hash -eq $customHash.Hash) | Should Be $true
                }
            } else {
                Write-Warning 'Hash equivalency tests can only be run in PowerShell Core or PowerShell 5.1+'
            }
        }
    }
}