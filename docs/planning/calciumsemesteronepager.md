# PSSwagger work in a nutshell for Calcium semester

## Enable teams/users to generate PS Cmdlets for new Azure/MAS services or any RESTful web services

- Support for automatic test server

- Azure CI/CD pipeline integration
  - Implement a PowerShell script to bootstrap the PSSwagger and its helper modules to the Azure PowerShell Repository clone.
  - Add support for leveraging the pre-generated C# SDK assemblies in New-PSSwaggerModule cmdlet.
  - Integrate with https://github.com/Azure/azure-powershell CI/CD pipeline to generate and test the PowerShell cmdlets for Azure Swagger documents (https://github.com/Azure/azure-rest-api-specs) and leverage the corresponding generated SDK assemblies from https://github.com/Azure/azure-sdk-for-net repository.

## Support PS Extensions

### Cmdlets

#### New-PSSwaggerMetadataFile

- [New-PSSwaggerMetadataFile](../commands/New-PSSwaggerMetadataFile.md)

#### Test-PSSwaggerMetadataFile

- Returns true or false based on validity of the PS Metadata.
- Checks whether all Swagger paths, operations, definitions, parameters/property names exist in both Swagger spec and it's psmeta.json file.
- This cmdlet will use New-PSSwaggerMetadataFile cmdlet with current spec copied to a temporary folder.
  After creating the psmeta.json file, this file at temporary folder will be used to compare the contents of current psmeta.json file.
- With -Detailed switch parameter on this cmdlet user can get more details, like
  - What is missing (includes newly added and removed) for Paths, Operations, Parameters, Definitions, Properties, Global parameters, module info and code-generation settings, etc.
  - What key properties are invalid like empty value for param/cmdlet name.
  - These details are in hierarchical order as in psmeta file.
  - An additional property will be added with current metadata (psmeta.json).
- Detailed output will have a property to indicate missing fields of the PS Extensions, if any.
- Detailed output will have a property to indicate deprecated fields of the PS Extensions, if any.
- Output format view will be added for displaying the detailed output on PS Console.
- Supports pipeline input.
- Cmdlet syntax
  ```powershell
  Test-PSSwaggerMetadataFile [-SwaggerSpecPath] <string> [-Detailed]
  ```

#### Update-PSSwaggerMetadataFile

- This cmdlet updates psmeta file as per the latest contents of Swagger spec.
- Removes missing elements and adds newly added elements as per new swagger spec to the psmeta file for Paths, Operations, Parameters, Definitions, Properties, Global parameters, module info and code-generation settings, etc.
- High level logic
  - Runs Test-ModuleManifest cmdlet with -Detailed switch to check if there are any missing/new metadata.
  - Detailed output will be used to update the psmeta.json file.
  - New keys will be added and missing keys will be removed from the psmeta.json
  - Runs Test-ModuleManifest cmdlet again to ensure that generated psmeta file is valid.
- Supports pipeline input.
- Supports ShouldProcess functionality (-Confirm and -WhatIf).
- Cmdlet syntax
  ```powershell
  Update-PSSwaggerMetadataFile [-SwaggerSpecPath] <string> [-Force] [-WhatIf] [-Confirm]
  ```

#### Support PS Extensions in New-PSSwaggerModule cmdlet

- If .psmeta file exists, Test-PSSwaggerMetadataFile cmdlet will be used with -Detailed switch to validate and get the detailed psmeta details.
- If swagger document contains PS Extensions, PowerShell Metadata extraction logic will give preference to PS Extensions, otherwise there will be no change to the existing implementation.
- This extracted psmeta will be used in preparation of module, cmdlet, parameter, code generation settings, output formats, etc., metadata.

#### Integration of PS Extensions with VS, VS Code and MSSwagger

## Making PSSwagger public

- Cmdlet review for three PSSwagger modules and incorporate the feedback
  - PSSwagger.Common.Helpers
  - PSSwagger.Azure.Helpers
  - PSSwagger
- Documentation update/cleanup for all cmdlets, modules and readme.md
- CI/CD pipeline integration
  - AppVeyor
    - Windows PowerShell
    - PowerShell Core
  - Travis CI
- Publishing to the PSGallery
  - Implement required automation logic for publishing the modules to PSGallery from master branch.

## Engineering quality/fundamentals

- Current list of PSSwagger issues with Common and Engineering labels will be enabled/fixed in this semester after triage.
  - [Engineering issues](https://github.com/PowerShell/PSSwagger/issues?q=is%3Aopen+is%3Aissue+label%3AEngineering)
  - [Common issues](https://github.com/PowerShell/PSSwagger/issues?q=is%3Aopen+is%3Aissue+label%3ACommon)