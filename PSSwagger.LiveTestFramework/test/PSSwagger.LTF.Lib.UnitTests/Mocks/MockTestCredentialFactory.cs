// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Credentials;
    using Interfaces;
    using System;

    /// <summary>
    /// Credential factory that allows registering ICredentialProviders
    /// </summary>
    public class MockTestCredentialFactory : LiveTestCredentialFactory
    {
        public MockTestCredentialFactory()
        {
            this.providers.Clear();
        }

        public void RegisterProvider<T>(string credType, T provider) where T : ICredentialProvider
        {
            if (String.IsNullOrEmpty(credType))
            {
                credType = "azure";
            }

            this.providers[credType] = (logger) => (T)Activator.CreateInstance(typeof(T));
        }
    }
}