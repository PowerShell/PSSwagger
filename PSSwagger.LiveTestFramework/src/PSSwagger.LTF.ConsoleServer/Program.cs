// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.ConsoleServer
{
    using Lib;
    using Lib.Credentials;
    using Lib.IO;
    using Lib.Logging;
    using Lib.Models;
    using Lib.PowerShell;
    using Lib.ServiceTracing;
    using Newtonsoft.Json;
    using PSSwagger.LTF.Lib.Transforms;
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.IO;
    using System.Reflection;
    using System.Threading;

    class Program
    {
        static void Main(string[] args)
        {
            ServerArgs serverArgs = new ServerArgs().Parse(Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "config.json")).Parse(args).Validate();
            
            EventLogOutputPipe eventLogOutputPipe = new EventLogOutputPipe();
            CompositeLogger logger = new CompositeLogger();
            if (serverArgs.EnableEventLog)
            {
                logger.AddLogger(new Logger(eventLogOutputPipe, eventLogOutputPipe));
            }

            if (serverArgs.EnablePipeLog)
            {
                try
                {
                    NamedPipeServer namedPipe = new NamedPipeServer(serverArgs.LogPipeName);
                    Logger namedPipeLogger = new Logger(namedPipe, namedPipe);
                    logger.AddLogger(namedPipeLogger);
                }
                catch (Exception e)
                {
                    logger.LogError("Failed to initialize named pipe logger: " + e.Message);
                }
            }
            
            if (serverArgs.Errors.Count > 0)
            {
                logger.LogError("Server arguments had errors.");
                foreach (string error in serverArgs.Errors)
                {
                    logger.LogError(error);
                }
                return;
            }

            // Load external modules
            PowerShellRunspace runspace = new PowerShellRunspace(logger);
            foreach (string externalModule in serverArgs.ExternalModules)
            {
                GeneratedModule module = new GeneratedModule(runspace);
                module.ModulePath = externalModule;
                CommandExecutionResult result = module.Load();
                if (result != null && result.HadErrors)
                {
                    logger.LogError(String.Format(CultureInfo.CurrentCulture, "Failed to load extra module: {0}", externalModule));
                    result.LogErrors(logger);
                    return;
                }
            }

            // Start test server
            JsonRpcPipe jsonRpcPipe = new JsonRpcPipe(new StandardInputPipe(), new StandardOutputPipe());
            LiveTestServer server = new LiveTestServer(new LiveTestServerStartParams()
            {
                Logger = logger,
                Input = jsonRpcPipe,
                Output = jsonRpcPipe,
                CredentialFactory = new LiveTestCredentialFactory(),
                RunspaceManager = runspace,
                ModulePath = serverArgs.ModulePath,
                TracingManager = new ServiceTracingManager(),
                SpecificationPaths = serverArgs.SpecificationPaths,
                ObjectTransforms = serverArgs.GetTransforms()
            });

            try
            {
                server.RunAsync().Wait();
            } catch (Exception ex)
            {
                logger.LogError("Failed to start server: " + ex.ToString());
            }

            // Wait until server exits (usually means the server ran into an internal error)
            while (server.IsRunning)
            {
                Thread.Sleep(2);
            }
        }
    }
    
    class ServerArgs
    {
        public List<string> SpecificationPaths { get; set; }
        public List<string> ExternalModules { get; set; }
        public string ModulePath { get; set; }
        public string LogPipeName { get; set; }
        public List<string> Errors { get; set; }
        public bool EnablePipeLog { get; set; }
        public bool EnableEventLog { get; set; }
        public List<string> TransformDefinitionFiles { get; set; }

        public ServerArgs()
        {
            this.Errors = new List<string>();
            this.SpecificationPaths = new List<string>();
            this.ExternalModules = new List<string>();
            this.LogPipeName = "psswagger-ltf-consoleserver";
            this.EnablePipeLog = true;
            this.EnableEventLog = false;
            this.TransformDefinitionFiles = new List<string>();
        }

        public IList<DynamicObjectTransform> GetTransforms()
        {
            List<DynamicObjectTransform> transforms = new List<DynamicObjectTransform>();
            foreach (string file in this.TransformDefinitionFiles)
            {
                transforms.Add(JsonConvert.DeserializeObject<DynamicObjectTransform>(File.ReadAllText(file)));
            }

            return transforms;
        }

        public ServerArgs Parse(string[] args)
        {
            string lastArg = String.Empty;
            bool resetSpecificationPaths = false;
            bool resetExternalModules = false;
            foreach (string arg in args)
            {
                if (!arg.StartsWith("/"))
                {
                    switch (lastArg.ToLowerInvariant())
                    {
                        case "spec":
                            if (!arg.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
                            {
                                this.Errors.Add("Specification file is not a .json file.");
                            }
                            else if (!File.Exists(arg))
                            {
                                this.Errors.Add(String.Format(CultureInfo.CurrentCulture, "Specification file does not exist: {0}", arg));
                            }
                            else
                            {
                                if (!resetSpecificationPaths)
                                {
                                    resetSpecificationPaths = true;
                                    this.SpecificationPaths.Clear();
                                }

                                this.SpecificationPaths.Add(arg);
                            }
                            break;
                        case "extmodule":
                            if (!resetExternalModules)
                            {
                                resetExternalModules = true;
                                this.ExternalModules.Clear();
                            }

                            this.ExternalModules.Add(arg);
                            break;
                        case "testmodule":
                            this.ModulePath = arg;
                            break;
                        case "logpipename":
                            this.LogPipeName = arg;
                            break;
                        case "transform":
                            // Let's merge these instead of overwriting maybe?
                            this.TransformDefinitionFiles.Add(arg);
                            break;
                        default:
                            this.Errors.Add(String.Format(CultureInfo.CurrentCulture, "Unknown argument: {0}", lastArg));
                            break;
                    }
                    lastArg = String.Empty;
                }
                else
                {
                    lastArg = arg.Substring(1);
                    switch (lastArg.ToLowerInvariant())
                    {
                        case "enablepipelog":
                            lastArg = String.Empty;
                            this.EnablePipeLog = true;
                            break;
                        case "enableeventlog":
                            lastArg = String.Empty;
                            this.EnableEventLog = true;
                            break;
                    }
                }
            }

            return this;
        }

        public ServerArgs Parse(string jsonFilePath)
        {
            if (File.Exists(jsonFilePath))
            {
                ServerArgs fromFile = JsonConvert.DeserializeObject<ServerArgs>(File.ReadAllText(jsonFilePath));
                if (!String.IsNullOrWhiteSpace(fromFile.ModulePath))
                {
                    this.ModulePath = fromFile.ModulePath;
                }

                if (!String.IsNullOrWhiteSpace(fromFile.LogPipeName))
                {
                    this.LogPipeName = fromFile.LogPipeName;
                }

                if (fromFile.ExternalModules != null && fromFile.ExternalModules.Count > 0)
                {
                    this.ExternalModules = fromFile.ExternalModules;
                }

                if (fromFile.SpecificationPaths != null && fromFile.SpecificationPaths.Count > 0)
                {
                    this.SpecificationPaths = fromFile.SpecificationPaths;
                }

                if (fromFile.TransformDefinitionFiles != null && fromFile.TransformDefinitionFiles.Count > 0)
                {
                    // Let's merge these instead of overwriting maybe?
                    this.TransformDefinitionFiles.AddRange(fromFile.TransformDefinitionFiles);
                }
            }

            return this;
        }

        public ServerArgs Validate()
        {
            if (String.IsNullOrEmpty(this.ModulePath))
            {
                this.Errors.Add("No test module path specified.");
            }

            return this;
        }
    }
}
