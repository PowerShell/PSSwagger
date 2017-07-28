---
external help file: PSSwagger-help.xml
online version: 
schema: 2.0.0
---

# New-PSSwaggerModule

## SYNOPSIS
PowerShell command to generate the PowerShell commands for a given RESTful Web Services using Swagger/OpenAPI documents.

## SYNTAX

### SwaggerPath
```
New-PSSwaggerModule -SpecificationPath <String> -Path <String> -Name <String> [-Version <Version>]
 [-DefaultCommandPrefix <String>] [-UseAzureCsharpGenerator] [-NoAssembly] [-PowerShellCorePath <String>]
 [-IncludeCoreFxAssembly] [-InstallToolsForAllUsers] [-TestBuild] [-SymbolPath <String>] [-ConfirmBootstrap]
```

### SwaggerURI
```
New-PSSwaggerModule -SpecificationUri <Uri> -Path <String> -Name <String> [-Version <Version>]
 [-DefaultCommandPrefix <String>] [-UseAzureCsharpGenerator] [-NoAssembly] [-PowerShellCorePath <String>]
 [-IncludeCoreFxAssembly] [-InstallToolsForAllUsers] [-TestBuild] [-SymbolPath <String>] [-ConfirmBootstrap]
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
Parameter Sets: SwaggerPath
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
Parameter Sets: SwaggerURI
Aliases: 

Required: True
Position: Named
Default value: None
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

### -UseAzureCsharpGenerator
Switch to specify whether AzureCsharp code generator is required.
By default, this command uses CSharp code generator.

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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

