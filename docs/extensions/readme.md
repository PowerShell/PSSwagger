# PowerShell Extensions

## Introduction
The following document describes PowerShell extensions for [OpenApi (Swagger) 2.0](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md) schema.
These extensions are used in the additional metadata file (Ex: _servicename_**.PSMeta.json**) for specifying the PowerShell specific metadata (like module, cmdlet, parameter and output format specific extended metadata).
These can also be used in the Swagger/OpenApi document.

## Extensions
* [x-ps-code-generation-settings](#x-ps-code-generation-settings) - enables passing PowerShell code generation settings via psmeta document or swagger document.
* [x-ps-module-info](#x-ps-module-info) - enables passing PowerShell Module manifest values via PSMeta document or Swagger/OpenApi document.
* [x-ps-cmdlet-infos](#x-ps-cmdlet-infos) - enables customization of generated commands for an operation.
* [x-ps-parameter-info](#x-ps-parameter-info) - enables customization for generated command parameters.
* [x-ps-output-format-info](#x-ps-output-format-info) - enables customization of output format views.



## x-ps-code-generation-settings
`x-ps-code-generation-settings` extension on `info` element enables passing PowerShell code generation settings via PSMeta document or Swagger/OpenApi document.

**Parent element**: [Info Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#infoObject)

**Schema**: 

Field Name | Type | Description
---|:---:|---
codeGenerator | `string` | Allowed values are "AzureCsharp" and "Csharp". If not specified, default is Csharp.
path | `string` | Full Path to a folder where the commands/modules are exported to. MUST be a valid path either absolute or relative.
noAssembly | `bool` | Boolean to specify whether the generated assemblies are copied under the generated module. Enables dynamic compilation scenario.
PowerShellCorePath | `string` | Path to PowerShell.exe for PowerShell Core. Only required if not installed via MSI in the default path. MUST be a valid path either absolute or relative.
includeCoreFxAssembly | `bool` | Boolean to additionally compile the module's binary component for core CLR.
testBuild | `bool` | Boolean to enable debug compilation of full CLR binary component. Effects: disables compiler optimization.
symbolPath | `string` | Path that will contain the generated module's generated code and corresponding PDB file. Defaults to $Path\symbols if not specified. MUST be a valid path either absolute or relative.
confirmBootstrap | `bool` | Specify true to automatically consent to downloading NuGet.exe or NuGet packages as required.
additionalFilesPath | `string` | Location of custom files path. MUST be a valid path either absolute or relative.
serviceType | `string` | One of 'azure' or 'azure_stack', if this service is an Azure or AzureStack service, respectively. Specifying this value customizes the resulting module for these services.
customAuthCommand | `string` | Specify a PowerShell cmdlet that should return a Microsoft.Rest.ServiceClientCredentials object that implements custom authentication logic.
hostOverrideCommand | `string` | Specify a PowerShell cmdlet that should return a custom hostname string. Overrides the default host in the specification.
noAuthChallenge | `bool` | Specify true to indicate that the service will not offer an authentication challenge, such as adding the WWW-Authenticate header to a 401 response. Default is false.

**Note**: These field names are taken from New-PSSwaggerModule cmdlet parameters. These field names will be renamed as per the cmdlet review updates for New-PSSwaggerModule cmdlet.

**Example**:
```json5
"info": {
    "x-ps-code-generation-settings": {
        "codeGenerator": "AzureCsharp",
        "nameSpacePrefix": "Microsoft.PowerShell.",
        "additionalFilesPath": "C:\HandWrittenCustomFilesPath"
    }
}
```

## x-ps-module-info
`x-ps-module-info` extension on `info` element enables passing PowerShell Module manifest values via PSMeta document or Swagger/OpenApi document.

**Parent element**: [Info Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#infoObject)

**Schema**: 

Field Name | Type | Description
---|:---:|---
name| `string` | **Required**. Module name.
moduleVersion | `string` | **Required**. Module version.
description | `string` | **Required**. Module description.
author | `string` | **Required**. Module author.
guid | `string` | **Required**. Module guid. MUST be in the form of valid guid.
.*| `string` or `bool` | Field name should be a valid parameters of either New-ModuleManifest or Update-ModuleManifest cmdlets. Value should be a valid string value, boolean for switch parameters, must be proper URL as string value for URI types - e.g., licenseUri, or array of strings if a parameter supports array of strings - e.g., Tags.

**Example**:
```json5
"info": {
    "x-ps-module-info": {
        "name": "AzDocumentDB",
        "description": "Azure DocumentDB Database Service Resource Provider REST API",
        "moduleVersion": "2.4.23",
        "guid": "caec68a4-c968-4d9b-b8bb-50814e19dc71",
        "author": "manikb@microsoft.com",
        "companyName": "Microsoft Corporation",
        "tags": [
            "Swagger",
            "Azure",
            "DocDB"
        ],
        "licenseUri": "https://raw.githubusercontent.com/Azure/azure-powershell/dev/LICENSE.txt",
        "projectUri": "https://github.com/Azure/azure-powershell",
        "iconUri": "https://github.com/Azure/azure-powershell/moduleicon.png",
        "releaseNotes": "Release notes of this module version.",
        "defaultCommandPrefix": "AzDocDB",
        "helpInfoUri": "https://gofwdurl.com"
    }
}
```

## x-ps-cmdlet-infos
`x-ps-cmdlet-infos` extension on `operation` or `schema` element enables passing list of PowerShell Cmdlet metadata objects [x-ps-cmdlet-info objects](#x-ps-cmdlet-infoObject) via PSMeta document or Swagger/OpenApi document.

**Parent element**: [Operation Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#operationObject) | [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#schemaObject)

**Note**: In case of schema object, x-ps-cmdlet-info is ignored when the grandparent is not [Definition Object]
(https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#definitionsObject).

### <a name="x-ps-cmdlet-infoObject"></a>x-ps-cmdlet-info Object

**Schema**:

Field Name | Type | Description
---|:---:|---
name| `string` | **Required**. Name of PowerShell Cmdlet. When multiple swagger operations are combined into a single cmdlet, name should be same in other swagger operations without other metadata fields.
description | `string` | Description of PowerShell Cmdlet. If not specified, description of operation is used as the cmdlet description.
generateCommand | `bool` | Boolean to indicate whether a cmdlet is required or not. Default is true.
defaultParameterSet | `string` | String value to indicate whether the specified OperationId or Definition name as the default parameter set name when multiple Operations or definitions are merged into the same cmdlet, e.g., Get and List operationIds can be combined into single cmdlet.
generateOutputFormat | `bool` | Applicable to definitions only. Boolean to indicate whether output format file is required for this model type or not. Default value true.

**Examples**:
1. x-ps-cmdlet-infos on operation
```json5
{
    "paths": {
        "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}": {
            "put": {
                "operationId": "DatabaseAccounts_CreateOrUpdate",
                "description": "Creates or updates an Azure DocumentDB database account.",
                "x-ps-cmdlet-infos": [
                    {
                        "name": "New-DatabaseAccount",
                        "description": "Creates or updates an Azure DocumentDB database account.",
                        "generateCommand": true,
                        "defaultParameterSet": "DatabaseAccounts_CreateOrUpdate"
                    },
                    {
                        "name": "Set-DatabaseAccount",
                        "description": "Creates or updates an Azure DocumentDB database account.",
                        "generateCommand": true,
                        "defaultParameterSet": "DatabaseAccounts_CreateOrUpdate"
                    }
                ],
                "parameters": [
                    {
                        "$ref": "#/parameters/resourceGroupNameParameter"
                    },
                    {
                        "name": "createUpdateParameters",
                        "in": "body",
                        "required": true,
                        "schema": {
                            "$ref": "#/definitions/DatabaseAccountCreateUpdateParameters"
                        },
                        "description": "The parameters to provide for the current database account.",
                    }
                ]
            }
        }
    }
}
```
2. x-ps-cmdlet-infos on definition
```json5
{
    "definitions" : {
        "DatabaseAccount": {
            "description": "A DocumentDB database account.",
            "type": "object",
            "x-ps-cmdlet-infos": [
                {
                    "name": "New-DatabaseAccountObject",
                    "description": "A DocumentDB database account.",
                    "generateCommand": true,
                    "defaultParameterSet": "DatabaseAccount",
                    "generateOutputFormat": true
                }
            ],
            "properties": {
            }
        }
    }
}
```

## x-ps-parameter-info
`x-ps-parameter-info` extension on `parameter` element enables passing Parameter metadata via PSMeta document or Swagger/OpenApi document. This can be specified on parameter elements of operation, definition and global parameters.

**Parent element**: [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#parameterObject)

**Schema**:

Field Name | Type | Description
---|:---:|---
name| `string` | **Required**. Name of Cmdlet parameter.
description | `string` | Description of Cmdlet parameter.

**Examples**:

1. x-ps-parameter-info on operation
```json5
{
    "paths": {
        "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}": {
            "put": {
                "operationId": "DatabaseAccounts_CreateOrUpdate",
                "description": "Creates or updates an Azure DocumentDB database account.",
                "parameters": [
                    {
                        "$ref": "#/parameters/resourceGroupNameParameter"
                    },
                    {
                        "name": "createUpdateParameters",
                        "in": "body",
                        "required": true,
                        "schema": {
                            "$ref": "#/definitions/DatabaseAccountCreateUpdateParameters"
                        },
                        "description": "The parameters to provide for the current database account.",
                        "x-ps-parameter-info": {
                            "name": "CreateUpdateParameter",
                            "description": "The parameters to provide for the current database account."
                        }
                    }
                ]
            }
        }
    }
}
```

2. x-ps-parameter-info on definition parameters
```json5
{
    "definitions" : {
        "DatabaseAccount": {
            "description": "A DocumentDB database account.",
            "type": "object",
            "properties": {
                "kind": {
                    "description": "Indicates the type of database account. This can only be set at database account creation.",
                    "type": "string",
                    "default": "GlobalDocumentDB",
                    "enum": [
                        "GlobalDocumentDB",
                        "MongoDB",
                        "Parse"
                    ],
                    "x-ms-enum": {
                        "name": "DatabaseAccountKind",
                        "modelAsString": true
                    },
                    "x-ps-parameter-info": {
                        "name": "Kind",
                        "description": "Indicates the type of database account. This can only be set at database account creation."
                    }
                },
                "properties": {
                    "x-ms-client-flatten": true,
                    "$ref": "#/definitions/DatabaseAccountProperties"
                }
            }
        }
    }
}
```

3. x-ps-parameter-info on global parameters
```json5
{
    "parameters": {
        "subscriptionIdParameter": {
            "name": "subscriptionId",
            "in": "path",
            "description": "Azure subscription ID.",
            "required": true,
            "type": "string",
            "x-ps-parameter-info": {
                "name": "SubscriptionId",
                "description": "Azure subscription ID."
            }
        }
}
```

## x-ps-output-format-info
`x-ps-output-format-info` extension on `schema object` element under definition enables passing PowerShell output format metadata via PSMeta document or Swagger/OpenApi document.

**Parent element**: [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#schemaObject)

**Note**: x-ps-output-format-info is ignored when the grandparent is not [Definition Object]
(https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#definitionsObject).

**Schema**:

Field Name | Type | Description
---|:---:|---
include| `bool` | **Required**. Boolean to indicate whether this property should be included in the output format file.
postion | `int` | **Required**. Expected position of this property in output format.
width | `int` | **Required**. Expected width of this property in output format.

**Example**:
```json5
{
    "definitions" : {
        "DatabaseAccount": {
            "description": "A DocumentDB database account.",
            "type": "object",
            "properties": {
                "kind": {
                    "description": "Indicates the type of database account. This can only be set at database account creation.",
                    "type": "string",
                    "default": "GlobalDocumentDB",
                    "enum": [
                        "GlobalDocumentDB",
                        "MongoDB",
                        "Parse"
                    ],
                    "x-ms-enum": {
                        "name": "DatabaseAccountKind",
                        "modelAsString": true
                    },
                    "x-ps-output-format-info": {
                        "include": true,
                        "position": 0,
                        "width": 10
                    }
                },
                "properties": {
                    "x-ms-client-flatten": true,
                    "$ref": "#/definitions/DatabaseAccountProperties"
                }
            }
        }
    }
}
```
