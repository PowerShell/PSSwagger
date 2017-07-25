// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Credentials;
    using Messages;
    using Mocks;
    using System;
    using System.Threading;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for LiveTestServer type.
    /// </summary>
    public class LiveTestServerTests
    {
        private readonly ITestOutputHelper output;
        public LiveTestServerTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        /// <summary>
        /// Test the basic execution flow of LiveTestServer: input -> process -> output
        /// </summary>
        [Fact]
        public void BasicExecutionFlow()
        {
            TimeSpan testTimeout = TimeSpan.FromMinutes(1);
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();
            blockPipe.Requests.Enqueue(new LiveTestRequest()
            {
                Id = "0",
                JsonRpc = "2.0",
                Method = "A.B_C",
                Params = new System.Collections.Generic.Dictionary<string, object>()
                    {
                        { "parm", 5.0 }
                    }
            });

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Input = blockPipe,
                Output = blockPipe,
                RunspaceManager = mockRunspace,
                ModulePath = "test",
                CredentialFactory = new LiveTestCredentialFactory(),
                TracingManager = new MockServiceTracingManager()
            };
            LiveTestServer server = new LiveTestServer(parms);
            server.RunAsync().Wait();
            DateTime start = DateTime.Now;
            while ((DateTime.Now - start) < testTimeout && !module.ProcessRequestCalled)
            {
                // Wait for the request to be processed, if ever
                Thread.Sleep(1);
            }

            server.Stop();

            // Check the expected flow
            //      1. Get module info
            //      3. Process request
            Assert.True(mockRunspace.GetModuleInfoCalled, "GetModuleInfo was never called.");
            Assert.True(module.ProcessRequestCalled, "ProcessRequest was never called.");
        }

        /// <summary>
        /// Test LiveTestServer constructor when missing required parameter.
        /// </summary>
        [Fact]
        public void MissingInputPipe()
        {
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Output = blockPipe,
                RunspaceManager = mockRunspace,
                ModulePath = "test",
                CredentialFactory = new LiveTestCredentialFactory()
            };
            Assert.Throws<ArgumentNullException>(() => new LiveTestServer(parms));
        }

        /// <summary>
        /// Test LiveTestServer constructor when missing required parameter.
        /// </summary>
        [Fact]
        public void MissingOutputPipe()
        {
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Input = blockPipe,
                RunspaceManager = mockRunspace,
                ModulePath = "test",
                CredentialFactory = new LiveTestCredentialFactory()
            };
            Assert.Throws<ArgumentNullException>(() => new LiveTestServer(parms));
        }

        /// <summary>
        /// Test LiveTestServer constructor when missing required parameter.
        /// </summary>
        [Fact]
        public void MissingRunspaceManager()
        {
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Input = blockPipe,
                Output = blockPipe,
                ModulePath = "test",
                CredentialFactory = new LiveTestCredentialFactory()
            };
            Assert.Throws<ArgumentNullException>(() => new LiveTestServer(parms));
        }

        /// <summary>
        /// Test LiveTestServer constructor when missing required parameter.
        /// </summary>
        [Fact]
        public void MissingModulePath()
        {
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Input = blockPipe,
                Output = blockPipe,
                RunspaceManager = mockRunspace,
                CredentialFactory = new LiveTestCredentialFactory()
            };
            Assert.Throws<ArgumentNullException>(() => new LiveTestServer(parms));
        }

        /// <summary>
        /// Test LiveTestServer constructor when missing required parameter.
        /// </summary>
        [Fact]
        public void MissingCredentialsFactory()
        {
            MockRunspaceManager mockRunspace = new MockRunspaceManager();
            MockGeneratedModule module = new MockGeneratedModule(mockRunspace);
            mockRunspace.ModuleMocks["test"] = module;
            TestBlockPipe blockPipe = new TestBlockPipe();

            LiveTestServerStartParams parms = new LiveTestServerStartParams()
            {
                Input = blockPipe,
                Output = blockPipe,
                RunspaceManager = mockRunspace,
                ModulePath = "test"
            };
            Assert.Throws<ArgumentNullException>(() => new LiveTestServer(parms));
        }
    }
}