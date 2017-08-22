// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using Credentials;
    using Interfaces;
    using Json;
    using Logging;
    using Messages;
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.Linq;

    /// <summary>
    /// Contains metadata for a generated module being tested.
    /// </summary>
    public class GeneratedModule
    {
        private IRunspaceManager runspace;

        public string ModulePath { get; set; }

        public IList<GeneratedModule> RequiredModules { get; private set; }

        public IDictionary<string, OperationData> Operations { get; private set; }

        public Logger Logger { get; set; }

        public GeneratedModule(IRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.RequiredModules = new List<GeneratedModule>();
            this.Operations = new Dictionary<string, OperationData>();
        }

        public virtual void LoadMetadataFromSpecification(JsonPathFinder jsonPathFinder)
        {
            // 1. Find x-ms-client-name directly under path
            JsonQueryBuilder findNameUnderPath = new JsonQueryBuilder().Property("paths").RecursiveDescent().Property("x-ms-client-name");
            IEnumerable<JsonPathFinder> findResults = jsonPathFinder.Find(findNameUnderPath);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    Log("Found x-ms-client-name under paths: " + node);
                    JsonPathFinder parameterNode = node.Parent.Parent;
                    string jsonName = parameterNode.Find("name").Single().GetValue<string>().ToLowerInvariant();
                    string parameterName = node.GetValue<string>().ToLowerInvariant();
                    JsonPathFinder operationNode = parameterNode.Parent.Parent.Parent;
                    JsonPathFinder operationIdNode = operationNode.Find("operationId").SingleOrDefault();
                    if (operationIdNode != null)
                    {
                        string operationId = operationIdNode.GetValue<string>().ToLowerInvariant();
                        
                        if (this.Operations.ContainsKey(operationId) && this.Operations[operationId].Parameters.ContainsKey(parameterName))
                        {
                            Log(String.Format(CultureInfo.CurrentCulture, "Mapping PowerShell parameter '{0}' to JSON property '{1}' for operation '{2}'", parameterName, jsonName, operationId));
                            this.Operations[operationId].Parameters[parameterName].JsonName = jsonName;
                        }
                    } else
                    {
                        // Path Item level parameter
                        JsonPathFinder pathItemNode = parameterNode.Parent.Parent.Parent;
                        foreach (JsonPathFinder opIdNodeFromPathItem in pathItemNode.Find(new JsonQueryBuilder().RecursiveDescent().Property("operationId")))
                        {
                            string operationId = opIdNodeFromPathItem.GetValue<string>().ToLowerInvariant();
                            if (this.Operations.ContainsKey(operationId) && this.Operations[operationId].Parameters.ContainsKey(parameterName))
                            {
                                Log(String.Format(CultureInfo.CurrentCulture, "Mapping PowerShell parameter '{0}' to JSON property '{1}' for operation '{2}'", parameterName, jsonName, operationId));
                                this.Operations[operationId].Parameters[parameterName].JsonName = jsonName;
                            }
                        }
                    }
                }
            }

            // 2. Find x-ms-client-name directly under x-ms-paths
            JsonQueryBuilder findNameUnderExtendedPaths = new JsonQueryBuilder().Property("x-ms-paths").RecursiveDescent().Property("x-ms-client-name");
            findResults = jsonPathFinder.Find(findNameUnderExtendedPaths);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    Log("Found x-ms-client-name under x-ms-paths: " + node);
                    JsonPathFinder parameterNode = node.Parent.Parent;
                    string jsonName = parameterNode.Find("name").Single().GetValue<string>().ToLowerInvariant();
                    JsonPathFinder operationNode = parameterNode.Parent.Parent.Parent;
                    string operationId = operationNode.Find("operationId").Single().GetValue<string>().ToLowerInvariant();
                    string parameterName = node.GetValue<string>().ToLowerInvariant();
                    if (this.Operations.ContainsKey(operationId) && this.Operations[operationId].Parameters.ContainsKey(parameterName))
                    {
                        Log(String.Format(CultureInfo.CurrentCulture, "Mapping PowerShell parameter '{0}' to JSON property '{1}' for operation '{2}'", parameterName, jsonName, operationId));
                        this.Operations[operationId].Parameters[parameterName].JsonName = jsonName;
                    }
                }
            }

            // 3. Find x-ms-client-flatten under paths and x-ms-paths
            JsonQueryBuilder schemaRef = new JsonQueryBuilder().Property("schema").Property("$ref");
            JsonQueryBuilder findFlattenUnderPaths = new JsonQueryBuilder().Property("paths").RecursiveDescent().Property("x-ms-client-flatten");
            findResults = jsonPathFinder.Find(findFlattenUnderPaths);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    if (!node.GetValue<bool>())
                    {
                        continue;
                    }
                    JsonPathFinder parameterNode = node.Parent.Parent;
                    string definitionPath = parameterNode.Find(schemaRef).Single().GetValue<string>();
                    JsonPathFinder operationNode = parameterNode.Parent.Parent.Parent;
                    JsonPathFinder operationIdNode = operationNode.Find("operationId").SingleOrDefault();
                    if (operationIdNode != null)
                    {
                        string operationId = operationIdNode.GetValue<string>().ToLowerInvariant();

                        if (this.Operations.ContainsKey(operationId))
                        {
                            JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                            JsonPathFinder objectNode = jsonPathFinder.Find(definitionObject).Single();
                            LoadMetadataFromDefinitionNode(operationId, objectNode, jsonPathFinder);
                        }
                    }
                    else
                    {
                        // Path Item level parameter
                        JsonPathFinder pathItemNode = parameterNode.Parent.Parent.Parent;
                        foreach (JsonPathFinder opIdNodeFromPathItem in pathItemNode.Find(new JsonQueryBuilder().RecursiveDescent().Property("operationId")))
                        {
                            string operationId = opIdNodeFromPathItem.GetValue<string>().ToLowerInvariant();
                            if (this.Operations.ContainsKey(operationId))
                            {
                                JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                                JsonPathFinder objectNode = jsonPathFinder.Find(definitionObject).Single();
                                LoadMetadataFromDefinitionNode(operationId, objectNode, jsonPathFinder);
                            }
                        }
                    }
                }
            }

            JsonQueryBuilder findFlattenUnderExtendedPaths = new JsonQueryBuilder().Property("x-ms-paths").RecursiveDescent().Property("x-ms-client-flatten");
            findResults = jsonPathFinder.Find(findFlattenUnderExtendedPaths);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    if (!node.GetValue<bool>())
                    {
                        continue;
                    }
                    JsonPathFinder parameterNode = node.Parent.Parent;
                    string definitionPath = parameterNode.Find(schemaRef).Single().GetValue<string>();
                    JsonPathFinder operationNode = parameterNode.Parent.Parent.Parent;
                    JsonPathFinder operationIdNode = operationNode.Find("operationId").SingleOrDefault();
                    if (operationIdNode != null)
                    {
                        string operationId = operationIdNode.GetValue<string>().ToLowerInvariant();

                        if (this.Operations.ContainsKey(operationId))
                        {
                            JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                            JsonPathFinder objectNode = jsonPathFinder.Find(definitionObject).Single();
                            LoadMetadataFromDefinitionNode(operationId, objectNode, jsonPathFinder);
                        }
                    }
                    else
                    {
                        // Path Item level parameter
                        JsonPathFinder pathItemNode = parameterNode.Parent.Parent.Parent;
                        foreach (JsonPathFinder opIdNodeFromPathItem in pathItemNode.Find(new JsonQueryBuilder().RecursiveDescent().Property("operationId")))
                        {
                            string operationId = opIdNodeFromPathItem.GetValue<string>().ToLowerInvariant();
                            if (this.Operations.ContainsKey(operationId))
                            {
                                JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                                JsonPathFinder objectNode = jsonPathFinder.Find(definitionObject).Single();
                                LoadMetadataFromDefinitionNode(operationId, objectNode, jsonPathFinder);
                            }
                        }
                    }
                }
            }

            // 4. Find all ref'd parameters
            JsonQueryBuilder findRefParameters = new JsonQueryBuilder().Property("paths").Any().Any().Property("parameters").ArrayIndex(new JsonQueryBuilder().Filter(new JsonQueryBuilder().HasProperty("$ref")));
            findResults = jsonPathFinder.Find(findRefParameters);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    JsonPathFinder operationNode = node.Parent.Parent.Parent;
                    string operationId = operationNode.Find("operationId").Single().GetValue<string>().ToLowerInvariant();
                    JsonPathFinder globalParameter = jsonPathFinder.Find(new JsonQueryBuilder(node.Find("$ref").Single().GetValue<string>())).Single();

                    // Check for x-ms-client-name
                    JsonPathFinder globalParameterClientName = globalParameter.Find("x-ms-client-name").SingleOrDefault();
                    if (globalParameterClientName != null)
                    {
                        string parameterName = globalParameterClientName.GetValue<string>().ToLowerInvariant();
                        Log("Found x-ms-client-name under global parameter: " + parameterName);
                        string jsonName = globalParameter.Find("name").Single().GetValue<string>().ToLowerInvariant();
                        if (this.Operations.ContainsKey(operationId) && this.Operations[operationId].Parameters.ContainsKey(parameterName))
                        {
                            Log(String.Format(CultureInfo.CurrentCulture, "Mapping PowerShell parameter '{0}' to JSON property '{1}' for operation '{2}'", parameterName, jsonName, operationId));
                            this.Operations[operationId].Parameters[parameterName].JsonName = jsonName;
                        }
                    }

                    // Check for x-ms-client-flatten
                    JsonPathFinder globalParameterClientFlatten = globalParameter.Find("x-ms-client-flatten").SingleOrDefault();
                    if (globalParameterClientFlatten != null)
                    {
                        string definitionPath = globalParameter.Find(schemaRef).Single().GetValue<string>();
                        if (this.Operations.ContainsKey(operationId))
                        {
                            JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                            JsonPathFinder objectNode = jsonPathFinder.Find(definitionObject).Single();
                            LoadMetadataFromDefinitionNode(operationId, objectNode, jsonPathFinder);
                        }
                    }
                }
            }
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

        private void LoadMetadataFromDefinitionNode(string operationId, JsonPathFinder definitionNode, JsonPathFinder rootFinder)
        {
            JsonQueryBuilder findName = new JsonQueryBuilder().RecursiveDescent().Property("x-ms-client-name");
            IEnumerable<JsonPathFinder> findResults = definitionNode.Find(findName);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    string jsonName = node.Key.ToLowerInvariant();
                    string parameterName = node.GetValue<string>().ToLowerInvariant();
                    Log("Found x-ms-client-name under definition property: " + parameterName);
                    if (this.Operations.ContainsKey(operationId) && this.Operations[operationId].Parameters.ContainsKey(parameterName))
                    {
                        Log(String.Format(CultureInfo.CurrentCulture, "Mapping PowerShell parameter '{0}' to JSON property '{1}' for operation '{2}'", parameterName, jsonName, operationId));
                        this.Operations[operationId].Parameters[parameterName].JsonName = jsonName;
                    }
                }
            }

            JsonQueryBuilder findFlatten = new JsonQueryBuilder().RecursiveDescent().Property("x-ms-client-flatten");
            JsonQueryBuilder findRef = new JsonQueryBuilder().Property("$ref");
            findResults = definitionNode.Find(findFlatten);
            if (findResults != null)
            {
                foreach (JsonPathFinder node in findResults)
                {
                    if (!node.GetValue<bool>())
                    {
                        continue;
                    }
                    JsonPathFinder refNode = node.Parent.Parent.Find(findRef).Single();
                    string definitionPath = refNode.GetValue<string>();
                    JsonQueryBuilder definitionObject = new JsonQueryBuilder(definitionPath);
                    JsonPathFinder objectNode = rootFinder.Find(definitionObject).Single();
                    LoadMetadataFromDefinitionNode(operationId, objectNode, rootFinder);
                }
            }
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