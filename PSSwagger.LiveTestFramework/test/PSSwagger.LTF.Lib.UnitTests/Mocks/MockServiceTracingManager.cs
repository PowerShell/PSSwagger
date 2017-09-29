// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Logging;
    using ServiceTracing;

    public class MockServiceTracingManager : ServiceTracingManager
    {
        public MockServiceTracer Tracer { get; set; }

        public MockServiceTracingManager()
        {
            this.Tracer = new MockServiceTracer();
        }

        /// <summary>
        /// Create a tracer for the given invocation ID. 
        /// </summary>
        /// <param name="invocationId">Invocation ID to create IServiceTracer for</param>
        /// <param name="logger">Logging source to send trace messages to</param>
        /// <returns>Service tracer</returns>
        public override IServiceTracer CreateTracer(long invocationId, Logger logger)
        {
            return this.Tracer;
        }

        public override void RemoveTracer(IServiceTracer tracer)
        {
        }

        public override void EnableTracing()
        {
        }

        public override void DisableTracing()
        {
        }

        public override long GetNextInvocationId()
        {
            return 0;
        }
    }
}