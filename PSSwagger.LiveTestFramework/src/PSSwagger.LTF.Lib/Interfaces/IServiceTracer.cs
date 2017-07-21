namespace PSSwagger.LTF.Lib.Interfaces
{
    using Models;
    using System.Collections;
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