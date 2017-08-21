// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.ServiceTracing
{
    using Interfaces;
    using Logging;
    using Microsoft.Rest;

    /// <summary>
    /// Manages tracing for the service layer.
    /// </summary>
    public class ServiceTracingManager
    {
        public virtual long GetNextInvocationId()
        {
            return ServiceClientTracing.NextInvocationId + 1;
        }

        /// <summary>
        /// Create a tracer for the given invocation ID. 
        /// </summary>
        /// <param name="invocationId">Invocation ID to create IServiceTracer for</param>
        /// <param name="logger">Logging source to send trace messages to</param>
        /// <returns>Service tracer</returns>
        public virtual IServiceTracer CreateTracer(long invocationId, Logger logger)
        {
            ClientRuntimeServiceTracer tracer = new ClientRuntimeServiceTracer(invocationId, logger);
            ServiceClientTracing.AddTracingInterceptor(tracer);
            return tracer;
        }

        public virtual void RemoveTracer(IServiceTracer tracer)
        {
            if (tracer is ClientRuntimeServiceTracer)
            {
                ServiceClientTracing.RemoveTracingInterceptor((ClientRuntimeServiceTracer)tracer);
            }
        }

        public virtual void EnableTracing()
        {
            ServiceClientTracing.IsEnabled = true;
        }

        public virtual void DisableTracing()
        {
            ServiceClientTracing.IsEnabled = false;
        }
    }
}