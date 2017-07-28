| Gitter | AppVeyor (Windows) |
|--------------------------|--------------------------|
| [![gitter-image][]][gitter-site] | [![av-image][]][av-site] |

[av-image]: https://ci.appveyor.com/api/projects/status/lx8ibbw9wjlpsu8u
[av-site]: https://ci.appveyor.com/project/PowerShell/psswagger
[gitter-image]: https://badges.gitter.im/PowerShell/PSSwagger.svg
[gitter-site]: https://gitter.im/PowerShell/PSSwagger

# PSSwagger

A PowerShell module with commands to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

# PSSwagger Documentation

## PSSwagger commands
- [New-PSSwaggerModule](/docs/commands/New-PSSwaggerModule.md)
- [New-PSSwaggerMetadataFile](/docs/commands/New-PSSwaggerMetadataFile.md)

## Customizing PowerShell Metadata
- [PowerShell Extensions](/docs/extensions/readme.md)

## Supported Platforms
| Usage | Platforms |
| ----------------| ------------------------------------- |
| Developer       | Windows, Any full PowerShell version, PowerShell Core (NOTE: AzureRM.Profile is currently broken on beta.1, but a new module should be released soon) |
| Module Publisher| Any full PowerShell version |
| Module Consumer | Any full PowerShell version, PowerShell Core Alpha11 or older  |

**Testing note**: While any full PowerShell version is fine for development, we recommend using PowerShell 5.1+ to enable testing our implementation of Get-FileHash.

## Dependencies
| Dependency       | Version   | Description              |             
| ----------------| ----------- | -------------------------- |
| AutoRest | 0.17.3 | Tool to generate C# SDK from Swagger spec |
| Newtonsoft.Json | Full CLR: 6.0.8, Core CLR: 9.0.1 | NuGet package containing Newtonsoft.Json assembly, required for all modules |
| Microsoft.Rest.ClientRuntime | 2.3.4 | NuGet package containing Microsoft.Rest.ClientRuntime assembly, required for all modules |
| Microsoft.Rest.ClientRuntime.Azure | 3.3.4 | NuGet package containing Microsoft.Rest.ClientRuntime.Azure assembly, required for Microsoft Azure modules |
| AzureRM.Profile | * | Module containing authentication helpers, required for Microsoft Azure modules on PowerShell |
| AzureRM.Profile.NetCore.Preview | * | Module containing authentication helpers, required for Microsoft Azure modules on PowerShell Core |

## Usage

1. Git clone this repository.
  ```code
  git clone https://github.com/PowerShell/PSSwagger.git
  ```

2. Ensure you AutoRest version 0.17.3 installed
  ```powershell
  Install-Package -Name AutoRest -Source https://www.nuget.org/api/v2 -RequiredVersion 0.17.3 -Scope CurrentUser
  ```   

3. Ensure AutoRest.exe is in $env:Path
  ```powershell
  $env:path += ";$env:localappdata\PackageManagement\NuGet\Packages\AutoRest.0.17.3\tools"
  ```

4. If you plan on precompiling the generated assembly, ensure you have the module AzureRM.Profile or AzureRM.NetCore.Preview available to PackageManagement if you are on PowerShell or PowerShell Core, respectively.

5. Run the following in a PowerShell console from the directory where you cloned PSSwagger in
  ```powershell
  Import-Module .\PSSwagger\PSSwagger.psd1
  $param = @{
    SpecificationUri = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json'
    Path           = 'C:\GeneratedModules\'
    Name           = 'AzBatchManagement'
    UseAzureCsharpGenerator = $true
  }
  New-PSSwaggerModule @param
  ```

After step 5, the module will be in `C:\Temp\GeneratedModule\Generated.AzureRM.BatchManagement ($param.Path)` folder.

Before importing that module and using it, you need to import `PSSwagger.Common.Helpers` module which is under PSSwagger folder. If the module is built on Azure, import the `PSSwagger.Azure.Helpers` module as well.
    
