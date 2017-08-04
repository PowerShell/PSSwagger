---
external help file: PSSwagger-help.xml
online version: 
schema: 2.0.0
---

# New-PSSwaggerMetadataFile

## SYNOPSIS
Creates PowerShell Metadata json file with PowerShell Extensions for the specified Swagger document.

## SYNTAX

```
New-PSSwaggerMetadataFile [-SpecificationPath] <String> [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Creates PowerShell Metadata json file with PowerShell Extensions for the specified Swagger document.
This file can be used to customize the PowerShell specific metadata like 
cmdlet name, parameter name, output format views, code generation settings, PowerShell Module metadata and other related metadata.
PowerShell Metadata file name for \<SwaggerSpecFileName\>.json is \<SwaggerSpecFileName\>.psmeta.json.
This \<SwaggerSpecFileName\>.psmeta.json file gets created under the same location as the specified swagger document path.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-PSSwaggerMetadataFile -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json'
```

Generates 'C:\SwaggerSpecs\BatchManagement.psmeta.json' file with PowerShell extensions for customizing the PowerShell related metadata.

### -------------------------- EXAMPLE 2 --------------------------
```
New-PSSwaggerMetadataFile -SpecificationPath 'C:\SwaggerSpecs\BatchManagement.json' -Force
```

Regenerates 'C:\SwaggerSpecs\BatchManagement.psmeta.json' file with PowerShell extensions for customizing the PowerShell related metadata.

## PARAMETERS

### -SpecificationPath
Full Path to a Swagger based JSON spec.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Force
To replace the existing PowerShell Metadata file.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

