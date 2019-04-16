
# PSSwagger

A PowerShell module with commands to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

*PSSwagger is no longer being developed*, but do not fret! AutoRest is now able to generate cmdlets directly, without needing PSSwagger. Please refer to: https://devblogs.microsoft.com/powershell/cmdlets-via-autorest/

This repository remains available for reference but pull requests and new issues will not be monitored.

# PSSwagger Documentation

## PSSwagger commands
- [New-PSSwaggerModule](/docs/commands/New-PSSwaggerModule.md)
- [New-PSSwaggerMetadataFile](/docs/commands/New-PSSwaggerMetadataFile.md)

## Customizing PowerShell Metadata
- [PowerShell Extensions](/docs/extensions/readme.md)

## Testing generated module
- [Mocking New-ServiceClient utility](/docs/testing/NewServiceClient.md)

## Supported Platforms
| Usage | Platforms |
| ----------------| ------------------------------------- |
| Developer       | Windows, PowerShell 5.1+, Latest PowerShell Core |
| Module Publisher| PowerShell 5.1+ |
| Module Consumer | PowerShell 5.1+, Latest PowerShell Core  |

**Future note**: We plan on supporting PowerShell 4+ for module consumers in the future; that scenario is untested currently.
**Testing note**: While any full PowerShell version is fine for development, we recommend using PowerShell 5.1+ to enable testing our implementation of Get-FileHash.

## Dependencies
| Dependency       | Version   | Description              |             
| ----------------| ----------- | -------------------------- |
| AutoRest | 0.17.3 or newer | Tool to generate C# SDK from Swagger spec |
| CSC.exe (Microsoft.Net.Compilers) | 2.3.1 or newer | C# Compiler to generate C# SDK assembly on Windows PowerShell |
| Newtonsoft.Json | Full CLR: 6.0.8, Core CLR: 9.0.1 | NuGet package containing Newtonsoft.Json assembly, required for all modules |
| Microsoft.Rest.ClientRuntime | 2.3.4 or newer | NuGet package containing Microsoft.Rest.ClientRuntime assembly, required for all modules |
| Microsoft.Rest.ClientRuntime.Azure | 3.3.4 or newer | NuGet package containing Microsoft.Rest.ClientRuntime.Azure assembly, required for Microsoft Azure modules |
| AzureRM.Profile | 2.0.0 or newer | Module containing authentication helpers, required for Microsoft Azure modules on PowerShell |
| AzureRM.Profile.NetCore.Preview | * | Module containing authentication helpers, required for Microsoft Azure modules on PowerShell Core |

## Usage
NOTE: In the short term, for best performance, the operation IDs in your Open API specifications should be of the form "<Noun>_<Verb><Suffix>". For example, the operation ID "Resource_GetByName" gets a resource named Resource by name.
1. Get PSSwagger!
    * Install from PowerShellGallery.com
       ```powershell
       Install-Module -Name PSSwagger
       ```
    * Clone the repository
        ```powershell
        git clone https://github.com/PowerShell/PSSwagger.git
       ```

2. Ensure AutoRest is installed and available in $env:PATH
    - Follow the instructions provided at [AutoRest github repository](https://github.com/Azure/Autorest#installing-autorest).
    - Ensure AutoRest.cmd path is in $env:Path
        ```powershell
        $env:path += ";$env:APPDATA\npm"
        Get-Command -Name AutoRest
        ```
3. Ensure CSC.exe is installed and available in $env:PATH
    - If CSC.exe is not installed already, install Microsoft.Net.Compilers package
        ```powershell
        Install-Package -Name Microsoft.Net.Compilers -Source https://www.nuget.org/api/v2 -Scope CurrentUser
        ```
    - Add CSC.exe path to $env:Path
        ```powershell
        $package = Get-Package -Name Microsoft.Net.Compilers
        $env:path += ";$(Split-Path $package.Source -Parent)\tools"
        Get-Command -Name CSC.exe
        ```

4. If you plan on pre-compiling the generated assembly, ensure you have the module AzureRM.Profile or AzureRM.NetCore.Preview available to PackageManagement if you are on PowerShell or PowerShell Core, respectively.

5. Run the following in a PowerShell console from the directory where you cloned PSSwagger in

    ```powershell
    # Import PSSwagger module
    Import-Module PSSwagger

    # If you are trying from a clone of this repository, follow below steps to import the PSSwagger module.
    # Ensure PSSwaggerUtility module is available in $env:PSModulePath
    # Please note the trialing back slash ('\') to ensure PSSwaggerUtility module is available.
    $PSSwaggerFolderPath = Resolve-Path '.\PSSwagger\'
    $env:PSModulePath = "$PSSwaggerFolderPath;$env:PSModulePath"
    Import-Module .\PSSwagger

    # Ensure PSSwagger module is loaded into the current session
    Get-Module PSSwagger

    # Prepare input parameters for cmdlet generation
    $null = New-Item -ItemType Directory -Path C:\GeneratedModules -Force
    $params = @{
      # Download the Open API v2 Specification from this location
      SpecificationUri = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json'
      # Output the generated module to this path
      Path           = 'C:\GeneratedModules\'
      # Name of the generated module
      Name           = 'AzBatchManagement'
      # This specification is for a Microsoft Azure service, so use Azure-specific functionality
      UseAzureCsharpGenerator = $true
    }
    
    # You may be prompted to download missing dependencies
    New-PSSwaggerModule @params
    ```

    The generated module will be in the `C:\Temp\GeneratedModule\Generated.AzureRM.BatchManagement` folder.
    For more New-PSSwaggerModule options, check out the [documentation](/docs/commands/New-PSSwaggerModule.md).
6. Your generated module is now ready! For production modules (i.e. modules you will publish to PowerShellGallery.com), we recommend using the -IncludeCoreFxAssembly option to generate the Core CLR assembly, strong name signing assemblies in the generated module, and authenticode signing the module. Optionally, you can remove the generated C# code (under the Generated.CSharp folder) for even more security.

## Metadata Generation
There are many cases where module generation doesn't result in the most optimal names for things like parameters or commands. To enable this and many other customization options, we've introduced additional PowerShell-specific Open API extensions that can be specified separately from your main specification. For more information, check out [PowerShell Extensions](/docs/extensions/readme.md) and [New-PSSwaggerMetadataFile](/docs/commands/New-PSSwaggerMetadataFile.md).

## Dynamic generation of C# assembly
When importing the module for the first time, the packaged C# files will be automatically compiled if the expected assembly doesn't exist.

## Microsoft.Rest.ServiceClientTracing support
To enable Microsoft.Rest.ServiceClientTracing support, pass -Debug into any generated command.

The included PowerShell tracer uses Write-Debug to write tracing messages.

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
Import-Module PSSwaggerUtility
PSSwaggerUtility\Initialize-PSSwaggerDependencies -AcceptBootstrap -Azure
```
For Microsoft Azure modules, or:
```powershell
Import-Module PSSwaggerUtility
PSSwaggerUtility\Initialize-PSSwaggerDependencies -AcceptBootstrap
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
The PSSwagger implementation of the [Azure Live Test Framework protocol](https://github.com/Azure/azure-rest-api-specs-tests/blob/master/json-rpc-server.md) is currently located in this repository in a subdirectory. Once PSSwaggerUtility is published to [PowerShellGallery.com](https://powershellgallery.com), the PSSwagger.LiveTestFramework code will be moved to a separate repository. You can find the readme for the PSSwagger.LiveTestFramework module [here](/docs/commands/New-PSSwaggerMetadataFile.md).

# [Code of Conduct](CODE_OF_CONDUCT.md)
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