```powershell
Import-Module .\PSSwagger\PSSwagger.Common.Helpers
Import-Module .\PSSwagger\PSSwagger.Azure.Helpers
Import-Module "$($param.Path)\$($param.Name)"
Get-Command -Module $param.Name
```

## Dynamic generation of C# assembly
When importing the module for the first time, the packaged C# files will be automatically compiled if the expected assembly doesn't exist. 
If the module's script files are signed, regardless of your script execution policy, the catalog file's signing will be checked for validity. 
If the generated module is not signed, the catalog file's signing will not be checked. However, the catalog file's hashed contents will always be checked.

## Distribution of module
Because of the dynamic compilation feature, it is highly recommended that publishers of a generated module Authenticode sign the module and strong name sign both precompiled assemblies (full CLR and core CLR).

## Microsoft.Rest.ServiceClientTracing support
To enable Microsoft.Rest.ServiceClientTracing support, you must:
1. Register a tracer (one is included in the PSSwagger.Common.Helpers module for PowerShell 5.0 and above)
2. Enable tracing

To register the PowerShell tracer included in the PSSwagger.Common.Helpers module, run:
```powershell
Register-PSSwaggerClientTracing -TracerObject (New-PSSwaggerClientTracing)
```
The included PowerShell tracer uses Write-Verbose to write tracing messages. To see these messages, you must set $VerbosePreference, as passing in the -Verbose flag to the cmdlet won't carry over to the tracing client.

When the module is imported to older version of PowerShell, the following steps will need to be taken:
1. Implement either Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerClientTracing or Microsoft.Rest.IServiceClientTracingInterceptor
2. Call: [Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor($myTracer)
3. If you use the Verbose or Debug streams of PowerShell, set $VerbosePreference or $DebugPreference, respectively

Note 1: We're not sure why yet, but something is setting [Microsoft.Rest.ServiceClientTracing]::IsEnabled to true before all cmdlet calls

## Symbol Path
If the module's full CLR assembly is precompiled, the symbols folder will contain:
1. Generated.cs - The C# code used to generate the assembly
2. *.pdb - The corresponding PDB file that defines Generated.cs as the source file

# Paging
When the "x-ms-pageable" extension is specified in the Swagger spec, paging is enabled in the generated module. This is true for both fragment URLs (when operationName is specified) and full URLs (when operationName is not specified).

A cmdlet that supports paging will have two additional optional parameters:
-Paging: A switch parameter that specifies the cmdlet should only return the first page. To access the items, use $returnValue.Page
-Page: Takes as input the last page return value and outputs the next page return value (again, to access the items, use $returnValue.Page). If the return value is null, no additional pages exist.

If -Paging is not specified and the cmdlet supports paging, the cmdlet will automatically unroll all pages. Assigning the result to a variable will result in all items being retrieved. Piping the cmdlet will result in pages being retrieved on-demand.

# Silent execution when missing dependency packages
When dependency packages are expected to be missing, silent execution (bypassing the missing packages prompt) can be achieved by calling:
```powershell
PSSwagger.Azure.Helpers\Initialize-PSSwaggerDependencies -AcceptBootstrap
```
For Microsoft Azure modules, or:
```powershell
PSSwagger.Common.Helpers\Initialize-PSSwaggerDependencies -AcceptBootstrap
```
For all other modules.

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

# PSSwagger.LiveTestFramework
The PSSwagger implementation of the [Azure Live Test Framework protocol](https://github.com/Azure/azure-rest-api-specs-tests/blob/master/json-rpc-server.md) is currently located in this repository in a subdirectory. Once PSSwagger.Common.Helpers is published to [PowerShellGallery.com](https://powershellgallery.com), the PSSwagger.LiveTestFramework code will be moved to a separate repository. You can find the readme for the PSSwagger.LiveTestFramework module [here](/docs/commands/New-PSSwaggerMetadataFile.md).

# [Code of Conduct](CODE_OF_CONDUCT.md)
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
