namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Models;
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

    /// <summary>
    /// Mock credential provider that adds a parameter to the given command (e.g. supplying -APIKey).
    /// </summary>
    public class ParameterBasedCredentialProvider : ICredentialProvider
    {
        public void Process(ICommandBuilder command)
        {
            command.AddParameter("CredentialKey", "testCredentials");
        }

        public void Set(string property, object value)
        {
        }
    }
}