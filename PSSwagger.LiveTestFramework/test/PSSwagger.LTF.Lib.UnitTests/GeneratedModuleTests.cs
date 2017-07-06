namespace PSSwagger.LTF.Lib.UnitTests
{
    using Messages;
    using Mocks;
    using Models;
    using System.Collections.Generic;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for GeneratedModule type.
    /// </summary>
    public class GeneratedModuleTests
    {
        private readonly ITestOutputHelper output;
        public GeneratedModuleTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        /// <summary>
        /// Test that a simple module executes the expected load command.
        /// </summary>
        [Fact]
        public void BasicLoadTest()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "test.psd1";
            module.Load();

            Assert.Equal("Import-Module", runspace.Builder.Command);
            Assert.True(runspace.Builder.Parameters.ContainsKey("Name"));
            Assert.Equal("test.psd1", runspace.Builder.Parameters["Name"]);
        }

        /// <summary>
        /// Test the expected command when force load == true.
        /// </summary>
        [Fact]
        public void ForceLoadTest()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "test.psd1";
            module.Load(force: true);

            Assert.Equal("Import-Module", runspace.Builder.Command);
            Assert.True(runspace.Builder.Parameters.ContainsKey("Name"));
            Assert.Equal("test.psd1", runspace.Builder.Parameters["Name"]);
            Assert.True(runspace.Builder.Parameters.ContainsKey("Force"));
            Assert.True((bool)runspace.Builder.Parameters["Force"]);
        }

        /// <summary>
        /// Test the expected command when module path is a module name instead of a full path.
        /// </summary>
        [Fact]
        public void LoadWithName()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "PackageManagement";
            module.Load();

            Assert.Equal("Import-Module", runspace.Builder.Command);
            Assert.True(runspace.Builder.Parameters.ContainsKey("Name"));
            Assert.Equal("PackageManagement", runspace.Builder.Parameters["Name"]);
        }

        /// <summary>
        /// Test the expected commands when the given module has required modules.
        /// </summary>
        [Fact]
        public void LoadWithRequiredModules()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            GeneratedModule requiredModule = new GeneratedModule(runspace);
            requiredModule.ModulePath = "PowerShellGet";
            module.ModulePath = "PackageManagement";
            module.RequiredModules.Add(requiredModule);
            module.Load();

            Assert.Equal("import-module [name powershellget]", runspace.Builder.InvokeHistory[0].ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement]", runspace.Builder.InvokeHistory[1].ToLowerInvariant());
        }

        /// <summary>
        /// Test that all import commands inherit the force attribute.
        /// </summary>
        [Fact]
        public void ForceIsPropogatedToAllModules()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            GeneratedModule requiredModule = new GeneratedModule(runspace);
            GeneratedModule requiredModuleSub = new GeneratedModule(runspace);
            requiredModuleSub.ModulePath = "psreadline";
            requiredModule.ModulePath = "PowerShellGet";
            requiredModule.RequiredModules.Add(requiredModuleSub);
            module.ModulePath = "PackageManagement";
            module.RequiredModules.Add(requiredModule);
            module.Load(force: true);

            Assert.Equal("import-module [name psreadline] [force true]", runspace.Builder.InvokeHistory[0].ToLowerInvariant());
            Assert.Equal("import-module [name powershellget] [force true]", runspace.Builder.InvokeHistory[1].ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement] [force true]", runspace.Builder.InvokeHistory[2].ToLowerInvariant());
        }

        [Fact]
        public void ProcessOperationSimpleParameters()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.Operations["Get-Thing"] = new OperationData("Thing_Get", "Get-Thing")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "Integer", new ParameterData() { Name = "Integer" } },
                    { "Boolean", new ParameterData() { Name = "Boolean" } },
                    { "Decimal", new ParameterData() { Name = "Decimal" } },
                    { "String", new ParameterData() { Name = "String" } }
                }
            };

            // MockLiveTestCredentialFactory credentialsFactory = new MockLiveTestCredentialFactory();
            LiveTestRequest request = new LiveTestRequest();

            CommandExecutionResult result = module.ProcessRequest(request, null);
            Assert.Equal(1, runspace.Builder.InvokeHistory.Count);
        }
    }
}