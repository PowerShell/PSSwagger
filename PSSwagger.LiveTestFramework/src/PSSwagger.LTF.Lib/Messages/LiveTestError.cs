// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    using Microsoft.Rest;
    using System.Net.Http;

    /// <summary>
    /// Error response from test operation.
    /// </summary>
    public class LiveTestError
    {
        public long Code { get; set; }
        public string Message { get; set; }
        public object Data { get; set; }
        public HttpResponseMessage HttpResponse { get; set; }
    }
}