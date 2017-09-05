// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using Credentials;
    using Interfaces;
    using Json;
    using Logging;
    using Messages;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Serialization;
    using PostProcessors;
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.Linq;
    using System.Reflection;

    /// <summary>
    /// Contains metadata for a generated module being tested.
    /// </summary>
    public class GeneratedModule
    {
        private IRunspaceManager runspace;
        private Dictionary<string, RuntimeTypeData> definitionsCache;

        public string ModulePath { get; set; }

        public IList<GeneratedModule> RequiredModules { get; private set; }

        public IDictionary<string, OperationData> Operations { get; private set; }

        public Logger Logger { get; set; }

        public GeneratedModule(IRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.RequiredModules = new List<GeneratedModule>();
            this.Operations = new Dictionary<string, OperationData>();
            this.definitionsCache = new Dictionary<string, RuntimeTypeData>();
        }

        public virtual void LoadMetadataFromSpecification(JsonPathFinder jsonPathFinder)
        {
            Log("Begin loading metadata from specification.");
            // 1. Parse definitions into RuntimeTypeData's
            JsonPathFinder definitionsNode = jsonPathFinder.Find(new JsonQueryBuilder().Property("definitions")).SingleOrDefault();
            if (definitionsNode != null)
            {
                foreach (JsonPathFinder definitionContainerNode in definitionsNode.Children())
                {
                    JsonPathFinder definitionNode = definitionContainerNode.OpenContainer();
                    string definitionPath = definitionNode.Path;
                    this.definitionsCache[definitionPath] = GetRuntimeTypeDataFromDefinition(definitionPath, definitionNode, this.definitionsCache, jsonPathFinder);
                }
            }

            // 2. Get ParameterData from global parameters
            JsonPathFinder globalParametersNode = jsonPathFinder.Find("parameters").SingleOrDefault();
            Dictionary<string, Dictionary<string, ParameterData>> globalParameterCache = new Dictionary<string, Dictionary<string, ParameterData>>();
            if (globalParametersNode != null)
            {
                foreach (JsonPathFinder globalParameterContainerNode in globalParametersNode.Children())
                {
                    JsonPathFinder globalParameter = globalParameterContainerNode.Children().First();
                    string parameterPath = globalParameter.Path;
                    globalParameterCache[parameterPath] = GetParameterMetadata(parameterPath, globalParameter, this.definitionsCache, globalParameterCache, jsonPathFinder);
                }
            }

            // 3. Parse operations
            ParseOperationsForMetadata(jsonPathFinder, this.definitionsCache, globalParameterCache);
            
            Log("Finished loading metadata from specification.");
        }

        /// <summary>
        /// Runs all operations that need to take place after all metadata is loaded from all specifications.
        /// </summary>
        public void CompleteMetadataLoad()
        {
            foreach (ParameterData parameterData in this.Operations.Values.SelectMany(od => od.Parameters.Values))
            {
                // Top-level parameters should have type filled in
                CompleteRuntimeDataType(parameterData.Type);
            }

            foreach (OperationData data in this.Operations.Values.Where(od => od.ResponseType != null))
            {
                // Make sure each response is properly merged
                data.ResponseType.Complete();

                // Then fill in subtypes
                CompleteRuntimeDataType(data.ResponseType.TypeData);

                // Create AzurePagePostProcessor if required
                if (data.ResponseType.PageType != null)
                {
                    data.PostProcessors.Add(new AzurePagePostProcessor(new AzurePageType(data.ResponseType.PageType, data.ResponseType.TypeData.Type)));
                }
            }
        }

        private void CompleteRuntimeDataType(RuntimeTypeData data)
        {
            // At this point, data should have its Type filled in. In case it isn't, let's let an exception bubble up as an error
            Type netType = data.Type;
            Dictionary<string, Type> propertyTypes = new Dictionary<string, Type>();
            foreach (PropertyInfo pi in netType.GetProperties())
            {
                propertyTypes[pi.Name.ToLowerInvariant()] = pi.PropertyType;
            }

            foreach (string propertyName in data.Properties.Keys)
            {
                ParameterData propertyData = data.Properties[propertyName];
                if (propertyData.Type != null)
                {
                    // Sometimes the Name property isn't set - propertyName is correct in this case
                    if (String.IsNullOrEmpty(propertyData.Name))
                    {
                        propertyData.Name = propertyName;
                    }

                    RuntimeTypeData propertyTypeData = propertyData.Type;
                    if (propertyTypeData.Type == null)
                    {
                        // Find the type of this property
                        if (propertyTypes.ContainsKey(propertyName))
                        {
                            propertyTypeData.Type = propertyTypes[propertyName];
                            // Recursively fill in the properties of this type
                            CompleteRuntimeDataType(propertyTypeData);
                        }
                    }
                }
            }
        }

        private void ParseOperationsForMetadata(JsonPathFinder rootDoc, Dictionary<string, RuntimeTypeData> definitionsCache, Dictionary<string, Dictionary<string, ParameterData>> parameterCache)
        {
            // Find each path item
            JsonPathFinder paths = rootDoc.Find("paths").SingleOrDefault();
            if (paths != null)
            {
                foreach (JsonPathFinder pathItemNode in paths.Children())
                {
                    ParsePathItemForMetadata(pathItemNode.OpenContainer(), definitionsCache, parameterCache, rootDoc);
                }
            }

            JsonPathFinder extendedPaths = rootDoc.Find("x-ms-paths").SingleOrDefault();
            if (extendedPaths != null)
            {
                foreach (JsonPathFinder pathItemNode in extendedPaths.Children())
                {
                    ParsePathItemForMetadata(pathItemNode.OpenContainer(), definitionsCache, parameterCache, rootDoc);
                }
            }
        }

        private void ParsePathItemForMetadata(JsonPathFinder pathItem, Dictionary<string, RuntimeTypeData> definitionsCache, Dictionary<string, Dictionary<string, ParameterData>> parameterCache, JsonPathFinder rootDoc)
        {
            // Parse path item level parameters first
            JsonPathFinder pathLevelParameters = pathItem.Find(new JsonQueryBuilder().Property("parameters")).SingleOrDefault();
            List<Dictionary<string, ParameterData>> pathLevelParameterList = new List<Dictionary<string, ParameterData>>();
            if (pathLevelParameters != null)
            {
                foreach (JsonPathFinder parameterNode in pathLevelParameters.Children())
                {
                    Dictionary<string, ParameterData> parameters = GetParameterMetadata(parameterNode.Path, parameterNode, definitionsCache, parameterCache, rootDoc);
                    pathLevelParameterList.Add(parameters);
                }
            }

            // Parse each path (all children that are not keyed by "$ref" or "parameters")
            foreach (JsonPathFinder operationContainerNode in pathItem.Children().Where(n => String.IsNullOrEmpty(n.Key) || (!n.Key.Equals("parameters") && !n.Key.Equals("$ref"))))
            {
                // Get parameter metadata from the operation
                OperationData operationData = ParseOperationForMetadata(operationContainerNode.OpenContainer(), definitionsCache, parameterCache, rootDoc);
                // Apply the path item level parameter data to this operation
                if (operationData != null)
                {
                    Log(String.Format(CultureInfo.InvariantCulture, "Applying path level parameters to operation '{0}'", operationData.OperationId));
                    foreach (Dictionary<string, ParameterData> parametersSet in pathLevelParameterList)
                    {
                        foreach (string parameterName in parametersSet.Keys)
                        {
                            if (operationData.Parameters.ContainsKey(parameterName.ToLowerInvariant()))
                            {
                                Log(String.Format(CultureInfo.InvariantCulture, "Found parameter with name '{0}' and JSON name '{1}'", parameterName, parametersSet[parameterName].JsonName));
                                operationData.Parameters[parameterName.ToLowerInvariant()].MergeWith(parametersSet[parameterName]);
                            }
                        }
                    }
                }
            }

            // TODO: Currently no support for path item using $ref
        }

        private OperationData ParseOperationForMetadata(JsonPathFinder path, Dictionary<string, RuntimeTypeData> definitionsCache, Dictionary<string, Dictionary<string, ParameterData>> parameterCache, JsonPathFinder rootDoc)
        {
            JsonPathFinder parametersNode = path.Find(new JsonQueryBuilder().Property("parameters")).SingleOrDefault();
            JsonPathFinder operationIdNode = path.Find(new JsonQueryBuilder().Property("operationId")).SingleOrDefault();
            if (operationIdNode == null)
            {
                return null;
            }

            string operationId = operationIdNode.GetValue<string>();
            if (!this.Operations.ContainsKey(operationId.ToLowerInvariant()))
            {
                Log(String.Format(CultureInfo.InvariantCulture, "Skipping operation '{0}' because no matching command was found.", operationId));
                return null;
            }

            OperationData operationData = this.Operations[operationId.ToLowerInvariant()];
            Log(String.Format(CultureInfo.InvariantCulture, "Loading metadata for operation '{0}' and command '{1}'", operationId, operationData.Command));

            if (parametersNode != null)
            {
                foreach (JsonPathFinder parameterNode in parametersNode.Children())
                {
                    Dictionary<string, ParameterData> parameters = GetParameterMetadata(parameterNode.Path, parameterNode, definitionsCache, parameterCache, rootDoc);
                    foreach (string parameterName in parameters.Keys)
                    {
                        if (operationData.Parameters.ContainsKey(parameterName.ToLowerInvariant()))
                        {
                            Log(String.Format(CultureInfo.InvariantCulture, "Found parameter with name '{0}' and JSON name '{1}'", parameterName, parameters[parameterName].JsonName));
                            operationData.Parameters[parameterName.ToLowerInvariant()].MergeWith(parameters[parameterName]);
                        }
                    }
                }
            }

            // Find the first response in the [200-299] range, as that's all PSSwagger supports right now
            JsonPathFinder responsesNode = path.Find(new JsonQueryBuilder().Property("responses")).SingleOrDefault();
            string responseDefinitionPath = null;
            if (responsesNode != null && operationData.ResponseType != null)
            {
                foreach (JsonPathFinder response in responsesNode.Children())
                {
                    int statusCode;
                    if (Int32.TryParse(response.Key, out statusCode) && statusCode >= 200 && statusCode <= 299)
                    {
                        // For now we only support ref'd schema - need to fix that
                        JsonPathFinder schemaRefNode = response.Find(new JsonQueryBuilder().RecursiveDescent().Property("$ref")).SingleOrDefault();
                        if (schemaRefNode != null)
                        {
                            responseDefinitionPath = schemaRefNode.GetValue<string>();
                            string definitionPathCaseInsensitive = responseDefinitionPath.ToLowerInvariant();
                            if (definitionsCache.ContainsKey(definitionPathCaseInsensitive))
                            {
                                operationData.ResponseType.SpecificationData.Add(definitionsCache[definitionPathCaseInsensitive]);
                                break;
                            }
                        }
                    }
                }
            }

            // Check for x-ms-pageable and set the page type if a response type exists
            JsonPathFinder pageableExtension = path.Find(new JsonQueryBuilder().Property("x-ms-pageable")).SingleOrDefault();
            if (pageableExtension != null && operationData.ResponseType != null)
            {
                string nextLinkJsonName = "nextLink";
                string itemsJsonName = "value";
                JsonPathFinder nextLinkName = pageableExtension.Find(new JsonQueryBuilder().RecursiveDescent().Property("nextLinkName")).SingleOrDefault();
                JsonPathFinder itemName = pageableExtension.Find(new JsonQueryBuilder().RecursiveDescent().Property("itemName")).SingleOrDefault();
                if (nextLinkName != null)
                {
                    nextLinkJsonName = nextLinkName.GetValue<string>();
                }

                if (itemName != null)
                {
                    itemsJsonName = itemName.GetValue<string>();
                }

                // Assuming the module is already loaded, find the correct .NET type for the Page
                foreach (Type candidateType in AppDomain.CurrentDomain.GetAssemblies().SelectMany(asm => asm.GetTypes()))
                {
                    PropertyInfo itemsProperty = candidateType.GetProperties(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance).Where(pi => pi.Name.Equals("Items")).FirstOrDefault();
                    PropertyInfo nextPageLinkProperty = candidateType.GetProperties(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance).Where(pi => pi.Name.Equals("NextPageLink")).FirstOrDefault();
                    bool candidate = true;
                    if (itemsProperty != null)
                    {
                        JsonPropertyAttribute jsonPropertyAttribute = (JsonPropertyAttribute)itemsProperty.GetCustomAttribute(typeof(JsonPropertyAttribute));
                        if (jsonPropertyAttribute == null || !jsonPropertyAttribute.PropertyName.Equals(itemsJsonName, StringComparison.OrdinalIgnoreCase))
                        {
                            candidate = false;
                        }
                    } else
                    {
                        candidate = false;
                    }

                    if (candidate && nextPageLinkProperty != null)
                    {
                        JsonPropertyAttribute jsonPropertyAttribute = (JsonPropertyAttribute)nextPageLinkProperty.GetCustomAttribute(typeof(JsonPropertyAttribute));
                        if (jsonPropertyAttribute == null || !jsonPropertyAttribute.PropertyName.Equals(nextLinkJsonName, StringComparison.OrdinalIgnoreCase))
                        {
                            candidate = false;
                        }
                    }
                    else
                    {
                        candidate = false;
                    }

                    if (candidate)
                    {
                        operationData.ResponseType.PageType = candidateType;
                    }
                }

                // Find the correct specification data. If x-ms-pageable is used, the referenced output type is probably an array of items
                // And PSSwagger will output the individual item type rather than the array type
                // Set the output type of the individual item type
                if (!String.IsNullOrEmpty(responseDefinitionPath))
                {
                    JsonPathFinder responseDefinitionNode = rootDoc.Find(new JsonQueryBuilder(responseDefinitionPath)).SingleOrDefault();
                    if (responseDefinitionNode != null)
                    {
                        JsonPathFinder itemType = responseDefinitionNode.Find(new JsonQueryBuilder().RecursiveDescent().Property("$ref")).FirstOrDefault();
                        if (itemType != null)
                        {
                            operationData.ResponseType.SpecificationData.Add(definitionsCache[itemType.GetValue<string>().ToLowerInvariant()]);
                        }
                    }
                }
            }

            return operationData;
        }

        private Dictionary<string, ParameterData> GetParameterMetadata(string parameterPath, JsonPathFinder parameter, Dictionary<string, RuntimeTypeData> definitionsCache, Dictionary<string, Dictionary<string, ParameterData>> parameterCache, JsonPathFinder rootDoc)
        {
            if (parameterCache.ContainsKey(parameterPath))
            {
                // We've already transformed this parameter into one or more parameters and found the correct module name
                return parameterCache[parameterPath];
            }

            Dictionary<string, ParameterData> ret = new Dictionary<string, ParameterData>();
            parameterCache[parameterPath] = ret;
            // 1. Check if it's a ref
            JsonPathFinder refNode = parameter.Find(new JsonQueryBuilder().Property("$ref")).SingleOrDefault();
            if (refNode != null)
            {
                // A direct ref should reference a parameter object
                string refParameterPath = refNode.GetValue<string>();
                return GetParameterMetadata(refParameterPath.ToLowerInvariant(), rootDoc.Find(new JsonQueryBuilder(refParameterPath)).Single(), definitionsCache, parameterCache, rootDoc);
            }
            else
            {
                // 2. Get the name and jsonName
                string jsonName = String.Empty;
                string clientName = String.Empty;
                JsonPathFinder jsonNameNode = parameter.Find(new JsonQueryBuilder().Property("name")).SingleOrDefault();
                JsonPathFinder clientNameNode = parameter.Find(new JsonQueryBuilder().Property("x-ms-client-name")).SingleOrDefault();
                if (jsonNameNode != null)
                {
                    jsonName = jsonNameNode.GetValue<string>().ToLowerInvariant();
                }

                if (clientNameNode != null)
                {
                    clientName = clientNameNode.GetValue<string>().ToLowerInvariant();
                }

                // 2. Check if it's a flatten
                JsonPathFinder flattenNode = parameter.Find(new JsonQueryBuilder().Property("x-ms-client-flatten")).SingleOrDefault();
                JsonPathFinder schemaRefNode = parameter.Find(new JsonQueryBuilder().RecursiveDescent().Property("$ref")).SingleOrDefault();
                if (flattenNode != null)
                {
                    // Get the ref node under the schema node - using recursive descent from the parameter node should work
                    // This should be a definitions object
                    string definitionPath = schemaRefNode.GetValue<string>();
                    RuntimeTypeData definitionData = definitionsCache[definitionPath];
                    // Don't think there will be a flatten of an object that's just an array?
                    foreach (string propertyName in definitionData.Properties.Keys)
                    {
                        ParameterData data = definitionData.Properties[propertyName];
                        if (!String.IsNullOrEmpty(data.Name))
                        {
                            ret[data.Name] = data;
                        }
                        else
                        {
                            ret[data.JsonName] = data;
                        }
                    }
                } else
                {
                    // 3. Just a regular parameter - check if it defines a definition as the type
                    ParameterData data = new ParameterData();
                    data.Name = clientName;
                    data.JsonName = jsonName;
                    if (schemaRefNode != null)
                    {
                        string definitionPath = schemaRefNode.GetValue<string>().ToLowerInvariant();
                        data.Type = definitionsCache[definitionPath];
                    } else
                    {
                        // Type with no properties, and the Type itself will be filled in later
                        data.Type = new RuntimeTypeData();
                    }

                    if (!String.IsNullOrEmpty(clientName))
                    {
                        ret[clientName] = data;
                    } else
                    {
                        ret[jsonName] = data;
                    }
                }
            }

            return ret;
        }

        private RuntimeTypeData GetRuntimeTypeDataFromDefinition(string definitionName, JsonPathFinder definitionNode, Dictionary<string, RuntimeTypeData> cache, JsonPathFinder rootDoc)
        {
            // 0. Check if the type already exists
            if (cache.ContainsKey(definitionName))
            {
                return cache[definitionName];
            }

            RuntimeTypeData data = new RuntimeTypeData();
            cache[definitionName] = data;
            // 1. Get properties node
            JsonPathFinder propertiesNode = definitionNode.Find(new JsonQueryBuilder().Property("properties")).SingleOrDefault();
            if (propertiesNode != null)
            {
                // 2. Read flat properties
                foreach (JsonPathFinder propertyContainerNode in propertiesNode.Children())
                {
                    JsonPathFinder propertyNode = propertyContainerNode.OpenContainer();
                    // First things first - check if the property is renamed
                    JsonPathFinder clientNameNode = propertyNode.Find(new JsonQueryBuilder().Property("x-ms-client-name")).SingleOrDefault();
                    string clientName = String.Empty;
                    if (clientNameNode != null)
                    {
                        clientName = clientNameNode.GetValue<string>().ToLowerInvariant();
                    }

                    string jsonName = propertyNode.Key.ToLowerInvariant();
                    string rawJsonName = propertyNode.Key;
                    // 5 cases:
                    //  1: Property contains a $ref node AND property contains an x-ms-client-flatten node
                    //  2: Property contains only a $ref node
                    //  3: Property is of type object and contains additionalProperties (not sure how to handle this yet)
                    //  4: Property is of type array (decode the individual items type)
                    //  5: Property is a simple property
                    JsonPathFinder refNode = propertyNode.Find(new JsonQueryBuilder().Property("$ref")).SingleOrDefault();
                    JsonPathFinder flattenNode = propertyNode.Find(new JsonQueryBuilder().Property("x-ms-client-flatten")).SingleOrDefault();
                    JsonPathFinder typeNode = propertyNode.Find(new JsonQueryBuilder().Property("type")).SingleOrDefault();
                    JsonPathFinder additionalPropertiesNode = propertyNode.Find(new JsonQueryBuilder().Property("additionalProperties")).SingleOrDefault();
                    JsonPathFinder arrayItemsRefNode = propertyNode.Find(new JsonQueryBuilder().Property("items").Property("$ref")).SingleOrDefault();
                    JsonPathFinder propertiesSubNode = propertyNode.Find(new JsonQueryBuilder().Property("properties")).SingleOrDefault();
                    if (refNode != null)
                    {
                        JsonPathFinder subDefinition = rootDoc.Find(new JsonQueryBuilder(refNode.GetValue<string>())).Single();
                        RuntimeTypeData referencedTypeData = GetRuntimeTypeDataFromDefinition(subDefinition.Path, subDefinition, cache, rootDoc);
                        if (flattenNode != null && flattenNode.GetValue<bool>())
                        {
                            // Push the properties of the referenced type to this type
                            // If it's flattened, the jsonName should actually be flatJsonName
                            foreach (string propertyName in referencedTypeData.Properties.Keys)
                            {
                                data.Properties[propertyName] = referencedTypeData.Properties[propertyName].Clone();
                                data.Properties[propertyName].SubNodeName = "properties";
                            }
                        }
                        else
                        {
                            // The referenced type is simply the type of this property
                            data.Properties[jsonName] = new ParameterData()
                            {
                                Name = clientName,
                                JsonName = jsonName,
                                RawJsonName = rawJsonName,
                                Type = referencedTypeData
                            };
                        }
                    }
                    else if (typeNode != null && typeNode.GetValue<string>().ToLowerInvariant().Equals("object") && additionalPropertiesNode != null)
                    {
                        // No converter required, this will probably be a Dictionary<string, something>
                        data.Properties[jsonName] = new ParameterData()
                        {
                            Name = clientName,
                            JsonName = jsonName,
                            RawJsonName = rawJsonName
                        };

                        // TODO: Support complex object as the additionalProperties type. Don't have a good example if this yet...
                    }
                    else if (typeNode != null && typeNode.GetValue<string>().ToLowerInvariant().Equals("array"))
                    {
                        // No converter required
                        data.Properties[jsonName] = new ParameterData()
                        {
                            Name = clientName,
                            JsonName = jsonName,
                            RawJsonName = rawJsonName
                        };

                        // When this is an array, we should add the type of the items in the array so that a converter is registered later
                        if (arrayItemsRefNode != null)
                        {
                            JsonPathFinder subDefinition = rootDoc.Find(new JsonQueryBuilder(arrayItemsRefNode.GetValue<string>())).Single();
                            data.Properties[jsonName].Type = new RuntimeTypeData();
                            data.Properties[jsonName].Type.CollectionTypes.Add(GetRuntimeTypeDataFromDefinition(subDefinition.Path, subDefinition, cache, rootDoc));
                        }
                    }
                    else if (propertiesSubNode != null)
                    {
                        // Not sure what to do with definition name yet
                        // The actual Type of the anonymous type will be filled in by postprocessing
                        // TODO: The properties of the subtype might be prefixed with "properties."
                        data.Properties[jsonName] = new ParameterData()
                        {
                            Name = clientName,
                            JsonName = jsonName,
                            RawJsonName = rawJsonName,
                            Type = GetRuntimeTypeDataFromDefinition(Guid.NewGuid().ToString(), propertyNode, cache, rootDoc)
                        };
                    }
                    else
                    {
                        // The last case should be the case of a simple property - assign the name and jsonName and let the type be inferred later
                        data.Properties[jsonName] = new ParameterData()
                        {
                            Name = clientName,
                            JsonName = jsonName,
                            RawJsonName = rawJsonName,
                            Type = new RuntimeTypeData()
                        };
                    }
                }
            }

            // 3. Read allOf node
            JsonPathFinder allOfNode = definitionNode.Find(new JsonQueryBuilder().Property("allOf")).SingleOrDefault();
            if (allOfNode != null)
            {
                // Get all $ref's
                foreach (JsonPathFinder refNode in allOfNode.Find(new JsonQueryBuilder().RecursiveDescent().Property("$ref")))
                {
                    JsonPathFinder subDefinition = rootDoc.Find(new JsonQueryBuilder(refNode.GetValue<string>())).Single();
                    RuntimeTypeData referencedTypeData = GetRuntimeTypeDataFromDefinition(subDefinition.Path, subDefinition, cache, rootDoc);
                    // Push the properties of the referenced type to this type
                    foreach (string propertyName in referencedTypeData.Properties.Keys)
                    {
                        data.Properties[propertyName] = referencedTypeData.Properties[propertyName];
                    }
                }
            }
            
            return data;
        }

        public virtual CommandExecutionResult ProcessRequest(LiveTestRequest request, LiveTestCredentialFactory credentialsFactory)
        {
            if (this.Logger != null)
            {
                this.Logger.LogAsync("Translating credentials...");
            }
            credentialsFactory.TranslateCredentialsObjects(request);
            CommandExecutionResult result = null;
            string operationId = request.OperationId == null ? null : request.OperationId.ToLowerInvariant();
            if (this.Logger != null)
            {
                this.Logger.LogAsync("Operation ID of message: " + operationId);
            }
            if (!String.IsNullOrEmpty(operationId) && this.Operations.ContainsKey(operationId))
            {
                if (this.Logger != null)
                {
                    this.Logger.LogAsync("Processing operation...");
                }
                OperationData op = this.Operations[operationId];
                // Create the command
                ICommandBuilder command = this.runspace.CreateCommand();
                command.Command = op.Command;
                foreach (string parameterName in op.Parameters.Keys)
                {
                    if (request.Params != null && request.Params.ContainsKey(parameterName.ToLowerInvariant()))
                    {
                        command.AddParameter(parameterName, request.Params[parameterName.ToLowerInvariant()]);
                    } else
                    {
                        this.Logger.LogAsync("Request missing parameter: " + parameterName);
                    }
                }

                // Process credentials
                IEnumerable<ICredentialProvider> credProviders = credentialsFactory.Create(request, this.Logger);
                foreach (ICredentialProvider credProvider in credProviders)
                {
                    credProvider.Process(command);
                }

                // Run the command
                result = command.Invoke();

                // Run post processors, if any
                foreach (ICommandPostProcessor postProcessor in op.PostProcessors)
                {
                    result = postProcessor.Process(result);
                }
            }
            else
            {
                // error
                if (this.Logger != null)
                {
                    this.Logger.LogError("Operation ID was not found in module under test.");
                }
            }
            
            return result;
        }

        public virtual CommandExecutionResult Load(bool force = false)
        {
            foreach (GeneratedModule requiredModule in this.RequiredModules)
            {
                CommandExecutionResult requiredModuleResult = requiredModule.Load(force: force);
                if (requiredModuleResult != null && requiredModuleResult.HadErrors)
                {
                    return requiredModuleResult;
                }
            }

            ICommandBuilder command = this.runspace.CreateCommand();
            command.Command = "Import-Module";
            if (!String.IsNullOrEmpty(ModulePath))
            {
                command.AddParameter("Name", this.ModulePath);
            }

            if (force)
            {
                command.AddParameter("Force", true);
            }

            return command.Invoke();
        }

        private void Log(string msg)
        {
            if (this.Logger != null)
            {
                this.Logger.LogAsync(msg);
            }
        }
    }
}