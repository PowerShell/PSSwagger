// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using System.Collections.Generic;
    using System.Net.Http;

    /// <summary>
    /// Traces operations at the service layer.
    /// </summary>
    public interface IServiceTracer
    {
        /// <summary>
        /// Gets the collection of HttpResponseMessages caught by this tracer.
        /// </summary>
        IList<HttpResponseMessage> HttpResponses { get; }
    }
}