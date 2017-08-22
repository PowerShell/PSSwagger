// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Credentials;
    using Logging;
    using Mocks;
    using Models;
    using System;
    using System.Collections.Generic;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for AzureCredentialProvider type.
    /// </summary>
    public class AzureCredentialProviderTests
    {
        private readonly XUnitOutputPipe output;
        private readonly XUnitOutputPipe error;
        private readonly Logger logger;
        public AzureCredentialProviderTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
            this.error = new XUnitOutputPipe(output, logAsErrors: true);
            this.logger = new Logger(this.output, this.error);
        }

        [Fact]
        public void HappyPathDefaultCredType()
        {
            AzureCredentialProvider test = new AzureCredentialProvider(this.logger);
            test.Set("tenantId", "testTenantId");
            test.Set("clientId", "testClientId");
            test.Set("secret", "testSecret");
            MockRunspaceManager runspace = new MockRunspaceManager();
            runspace.CommandBuilders.Add(new MockCommandBuilder(runspace)
            {
                MockResult = new CommandExecutionResult(null, null, false)
            });
            runspace.CommandBuilders.Add(new MockCommandBuilder(runspace)
            {
                MockResult = new CommandExecutionResult(null, null, false)
            });
            test.Process(runspace.CommandBuilders[0]);

            Assert.Equal(2, runspace.InvokeHistory.Count);
            Assert.Equal("import-module [name azurerm.profile]", ((string)runspace.InvokeHistory[0]).ToLowerInvariant());
            Assert.Equal("add-azurermaccount [credential (testclientid testsecret)] [tenantid testtenantid] [serviceprincipal true]", ((string)runspace.InvokeHistory[1]).ToLowerInvariant());
        }

        [Fact]
        public void ExceptionWhenCredentialsPropertiesAreMissing()
        {
            AzureCredentialProvider test = new AzureCredentialProvider(this.logger);
            test.Set("tenantId", "testTenantId");
            test.Set("clientId", "testClientId");
            MockRunspaceManager runspace = new MockRunspaceManager();
            Assert.Throws<InvalidTestCredentialsException>(() => test.Process(runspace.CreateCommand()));
        }

        [Fact]
        public void ExceptionWhenCredentialsPropertiesAreEmpty()
        {
            AzureCredentialProvider test = new AzureCredentialProvider(this.logger);
            test.Set("tenantId", "testTenantId");
            test.Set("clientId", "testClientId");
            test.Set("secret", String.Empty);
            MockRunspaceManager runspace = new MockRunspaceManager();
            Assert.Throws<InvalidTestCredentialsException>(() => test.Process(runspace.CreateCommand()));
        }

        [Fact]
        public void ExceptionWhenCommandFails()
        {
            AzureCredentialProvider test = new AzureCredentialProvider(this.logger);
            test.Set("tenantId", "testTenantId");
            test.Set("clientId", "testClientId");
            test.Set("secret", "testSecret");
            MockRunspaceManager runspace = new MockRunspaceManager();
            runspace.CommandBuilders.Add(new MockCommandBuilder(runspace)
            {
                MockResult = new CommandExecutionResult(null, new List<string>() { "This is an error" }, true)
            });
            Assert.Throws<CommandFailedException>(() => test.Process(runspace.CommandBuilders[0]));
        }
    }
}