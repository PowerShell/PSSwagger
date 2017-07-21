namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Models;
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

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