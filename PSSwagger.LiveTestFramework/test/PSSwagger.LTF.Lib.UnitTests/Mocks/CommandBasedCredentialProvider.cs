// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;

    /// <summary>
    /// Mock credential provider that executes a command (e.g. AzureCredentialProvider).
    /// </summary>
    public class CommandBasedCredentialProvider : ICredentialProvider
    {
        public void Process(ICommandBuilder command)
        {
            ICommandBuilder credCommand = command.Runspace.CreateCommand();
            credCommand.Command = "Login-Account";
            credCommand.Invoke();
        }

        public void Set(string property, object value)
        {
        }
    }
}