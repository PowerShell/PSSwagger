NOTE: The git top level directory is referred to as ~ in this doc.
# PSSwagger.LiveTestFramework
## Creating the module
While you can directly import PSSwagger.LiveTestFramework.psd1 for local testing, the subdirectories contain a lot of files not used by the final module. To create the final module, run ```~\Build-PowerShellModule.psd1 -OutputDirectory $outputDirectory```. The module will be copied into the folder ```$outputDirectory\$moduleVersion```. You can find the module version in ```~\release.json```. The build script should be used for publishing and final testing. All code will be automatically converted to ```.Code.ps1``` files.
## C# vs. Code Files
The C# code in this module is represented two ways: in ```.cs``` form and in ```.Code.ps1``` form. When distributing, the code is transformed into ```.Code.ps1``` files and authenticode signed. For test code, the C# code is transformed into ```.cs``` form and includes both a VisualStudio-compatible ```.csproj``` (under the ```vs-csproj``` folder) and a dotnet CLI ```.csproj```. The scripts ```~\src\ConvertTo-CSharpFiles.ps1``` and ```~\src\ConvertFrom-CSharpFiles.ps1``` are provided to convert between ```.cs``` and ```.Code.ps1``` files. The module PSSwagger.LiveTestFramework expects ```.Code.ps1``` files only.
# PSSwagger.LiveTestFramework.Tests
Under the ```~\test``` folder, you'll find all the tests for PSSwagger.LiveTestFramework. We use a mixture of C# tests for the C# components, and Pester for the PowerShell components. All the build/run scripts are wrapped by PowerShell commands located in this module. Like the product module (PSSwagger.LiveTestFramework), the test module depends on ```PSSwaggerUtility```. A helper script is available to load the helper module then the test module: ```~\test\Load-TestModule.ps1```.
## Dependencies
You can install PSSwagger.LiveTestFramework.Tests dependencies using the command ```Initialize-LTFTestsDependencies```. Current test dependencies:
* dotnet CLI
* Pester
## Executing test run
Full test run for net452: ```Start-LTFTestsRun``` or ```Start-LTFTestsRun -Framework net452```
Full test run for netcoreapp2.0: ```Start-LTFTestsRun -Framework netcoreapp2.0```
## C# vs. Code Files
When developing C# test projects, ensure all code is in .cs form using ```~\src\ConvertTo-CSharpFiles.ps1```. The test run command will do this automatically.