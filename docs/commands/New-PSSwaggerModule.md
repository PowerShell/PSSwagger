---
external help file: PSSwagger-help.xml
online version: 
schema: 2.0.0
---

# New-PSSwaggerModule

## SYNOPSIS
PowerShell command to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

## SYNTAX

### SpecificationPath (Default)
```
New-PSSwaggerModule -SpecificationPath <String> -Path <String> -Name <String> [-Version <Version>]
 [-NoVersionFolder] [-DefaultCommandPrefix <String>] [-Header <String[]>] [-UseAzureCsharpGenerator]
 [-NoAssembly] [-PowerShellCorePath <String>] [-IncludeCoreFxAssembly] [-InstallToolsForAllUsers] [-TestBuild]
 [-SymbolPath <String>] [-ConfirmBootstrap] [-Formatter <String>]
```

### SdkAssemblyWithSpecificationPath
```
New-PSSwaggerModule -SpecificationPath <String> -Path <String> -AssemblyFileName <String>
 [-ClientTypeName <String>] [-ModelsName <String>] -Name <String> [-Version <Version>] [-NoVersionFolder]
 [-DefaultCommandPrefix <String>] [-Header <String[]>] [-UseAzureCsharpGenerator][-Formatter <String>]
```

### SdkAssemblyWithSpecificationUri
```
New-PSSwaggerModule -SpecificationUri <Uri> [-Credential <PSCredential>] [-UseDefaultCredential] -Path <String>
 -AssemblyFileName <String> [-ClientTypeName <String>] [-ModelsName <String>] -Name <String>
 [-Version <Version>] [-NoVersionFolder] [-DefaultCommandPrefix <String>] [-Header <String[]>]
 [-UseAzureCsharpGenerator] [-Formatter <String>]
```

### SpecificationUri
```
New-PSSwaggerModule -SpecificationUri <Uri> [-Credential <PSCredential>] [-UseDefaultCredential] -Path <String>
 -Name <String> [-Version <Version>] [-NoVersionFolder] [-DefaultCommandPrefix <String>] [-Header <String[]>]
 [-UseAzureCsharpGenerator] [-NoAssembly] [-PowerShellCorePath <String>] [-IncludeCoreFxAssembly]
 [-InstallToolsForAllUsers] [-TestBuild] [-SymbolPath <String>] [-ConfirmBootstrap] [-Formatter <String>]
```

## DESCRIPTION
PowerShell command to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-PSSwaggerModule -SpecificationUri 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-batch/2015-12-01/swagger/BatchManagement.json' -Path 'C:\GeneratedModules\' -Name 'AzBatchManagement' -UseAzureCsharpGenerator
```

Generates a PS Module for the specified SpecificationUri.

### -------------------------- EXAMPLE 2 --------------------------
```
New-PSSwaggerModule -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json' -Path 'C:\GeneratedModules\' -Name 'AzBatchManagement' -UseAzureCsharpGenerator
```

Generates a PS Module for the specified SpecificationPath.

## PARAMETERS

### -SpecificationPath
Full Path to a Swagger based JSON spec.

```yaml
Type: String
Parameter Sets: SpecificationPath, SdkAssemblyWithSpecificationPath
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpecificationUri
Uri to a Swagger based JSON spec.

```yaml
Type: Uri
Parameter Sets: SdkAssemblyWithSpecificationUri, SpecificationUri
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credential to use when the SpecificationUri requires authentication.
It will override -UseDefaultCredential when both are specified at the same time.

```yaml
Type: PSCredential
Parameter Sets: SdkAssemblyWithSpecificationUri, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDefaultCredential
Use default credentials to download the SpecificationUri.
Overridden by -Credential when both are specified at the same time.

