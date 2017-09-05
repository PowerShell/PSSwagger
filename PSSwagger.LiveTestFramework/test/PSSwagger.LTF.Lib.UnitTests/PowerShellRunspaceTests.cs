// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Interfaces;
    using Logging;
    using Mocks;
    using Models;
    using PowerShell;
    using System;
    using System.IO;
    using System.Linq;
    using System.Reflection;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for PowerShellRunspace type.
    /// </summary>
    public class PowerShellRunspaceTests
    {
        private readonly XUnitOutputPipe output;
        private readonly XUnitOutputPipe error;
        private readonly Logger logger;
        public PowerShellRunspaceTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
            this.error = new XUnitOutputPipe(output, logAsErrors: true);
            this.logger = new Logger(this.output, this.error);
        }

        /// <summary>
        /// Test that a basic PowerShell module can be loaded and parsed.
        /// </summary>
        [Fact]
        public void BasicHappyPathTest()
        {
            string modulePath = GetRootedPath(System.IO.Path.Combine("data", "Modules", "BasicHappyPath", "BasicHappyPath.psd1"));
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            GeneratedModule result = psRunspace.GetModuleInfo(modulePath);
            Assert.Equal(0, this.error.Errors.Count);
            Assert.NotNull(result);
            Assert.Equal(modulePath, result.ModulePath);
            Assert.Equal(4, result.Operations.Count);
            AssertModuleContainsOperation(result, new OperationData("Guitar_Create", "New-Guitar")
            {
                Parameters =
                {
                    { "id", new ParameterData()
                        {
                            Name = "id",
                            Type = new RuntimeTypeData(typeof(string))
                        }
                    }
                }
            });
            AssertModuleContainsOperation(result, new OperationData("Guitar_CreateByName", "New-Guitar")
            {
                Parameters =
                {
                    { "name", new ParameterData()
                        {
                            Name = "name",
                            Type = new RuntimeTypeData(typeof(string))
                        }
                    }
                }
            });
            AssertModuleContainsOperation(result, new OperationData("Guitar_GetById", "Get-Guitar")
            {
                Parameters =
                {
                    { "id", new ParameterData()
                        {
                            Name = "id",
                            Type = new RuntimeTypeData(typeof(string))
                        }
                    }
                },
                ResponseType = new ResponseTypeData()
                {
                    ModuleData = new RuntimeTypeData(typeof(string))
                }
            });
        }

        /// <summary>
        /// Test that there is a fatal error when no module exists.
        /// </summary>
        [Fact]
        public void FatalErrorWhenModuleNotExist()
        {
            string modulePath = System.IO.Path.GetRandomFileName();
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            Assert.Throws<CommandFailedException>(() => psRunspace.GetModuleInfo(modulePath));
        }

        /// <summary>
        /// Test that there is a fatal error when the given module path is an invalid module.
        /// </summary>
        [Fact]
        public void FatalErrorWhenModulePathNotValid()
        {
            string modulePath = GetRootedPath(System.IO.Path.Combine("data", "Modules", "InvalidManifest", "InvalidManifest.psd1"));
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            Assert.Throws<CommandFailedException>(() => psRunspace.GetModuleInfo(modulePath));
        }

        /// <summary>
        /// Test running a basic PowerShell command and getting a result.
        /// </summary>
        [Fact]
        public void RunGetVerb()
        {
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            ICommandBuilder psCommand = psRunspace.CreateCommand();
            psCommand.Command = "Get-Verb";
            psCommand.AddParameter("Verb", "Start");
            CommandExecutionResult results = psCommand.Invoke();
            Assert.NotNull(results);
            Assert.Equal(1, results.Results.Count());
            Assert.False(results.HadErrors);
            object result = results.Results.FirstOrDefault();
            Assert.NotNull(result);
            Assert.Equal("@{Verb=Start; Group=Lifecycle}", result.ToString());
        }

        /// <summary>
        /// Test error execution flow for exceptions when Invoke is called.
        /// </summary>
        [Fact]
        public void RunCommandWithExpectedErrorAsException()
        {
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            ICommandBuilder psCommand = psRunspace.CreateCommand();
            psCommand.Command = "Get-Process";
            psCommand.AddParameter("Test", "Start");
            CommandExecutionResult results = psCommand.Invoke();
            Assert.True(results.HadErrors);
            Assert.Equal(1, results.Errors.Count());
        }

        /// <summary>
        /// Test error execution flow for PS error stream.
        /// </summary>
        [Fact]
        public void RunCommandWithExpectedErrorAsErrorRecord()
        {
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            ICommandBuilder psCommand = psRunspace.CreateCommand();
            psCommand.Command = "Get-Process";
            psCommand.AddParameter("Name", "123456789");
            CommandExecutionResult results = psCommand.Invoke();
            Assert.True(results.HadErrors);
            Assert.Equal(1, results.Errors.Count());
        }

        /// <summary>
        /// Test parsing a module by name instead of path.
        /// </summary>
        [Fact]
        public void GetModuleInfoByName()
        {
            string modulePath = "PowerShellGet";
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            GeneratedModule module = psRunspace.GetModuleInfo(modulePath);
            Assert.Equal(12, module.Operations.Count);
        }

        /// <summary>
        /// Test that if a valid module path is specified, it must be an absolute path.
        /// </summary>
        [Fact]
        public void ModulePathNotRooted()
        {
            string modulePath = System.IO.Path.Combine("data", "Modules", "InvalidManifest", "InvalidManifest.psd1");
            PowerShellRunspace psRunspace = new PowerShellRunspace(this.logger);
            Assert.Throws<ModulePathNotRootedException>(() => psRunspace.GetModuleInfo(modulePath));
        }

        private string GetRootedPath(string relativePath)
        {
            string root = Path.GetDirectoryName(Uri.UnescapeDataString(new UriBuilder(Assembly.GetExecutingAssembly().CodeBase).Path));
            return Path.Combine(root, relativePath);
        }

        /// <summary>
        /// Verify <paramref name="result"/> contains the expected operation exactly.
        /// </summary>
        /// <param name="result">Resulting GeneratedModule object.</param>
        /// <param name="expectedOperation">Expected operation info.</param>
        private void AssertModuleContainsOperation(GeneratedModule result, OperationData expectedOperation)
        {
            // Ignore these 11 parameters:
            /* Verbose
            Debug
            ErrorAction
            WarningAction
            InformationAction
            ErrorVariable
            WarningVariable
            InformationVariable
            OutVariable
            OutBuffer
            PipelineVariable */
            Assert.True(result.Operations.ContainsKey(expectedOperation.OperationId.ToLowerInvariant()));
            Assert.Equal(expectedOperation.Parameters.Count, result.Operations[expectedOperation.OperationId.ToLowerInvariant()].Parameters.Count-11);
            OperationData actualOperation = result.Operations[expectedOperation.OperationId.ToLowerInvariant()];
            foreach (string parmName in expectedOperation.Parameters.Keys)
            {
                Assert.True(actualOperation.Parameters.ContainsKey(parmName), parmName);
                Assert.NotNull(actualOperation.Parameters[parmName].Type);
                Assert.Equal(expectedOperation.Parameters[parmName].Type.Type, actualOperation.Parameters[parmName].Type.Type);
                Assert.Equal(expectedOperation.Parameters[parmName].Type.Properties.Count, actualOperation.Parameters[parmName].Type.Properties.Count);
                foreach (string propertyName in expectedOperation.Parameters[parmName].Type.Properties.Keys)
                {
                    Assert.Equal(expectedOperation.Parameters[parmName].Type.Properties[propertyName].Type, actualOperation.Parameters[parmName].Type.Properties[propertyName].Type);
                    Assert.Equal(expectedOperation.Parameters[parmName].Type.Properties[propertyName].Name, actualOperation.Parameters[parmName].Type.Properties[propertyName].Name);
                    Assert.Equal(expectedOperation.Parameters[parmName].Type.Properties[propertyName].JsonName, actualOperation.Parameters[parmName].Type.Properties[propertyName].JsonName);
                }
            }

            if (expectedOperation.ResponseType != null)
            {
                Assert.NotNull(actualOperation.ResponseType);
                Assert.NotNull(actualOperation.ResponseType.ModuleData);
                Assert.Equal(expectedOperation.ResponseType.ModuleData.Type, actualOperation.ResponseType.ModuleData.Type);
            }
            else
            {
                Assert.Null(actualOperation.ResponseType);
            }
        }
    }
}
 