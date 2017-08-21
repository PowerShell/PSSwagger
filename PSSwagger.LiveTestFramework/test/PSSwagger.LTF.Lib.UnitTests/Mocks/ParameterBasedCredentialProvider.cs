// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;

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