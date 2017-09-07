// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.ServiceTracing
{
    using Interfaces;
    using Logging;
    using Microsoft.Rest;
    using System;
    using System.Collections.Generic;
    using System.Net.Http;

    /// <summary>
    /// Traces operations at the service layer using Microsoft.Rest.ClientRuntime.
    /// </summary>
    public class ClientRuntimeServiceTracer : IServiceTracer, IServiceClientTracingInterceptor
    {
        private Logger logger;
        private string invocationId;

        /// <summary>
        /// Gets the collection of HttpResponseMessages caught by this tracer.
        /// </summary>
        public IList<HttpResponseMessage> HttpResponses { get; private set; }

        public ClientRuntimeServiceTracer(long invocationId, Logger logger)
        {
            this.HttpResponses = new List<HttpResponseMessage>();
            this.logger = logger;
            this.invocationId = invocationId.ToString();
        }

        public void Configuration(string source, string name, string value)
        {
        }

        public void EnterMethod(string invocationId, object instance, string method, IDictionary<string, object> parameters)
        {
        }

        public void ExitMethod(string invocationId, object returnValue)
        {
        }

        public void Information(string message)
        {
        }

        public void ReceiveResponse(string invocationId, HttpResponseMessage response)
        {
            // InvocationId check is currently disabled due to the multi-request nature of some AutoRest functions
            // This means that, for now, tracing is not thread safe
            //if (this.invocationId.Equals(invocationId))
            {
                if (this.logger != null)
                {
                    this.logger.LogAsync(response.ToString());
                }

                this.HttpResponses.Add(response);
            }
        }

        public void SendRequest(string invocationId, HttpRequestMessage request)
        {
            // InvocationId check is currently disabled due to the multi-request nature of some AutoRest functions
            // This means that, for now, tracing is not thread safe
            //if (this.invocationId.Equals(invocationId))
            {
                if (this.logger != null)
                {
                    this.logger.LogAsync(request.ToString());
                }
            }
        }

        public void TraceError(string invocationId, Exception exception)
        {
        }
    }
}