```yaml
Type: SwitchParameter
Parameter Sets: SdkAssemblyWithSpecificationUri, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Full Path to a file where the commands are exported to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssemblyFileName
File name of the pre-compiled SDK assembly.
This assembly along with its dependencies should be available in '.\ref\fullclr\' folder under the target module version base path ($Path\$Name\$Version\\).
If your generated module needs to work on PowerShell Core, place the coreclr assembly along with its dependencies under '.\ref\coreclr\' folder under the target module version base path ($Path\$Name\$Version\\).
For FullClr, the specified assembly should be available at "$Path\$Name\$Version\ref\fullclr\$AssemblyFileName".
For CoreClr, the specified assembly should be available at "$Path\$Name\$Version\ref\coreclr\$AssemblyFileName".

```yaml
Type: String
Parameter Sets: SdkAssemblyWithSpecificationPath, SdkAssemblyWithSpecificationUri
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientTypeName
Client type name in the pre-compiled SDK assembly.
Specify if client type name is different from the value of 'Title' field from the input specification, or
if client type namespace is different from the specified namespace in the specification.
It is recommended to specify the fully qualified client type name.

```yaml
Type: String
Parameter Sets: SdkAssemblyWithSpecificationPath, SdkAssemblyWithSpecificationUri
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModelsName
Models name if it is different from default value 'Models'.
It is recommended to specify the custom models name in using x-ms-code-generation-settings extension in specification.

```yaml
Type: String
Parameter Sets: SdkAssemblyWithSpecificationPath, SdkAssemblyWithSpecificationUri
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the module to be generated.
A folder with this name will be created in the location specified by Path parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
Version of the generated PowerShell module.

```yaml
Type: Version
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 0.0.1
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoVersionFolder
Switch to not create the version folder under the generated module folder.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultCommandPrefix
Prefix value to be prepended to cmdlet noun or to cmdlet name without verb.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header
Text to include as a header comment in the PSSwagger generated files.
It also can be a path to a .txt file with the content to be added as header in the PSSwagger generated files.

Supported predefined license header values:
- NONE: Suppresses the default header.
- MICROSOFT_MIT: Adds predefined Microsoft MIT license text with default PSSwagger code generation header content.
- MICROSOFT_MIT_NO_VERSION: Adds predefined Microsoft MIT license text with default PSSwagger code generation header content without version.
- MICROSOFT_MIT_NO_CODEGEN: Adds predefined Microsoft MIT license text without default PSSwagger code generation header content.
- MICROSOFT_APACHE: Adds predefined Microsoft Apache license text with default PSSwagger code generation header content.
- MICROSOFT_APACHE_NO_VERSION: Adds predefined Microsoft Apache license text with default PSSwagger code generation header content without version.
- MICROSOFT_APACHE_NO_CODEGEN: Adds predefined Microsoft Apache license text without default PSSwagger code generation header content.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAzureCsharpGenerator
Switch to specify whether AzureCsharp code generator is required.
By default, this command uses CSharp code generator.

When this switch is specified and the resource id follows the guidelines of Azure Resource operations
- The following additional parameter sets will be generated
  - InputObject parameter set with the same object type returned by Get.
Supports piping from Get operarion to action cmdlets.
  - ResourceId parameter set which splits the resource id into component parts (supports piping from generic cmdlets).
- Parameter name of Azure resource name parameter will be generated as 'Name' and the actual resource name parameter from the resource id will be added as an alias.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAssembly
Switch to disable saving the precompiled module assembly and instead enable dynamic compilation.

```yaml
Type: SwitchParameter
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerShellCorePath
Path to PowerShell.exe for PowerShell Core.
Only required if PowerShell Core not installed via MSI in the default path.

```yaml
Type: String
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeCoreFxAssembly
Switch to additionally compile the module's binary component for Core CLR.

```yaml
Type: SwitchParameter
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallToolsForAllUsers
User wants to install local tools for all users.

```yaml
Type: SwitchParameter
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestBuild
Switch to disable optimizations during build of full CLR binary component.

```yaml
Type: SwitchParameter
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SymbolPath
Path to save the generated C# code and PDB file.
Defaults to $Path\symbols.

```yaml
Type: String
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfirmBootstrap
Automatically consent to downloading nuget.exe or NuGet packages as required.

```yaml
Type: SwitchParameter
Parameter Sets: SpecificationPath, SpecificationUri
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Formatter
Specify a formatter to use. One of: 'None', 'PSScriptAnalyzer'
```yaml
Type: String
Parameter Sets: SpecificationPath, SpecificationUri, SdkAssemblyWithSpecificationPath, SdkAssemblyWithSpecificationUri
Aliases:

Required: False
Position: Named
Default value: 'None'
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

