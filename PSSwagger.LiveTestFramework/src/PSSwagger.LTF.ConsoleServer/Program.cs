namespace PSSwagger.LTF.ConsoleServer
{
    using Lib;
    using Lib.Credentials;
    using Lib.Interfaces;
    using Lib.IO;
    using Lib.Logging;
    using Lib.Models;
    using Lib.PowerShell;
    using Lib.ServiceTracing;
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.IO;
    using System.Threading;

    class Program
    {
        static void Main(string[] args)
        {
            ServerArgs serverArgs = new ServerArgs(args);
            NamedPipeServer namedPipe = new NamedPipeServer(serverArgs.LogPipeName);
            Logger logger = new Logger(namedPipe, namedPipe);
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
                SpecificationPaths = serverArgs.SpecificationPaths
            });

            try
            {
                server.RunAsync().Wait();
            } catch (Exception ex)
            {
                logger.LogError("Failed to start server: " + ex.ToString());
            }

            // Wait forever
            while (server.IsRunning)
            {
                Thread.Sleep(1);
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

        public ServerArgs(string[] args)
        {
            this.LogPipeName = "psswagger-ltf-consoleserver";
            string lastArg = String.Empty;
            this.SpecificationPaths = new List<string>();
            this.ExternalModules = new List<string>();
            this.Errors = new List<string>();
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
                            } else if (!File.Exists(arg))
                            {
                                this.Errors.Add(String.Format(CultureInfo.CurrentCulture, "Specification file does not exist: {0}", arg));
                            } else
                            {
                                this.SpecificationPaths.Add(arg);
                            }
                            break;
                        case "extmodule":
                            this.ExternalModules.Add(arg);
                            break;
                        case "testmodule":
                            this.ModulePath = arg;
                            break;
                        case "logpipename":
                            this.LogPipeName = arg;
                            break;
                        default:
                            this.Errors.Add(String.Format(CultureInfo.CurrentCulture, "Unknown argument: {0}", lastArg));
                            break;
                    }
                    lastArg = String.Empty;
                } else
                {
                    lastArg = arg.Substring(1);
                }
            }

            if (String.IsNullOrEmpty(this.ModulePath))
            {
                this.Errors.Add("No test module path specified.");
            }
        }
    }
}
