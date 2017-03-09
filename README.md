# PSSwagger

Tool to generate PowerShell Cmdlets using Swagger based specifications

## Syntax

New-PSSwaggerModule -SwaggerSpecPath <string> -Path <string> -ModuleName <string> [-UseAzureCsharpGenerator] [-SkipAssemblyGeneration] [-PowerShellCorePath <string>] [-IncludeCoreFxAssembly] [<CommonParameters>]

New-PSSwaggerModule -SwaggerSpecUri <uri> -Path <string> -ModuleName <string> [-UseAzureCsharpGenerator] [-SkipAssemblyGeneration] [-PowerShellCorePath <string>] [-IncludeCoreFxAssembly] [<CommonParameters>]

| Parameter       | Description                           |
| ----------------| ------------------------------------- |
| SwaggerSpecPath | Full Path to a Swagger based JSON spec|
| Path            | Full Path to a folder where the commands/modules are exported to |
| ModuleName      | Name of the module to be generated. A folder with this name will be created in the location specified by Path parameter |
| SwaggerSpecUri  | URI to the swagger spec |
| SkipAssemblyGeneration      | Skip compiling the generated module's C# assembly during generation of module (including CoreFX, even if specified) |
| PowerShellCorePath      | Path to PowerShell.exe for PowerShell Core. Only required if not installed via MSI in the default path |
| IncludeCoreFxAssembly      | Switch to additionally compile the module's binary component for core CLR |

## Supported Platforms
| Usage | Platforms |
| ----------------| ------------------------------------- |
| Developer       | Windows, Any full PowerShell version, PowerShell Core Alpha11 or older for Core CLR compilation |
| Module Publisher| Any full PowerShell version |
| Module Consumer | Any full PowerShell version, PowerShell Core Alpha11 or older  |

**Testing note**: While any full PowerShell version is fine for development, we recommend using PowerShell 5.1+ to enable testing our implementation of Get-FileHash.

## Usage

1. Git clone this repository.
  ```code
  git clone https://github.com/PowerShell/PSSwagger.git
  ```

2. Ensure you AutoRest version 0.16.0 installed
  ```powershell
  Install-Package -Name AutoRest -Source https://www.nuget.org/api/v2 -RequiredVersion 0.16.0 -Scope CurrentUser
  ```   

3. Ensure AutoRest.exe is in $env:Path
  ```powershell
  $env:path += ";$env:localappdata\PackageManagement\NuGet\Packages\AutoRest.0.16.0\tools"
  ```

4. If you plan on precompiling the generated assembly, ensure you have the module AzureRM.Profile or AzureRM.NetCore.Preview available to PackageManagement if you are on PowerShell or PowerShell Core, respectively.

5. Run the following in a PowerShell console from the directory where you cloned PSSwagger in
  ```powershell
  Import-Module .\PSSwagger\PSSwagger.psd1
  $param = @{
    SwaggerSpecUri = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json'
    Path           = 'C:\Temp\generatedmodule\'
    ModuleName     = 'Generated.AzureRM.BatchManagement'
    UseAzureCsharpGenerator = $true
  }
  New-PSSwaggerModule @param
  ```

After step 5, the module will be in `C:\Temp\GeneratedModule\Generated.AzureRM.BatchManagement ($param.Path)` folder.

Before importing that module and using it, you need to import `Generated.Azure.Common.Helpers` module which is under PSSwagger folder.
    
```powershell
Import-Module .\PSSwagger\Generated.Azure.Common.Helpers
Import-Module "$($param.Path)\$($param.ModuleName)"
Get-Command -Module $param.ModuleName
```

## Dynamic generation of C# assembly
When importing the module for the first time, the packaged C# files will be automatically compiled if the expected assembly doesn't exist. 
If the module's script files are signed, regardless of your script execution policy, the catalog file's signing will be checked for validity. 
If the generated module is not signed, the catalog file's signing will not be checked. However, the catalog file's hashed contents will always be checked.

## Distribution of module
Because of the dynamic compilation feature, it is highly recommended that publishers of a generated module Authenticode sign the module and strong name sign both precompiled assemblies (full CLR and core CLR).

## Upcoming additions

1. Enabe PowerShell Best practices
   * Using approved Verbs
   * Verbs that change system like New/Update/Remove need to implement ShouldProcess (-WhatIf/-Confirm)
   * Mapping properties to ValueFromPipeline semantics so that  Get-<Noun> | Remove-<Noun>  (and other pipeline scenarios) work.
   * Long running operations need to have -AsJob variants and use -Job cmdlets for further processing.
2. Representing complex objects as parameters
3. Identifying / driving common extensions in Swagger not just MAS but for entire PowerShell ecosystem.
4. Test Cases
5. Make generated cmdlets work with PowerShell Core on Linux / Mac

## Notes

1. Swagger Specification is at: http://swagger.io/specification/
2. Azure ARM based Swagger documents at: https://github.com/Azure/azure-rest-api-specs
3. AutoRest Generators: https://github.com/Azure/autorest/tree/master/src/generator

## Developers

###  Testing
You can run tests right after cloning the repository. The test scripts should install the required packages. To run the tests, navigate to the Tests directory, then run:

```powershell
.\run-tests.ps1 -TestFramework <framework> -Verbose -TestSuite <TestSuite> -TestName <TestName>
```

TestFramework should be one of "net452" | "netstandard1.7". If you are on Windows, you can use either net452, which uses the full CLR, or netstandard1.7, which uses the Core CLR. For Linux, Darwin, or Nano Server users, you will have to use netstandard1.7.

    TestFramework defaults to net452

Use TestSuite or TestName parameters to filter by Pester Tag or test name.

#### What does the script do?
The script will ensure dependencies exist on your machine, like AutoRest, node.js, npm, json-server, and dotnet CLI. Then it will run pester tests in a separate PS session and validate no tests failed.

    If dotnet CLI is already in your PS session's path, and you don't need to upgrade, you can use the parameter -SkipBootstrap to skip dotnet CLI bootstrapping and save lots of time.

#### Unit tests
| Scenario        | Description                           |
| ----------------| ------------------------------------- |
| Get-InternalFileHash | Tests that Get-InternalFileHash is equivalent to Get-FileHash in PS 5.1+ |

#### Scenario tests
The scenario test suite contains tests that hit actual (local) web API endpoints. The following scenarios are covered:

| Scenario        | Description                           |
| ----------------| ------------------------------------- |
| PsSwaggerTestsBasic | A very basic test of a single string-only path using get and post.|