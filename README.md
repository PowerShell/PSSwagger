# PSSwagger

Tool to generate PowerShell Cmdlets using Swagger based specifications

## Syntax

Export-CommandFromSwagger -SwaggerSpecPath <string> -Path <string> -ModuleName <string> [-UseAzureCsharpGenerator] [<CommonParameters>]

Export-CommandFromSwagger -SwaggerSpecUri <uri> -Path <string> -ModuleName <string> [-UseAzureCsharpGenerator] [<CommonParameters>]

| Parameter       | Description                           |
| ----------------| ------------------------------------- |
| SwaggerSpecPath | Full Path to a Swagger based JSON spec|
| Path            | Full Path to a folder where the commands/modules are exported to |
| ModuleName      | Name of the module to be generated. A folder with this name will be created in the location specified by Path parameter |
| SwaggerSpecUri  | URI to the swagger spec |

## Usage

Note: Please run this steps on a Windows 10 Anniversary Update or Windows Server 2016 RTM and above.

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

4. Run the following in a PowerShell console from the directory where you cloned PSSwagger in:

   ```powershell
   Import-Module .\PSSwagger.psd1
   $param = @{
       SwaggerSpecUri = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json'
       Path           = 'C:\Temp\generatedmodule\'
       ModuleName     = 'Generated.Azure.BatchManagement'
   }
   Export-CommandFromSwagger @param
   ```

After step 4, the module will be in `C:\Temp\GeneratedModule\Generated.Azure.BatchManagement ($param.Path)` folder.

Before importing that module and using it, you need to import `Generated.Azure.Common.Helpers` module which is under PSSwagger folder.

## Upcoming additions

1. Enabe PowerShell Best practices
   (a)	Using approved Verbs
   (b)	Verbs that change system like New/Update/Remove need to implement ShouldProcess (-WhatIf/-Confirm)
   (c)	Mapping properties to ValueFromPipeline semantics so that  Get-<Noun> | Remove-<Noun>  (and other pipeline scenarios) work.
   (d)	Long running operations need to have -AsJob variants and use *-Job cmdlets for further processing.
2. Representing complex objects as parameters
3. Identifying / driving common extensions in Swagger not just MAS but for entire PowerShell ecosystem.
4. Test Cases
5. Make generated cmdlets work with PowerShell Core on Linux / Mac

## Notes

1. Swagger Specification is at: http://swagger.io/specification/
2. Azure ARM based Swagger documents at: https://github.com/Azure/azure-rest-api-specs
