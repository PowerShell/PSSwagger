# Changelog

## v0.3.0 - 2017-09-29
- Add support for generating proper output type for the Swagger operations with x-ms-pageable extension (#342)
- Add support for parameter type references to enum definitions (#341)
- Add support for AdditionalProperties Json schema with array type (#339)
- Generate SYNOPSIS help content in the generated cmdlets (#337)
- Rename IsOSX to IsMacOS after breaking change in PowerShell 6.0.0-beta.7 to fix #333 (#334)
- Resolve UnableToExtractDetailsFromSdkAssembly error when OperationType in OperationId conflicts with Definition name (#332)
- Change warninglevel to 1 for generating assembly for Azure Swagger specs (#331)
- Write exceptions in generated commands (#324)
- Add New-ServiceClient utility function in generated module to enable mock testing (#325)
- Add support for generating PowerShell cmdlets using pre-built SDK assembly and specification (#321)
- Add support for predefined header values (#320)
- Removing the langversion from CSC parameters as latest is the default language version (#318)
- Support latest version of AutoRest in PSSwagger (#313)
- Add support for generating the C# SDK assembly using CSC.exe on Windows PS (#312)
- Support default and customizable header comment for the PSSwagger generated files (#310)
- Ensure $oDataQuery expression is generated properly when a global parameter is referenced in more than one swagger operations with or without x-ms-odata extension (#307)
- Fix localization error in SwaggerUtil for PluralizationService  (#303)
- Update Readme and fix an error related to importing the PSSwaggerUtility module (#300)
- Support custom x-ms-pageable\NextLinkName field name (#294)

## v0.2.0 - 2017-08-15

* First preview release

    First preview release of PSSwagger and PSSwaggerUtility modules. While the goal is to support all web APIs, scenarios are focused on Microsoft Azure for this first release.

* Supported Scenarios
  - From an Open API v2 specification, generate a PowerShell module using [Azure AutoRest](https://github.com/azure/autorest)
        - Generating modules is only supported on PowerShell 5.1
  - Customize the generation process with Open API v2 extensions in either the same specification as your web API or a separate file
    - Rename automatically generated cmdlets
    - Flatten complex parameters without flattening the underlying .NET API
  - Generated modules support PowerShell on Windows (PowerShell 4 or greater) or PowerShell Core on Windows, Linux or Mac
  - Compile the underlying .NET API before you publish your module or compile it on-the-fly on your end-user's machine
  - Debugging symbols for underlying .NET API available
  - Currently supported authentication schemes:
      - Basic authentication, with or without challenge
      - API key based authentication
      - No authentication
      - Authentication using AzureRM.Profile