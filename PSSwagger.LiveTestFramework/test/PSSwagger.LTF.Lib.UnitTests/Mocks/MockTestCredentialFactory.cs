namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Credentials;
    using Interfaces;
    using Models;
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using Logging;
    using Messages;

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