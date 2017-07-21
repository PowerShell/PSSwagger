namespace PSSwagger.LTF.Lib.ServiceTracing
{
    using Microsoft.Rest;
    using Models;
    using System.Collections;
    using System.Collections.Generic;
    using System.Net.Http;
    using System;
    using Interfaces;
    using Logging;

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
            if (this.invocationId.Equals(invocationId))
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
            if (this.invocationId.Equals(invocationId))
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