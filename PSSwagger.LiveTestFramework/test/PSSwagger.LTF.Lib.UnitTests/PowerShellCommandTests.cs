// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Mocks;
    using PowerShell;
    using System;
    using System.Management.Automation.Runspaces;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for PowerShellCommand type.
    /// </summary>
    public class PowerShellCommandTests
    {
        private readonly XUnitOutputPipe output;
        public PowerShellCommandTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
        }

        /// <summary>
        /// Test that a basic command can be executed.
        /// </summary>
        [Fact]
        public void RunGetVerbWithSwitchParameter()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            PowerShellCommand command = new PowerShellCommand(runspace);
            command.Command = "Get-Verb";
            command.AddParameter("Verb", "Start");
            command.AddParameter("Verbose", true);
            command.Invoke();
            
            Assert.Equal(1, runspace.InvokeHistory.Count);
            Command result = runspace.InvokeHistory[0] as Command;
            Assert.NotNull(result);
            Assert.Equal("Get-Verb", result.CommandText);
            Assert.Equal(2, result.Parameters.Count);
            Assert.Equal("Verb", result.Parameters[0].Name);
            Assert.Equal("Verbose", result.Parameters[1].Name);
        }

        /// <summary>
        /// Test that AddParameter without a command throws an exception.
        /// </summary>
        [Fact]
        public void AddParameterWithoutCommandFails()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            PowerShellCommand command = new PowerShellCommand(runspace);
            Assert.Throws<InvalidOperationException>(() => command.AddParameter("Verb", "Start"));
        }

        /// <summary>
        /// Test that trying to add a parameter with no name fails.
        /// </summary>
        [Fact]
        public void NoParameterNameFails()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            PowerShellCommand command = new PowerShellCommand(runspace);
            command.Command = "Get-Verb";
            Assert.Throws<ArgumentNullException>(() => command.AddParameter(null, "Start"));
        }

        /// <summary>
        /// Test that the same builder can be used for multiple commands once the Command property is changed.
        /// </summary>
        [Fact]
        public void ParametersAreClearedWhenNewCommandCreated()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            PowerShellCommand command = new PowerShellCommand(runspace);
            command.Command = "Get-Verb";
            command.AddParameter("Verb", "Start");
            command.AddParameter("Verbose", true);

            command.Command = "Get-Verbage";
            command.AddParameter("Debug", true);
            command.Invoke();

            Assert.Equal(1, runspace.InvokeHistory.Count);
            Command result = runspace.InvokeHistory[0] as Command;
            Assert.NotNull(result);
            Assert.Equal("Get-Verbage", result.CommandText);
            Assert.Equal(1, result.Parameters.Count);
            Assert.Equal("Debug", result.Parameters[0].Name);
        }
    }
}