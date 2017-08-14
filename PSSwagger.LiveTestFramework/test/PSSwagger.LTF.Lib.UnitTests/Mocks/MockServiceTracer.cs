// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using System.Collections.Generic;
    using System.Net.Http;

    /// <summary>
    /// Traces operations at the service layer using Microsoft.Rest.ClientRuntime.
    /// </summary>
    public class MockServiceTracer : IServiceTracer
    {
        /// <summary>
        /// Gets the collection of HttpResponseMessages caught by this tracer.
        /// </summary>
        public IList<HttpResponseMessage> HttpResponses { get; set; }

        public MockServiceTracer()
        {
            this.HttpResponses = new List<HttpResponseMessage>();
        }
    }
}