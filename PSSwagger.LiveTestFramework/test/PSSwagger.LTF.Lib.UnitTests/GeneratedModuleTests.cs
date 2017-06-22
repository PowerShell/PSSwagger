namespace PSSwagger.LTF.Lib.UnitTests
{
    using Mocks;
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
            Assert.Equal("test.psd1", runspace.Builder.Parameters["Name"].Item1);
            Assert.False(runspace.Builder.Parameters["Name"].Item2);
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
            Assert.Equal("test.psd1", runspace.Builder.Parameters["Name"].Item1);
            Assert.False(runspace.Builder.Parameters["Name"].Item2);
            Assert.True(runspace.Builder.Parameters.ContainsKey("Force"));
            Assert.True((bool)runspace.Builder.Parameters["Force"].Item1);
            Assert.True(runspace.Builder.Parameters["Force"].Item2);
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
            Assert.Equal("PackageManagement", runspace.Builder.Parameters["Name"].Item1);
            Assert.False(runspace.Builder.Parameters["Name"].Item2);
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

            Assert.Equal("import-module [name powershellget false]", runspace.Builder.InvokeHistory[0].ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement false]", runspace.Builder.InvokeHistory[1].ToLowerInvariant());
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

            Assert.Equal("import-module [name psreadline false] [force true true]", runspace.Builder.InvokeHistory[0].ToLowerInvariant());
            Assert.Equal("import-module [name powershellget false] [force true true]", runspace.Builder.InvokeHistory[1].ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement false] [force true true]", runspace.Builder.InvokeHistory[2].ToLowerInvariant());
        }
    }
}