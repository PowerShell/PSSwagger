// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib
{
    using Converters;
    using Credentials;
    using Interfaces;
    using IO;
    using Logging;
    using Messages;
    using Models;
    using ServiceTracing;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Transforms;

    public class LiveTestServerStartParams
    {
        public IInputPipe Input { get; set; }
        public IOutputPipe Output { get; set; }
        public Logger Logger { get; set; }
        public IRunspaceManager RunspaceManager { get; set; }
        public string ModulePath { get; set; }
        public IList<string> SpecificationPaths { get; set; }
        public LiveTestCredentialFactory CredentialFactory { get; set; }
        public ServiceTracingManager TracingManager { get; set; }
        public IList<DynamicObjectTransform> ObjectTransforms { get; set; }
        public LiveTestServerStartParams()
        {
            this.SpecificationPaths = new List<string>();
            this.ObjectTransforms = new List<DynamicObjectTransform>();
        }
    }

    /// <summary>
    /// Main class for starting and interacting with the live test server.
    /// </summary>
    public class LiveTestServer
    {
        #region Language Server Protocol error codes
        private const int MethodNotFound = -32601;
        private const int InternalError = -32603;
        #endregion

        private LiveTestServerStartParams parameters;
        private GeneratedModule currentModule;
        private Thread messageReadThread;

        public IInputPipe Input { get; private set; }
        public IOutputPipe Output { get; private set; }
        public bool IsRunning { get; private set; }
        public LiveTestServer(LiveTestServerStartParams parms)
        {
            if (parms == null)
            {
                throw new ArgumentNullException("parms");
            }
            if (parms.Input == null)
            {
                throw new ArgumentNullException("parms.Input");
            }
            if (parms.Output == null)
            {
                throw new ArgumentNullException("parms.Output");
            }
            if (parms.RunspaceManager == null)
            {
                throw new ArgumentNullException("parms.RunspaceManager");
            }
            if (parms.CredentialFactory == null)
            {
                throw new ArgumentNullException("parms.CredentialFactory");
            }
            if (parms.TracingManager == null)
            {
                throw new ArgumentNullException("parms.TracingManager");
            }
            if (String.IsNullOrEmpty(parms.ModulePath))
            {
                throw new ArgumentNullException("parms.ModulePath");
            }

            this.parameters = parms;
            this.Input = parms.Input;
            this.Output = parms.Output;
            this.IsRunning = false;
            this.currentModule = null;
            this.messageReadThread = null;
        }

        public async Task RunAsync()
        {
            if (this.IsRunning)
            {
                throw new InvalidOperationException("Server is already running.");
            }

            // Retrieve all module information using the current runspace manager
            this.currentModule = this.parameters.RunspaceManager.GetModuleInfo(this.parameters.ModulePath);
            this.currentModule.Logger = this.parameters.Logger;

            // Parse specifications/metadata files for extra information, e.g. parameter renaming
            if (this.parameters.SpecificationPaths != null)
            {
                foreach (string specificationPath in this.parameters.SpecificationPaths)
                {
                    if (this.parameters.Logger != null)
                    {
                        this.parameters.Logger.LogAsync("Loading specification file: " + specificationPath);
                    }
                    Json.JsonPathFinder jsonFinder = new Json.JsonPathFinder(File.ReadAllText(specificationPath));
                    if (this.parameters.Logger != null)
                    {
                        this.parameters.Logger.LogAsync("Parsing specification file: " + specificationPath);
                    }
                    this.currentModule.LoadMetadataFromSpecification(jsonFinder);
                }
            }

            this.currentModule.CompleteMetadataLoad();

            // For JSON-RPC pipe input/output, add Newtonsoft.Json converters
            Newtonsoft.Json.JsonSerializerSettings inputSerializerSettings = null;
            if (this.Input is JsonRpcPipe)
            {
                JsonRpcPipe jsonRpcPipe = (JsonRpcPipe)this.Input;
                inputSerializerSettings = jsonRpcPipe.JsonSerializerSettings;
                new LiveTestRequestConverter(this.currentModule).RegisterSelf(jsonRpcPipe.JsonSerializerSettings);
                if (this.parameters.Logger != null)
                {
                    this.parameters.Logger.JsonSerializerSettings = jsonRpcPipe.JsonSerializerSettings;
                }
            }

            if (this.Output is JsonRpcPipe)
            {
                JsonRpcPipe jsonRpcPipe = (JsonRpcPipe)this.Output;
                // Double check this is a different object than the input pipe, if any.
                if (inputSerializerSettings == null || inputSerializerSettings != jsonRpcPipe.JsonSerializerSettings)
                {
                    new LiveTestRequestConverter(this.currentModule).RegisterSelf(jsonRpcPipe.JsonSerializerSettings);
                    if (this.parameters.Logger != null)
                    {
                        this.parameters.Logger.JsonSerializerSettings = jsonRpcPipe.JsonSerializerSettings;
                    }
                }
            }

            this.IsRunning = true;

            // Start message read thread
            this.messageReadThread = new Thread(async () =>
            {
                while (this.IsRunning)
                {
                    try
                    {
                        // Block and wait for the next request
                        LiveTestRequest msg = await this.Input.ReadBlock<LiveTestRequest>();
                        if (this.IsRunning)
                        {
                            if (msg == null)
                            {
                                if (this.parameters.Logger != null)
                                {
                                    this.parameters.Logger.LogAsync("Input stream has been closed, stopping server.", msg);
                                }

                                this.IsRunning = false;
                            }
                            else
                            {
                                if (this.parameters.Logger != null)
                                {
                                    this.parameters.Logger.LogAsync("Processing message: {0}", msg);
                                }
                                Task.Run(() =>
                                {
                                    LiveTestResponse response = null;
                                    IServiceTracer serviceTracer = null;
                                    try
                                    {
                                    // Enable service tracing so that we can get service layer information required by test protocol
                                    long invocationId = this.parameters.TracingManager.GetNextInvocationId();
                                        serviceTracer = this.parameters.TracingManager.CreateTracer(invocationId, this.parameters.Logger);
                                        this.parameters.TracingManager.EnableTracing();
                                    // Process teh request
                                    CommandExecutionResult commandResult = this.currentModule.ProcessRequest(msg, this.parameters.CredentialFactory);
                                        if (commandResult == null)
                                        {
                                            if (this.parameters.Logger != null)
                                            {
                                                this.parameters.Logger.LogAsync("Command not found.");
                                            }

                                            response = msg.MakeResponse(null, MethodNotFound);
                                        }
                                        else
                                        {
                                            response = msg.MakeResponse(commandResult, serviceTracer, parameters.ObjectTransforms, this.parameters.Logger);
                                        }
                                    }
                                    catch (Exception exRequest)
                                    {
                                        if (this.parameters.Logger != null)
                                        {
                                            this.parameters.Logger.LogError("Exception processing request: " + exRequest.ToString());
                                        }

                                        response = msg.MakeResponse(exRequest, InternalError);
                                    }
                                    finally
                                    {
                                        if (response != null)
                                        {
                                            this.Output.WriteBlock(response);
                                        }

                                        if (serviceTracer != null)
                                        {
                                            this.parameters.TracingManager.RemoveTracer(serviceTracer);
                                        }
                                    }
                                });
                            }
                        }
                    }
                    catch (Exception eRead)
                    {
                        if (this.parameters.Logger != null)
                        {
                            this.parameters.Logger.LogError("Exception during test server message loop: " + eRead.ToString());
                        }

                        this.IsRunning = false;
                    }
                }
            })
            { IsBackground = true };
            this.messageReadThread.Start();
            if (this.parameters.Logger != null)
            {
                this.parameters.Logger.LogAsync("PowerShell live test server has started.");
            }
        }

        public void Stop()
        {
            this.IsRunning = false;
            // For core CLR, the thread will still be waiting for input. The next message, depending on when it comes in, may be ignored.
#if !CORECLR
            this.messageReadThread.Abort();
            this.messageReadThread = null;
#endif
        }
    }
}
