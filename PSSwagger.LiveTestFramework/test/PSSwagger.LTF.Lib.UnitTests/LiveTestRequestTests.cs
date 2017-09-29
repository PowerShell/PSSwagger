// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Logging;
    using Messages;
    using Mocks;
    using Models;
    using System;
    using System.Collections.Generic;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for LiveTestRequest type.
    /// </summary>
    public class LiveTestRequestTests
    {
        private readonly XUnitOutputPipe output;
        private readonly XUnitOutputPipe error;
        private readonly Logger logger;
        public LiveTestRequestTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
            this.error = new XUnitOutputPipe(output, logAsErrors: true);
            this.logger = new Logger(this.output, this.error);
        }

        [Fact]
        public void ExceptionResponse()
        {
            int errorCode = 1;
            Exception ex = new NotImplementedException();
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(ex, errorCode);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Error);
            Assert.Equal(errorCode, response.Error.Code);

            Assert.NotNull(response.Error.Data);
            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
            Assert.Equal(ex, response.Error.Data.Response);
        }

        [Fact]
        public void NullErrorResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            CommandExecutionResult result = new CommandExecutionResult(null, null, true);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Error);
            Assert.Equal(-32600, response.Error.Code); // Invalid Request error code defined by LSP

            Assert.NotNull(response.Error.Data);
            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
            Assert.Null(response.Error.Data.Response);
        }

        [Fact]
        public void NoErrorResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            List<object> errors = new List<object>();
            CommandExecutionResult result = new CommandExecutionResult(null, errors, true);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Error);
            Assert.Equal(-32600, response.Error.Code); // Invalid Request error code defined by LSP

            Assert.NotNull(response.Error.Data);
            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
            Assert.Null(response.Error.Data.Response);
        }

        [Fact]
        public void SingleErrorResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            object errorResult = 5;
            List<object> errors = new List<object>();
            errors.Add(errorResult);
            CommandExecutionResult result = new CommandExecutionResult(null, errors, true);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Error);
            Assert.Equal(-32600, response.Error.Code); // Invalid Request error code defined by LSP

            Assert.NotNull(response.Error.Data);
            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
            Assert.NotNull(response.Error.Data.Response);
            Assert.Equal(errorResult, response.Error.Data.Response);
        }

        [Fact]
        public void MultipleErrorResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            object errorResult1 = 5;
            object errorResult2 = "test";
            List<object> errors = new List<object>();
            errors.Add(errorResult1);
            errors.Add(errorResult2);
            CommandExecutionResult result = new CommandExecutionResult(null, errors, true);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Error);
            Assert.Equal(-32600, response.Error.Code); // Invalid Request error code defined by LSP

            Assert.NotNull(response.Error.Data);
            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
            Assert.NotNull(response.Error.Data.Response);
            Assert.True(response.Error.Data.Response is object[]);
            Assert.Collection<object>((object[])response.Error.Data.Response, new Action<object>[]
            {
                (obj) =>
                {
                    Assert.Equal(errorResult1, obj);
                },
                (obj) =>
                {
                    Assert.Equal(errorResult2, obj);
                }
            });
        }

        [Fact]
        public void NullResultResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            CommandExecutionResult result = new CommandExecutionResult(null, null, false);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Result);
            Assert.Null(response.Result.Headers);
            Assert.Equal(default(long), response.Result.StatusCode);
            Assert.Null(response.Result.Response);
        }

        [Fact]
        public void NoResultResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            List<object> psResults = new List<object>();
            CommandExecutionResult result = new CommandExecutionResult(psResults, null, false);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Result);
            Assert.Null(response.Result.Headers);
            Assert.Equal(default(long), response.Result.StatusCode);
            Assert.Null(response.Result.Response);
        }

        [Fact]
        public void SingleResultResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            object psResult = 5;
            List<object> psResults = new List<object>();
            psResults.Add(psResult);
            CommandExecutionResult result = new CommandExecutionResult(psResults, null, false);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Result);
            Assert.Null(response.Result.Headers);
            Assert.Equal(default(long), response.Result.StatusCode);
            Assert.NotNull(response.Result.Response);
            Assert.Equal(psResult, response.Result.Response);
        }

        [Fact]
        public void MultipleResultResponse()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            object psResult1 = 5;
            object psResult2 = "test";
            List<object> psResults = new List<object>();
            psResults.Add(psResult1);
            psResults.Add(psResult2);
            CommandExecutionResult result = new CommandExecutionResult(psResults, null, false);
            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);
            Assert.Equal(request.Id, response.Id);
            Assert.Equal(request.JsonRpc, response.JsonRpc);

            Assert.NotNull(response.Result);
            Assert.Null(response.Result.Headers);
            Assert.Equal(default(long), response.Result.StatusCode);
            Assert.NotNull(response.Result.Response);
            Assert.Collection<object>((object[])response.Result.Response, new Action<object>[]
            {
                (obj) =>
                {
                    Assert.Equal(psResult1, obj);
                },
                (obj) =>
                {
                    Assert.Equal(psResult2, obj);
                }
            });
        }

        [Fact]
        public void HttpResponseDataInError()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            System.Net.Http.HttpResponseMessage httpResponse = new System.Net.Http.HttpResponseMessage(System.Net.HttpStatusCode.BadGateway);
            httpResponse.Headers.Add("x-ms-header", "value");
            tracer.HttpResponses.Add(httpResponse);

            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            request.HttpResponse = true;

            CommandExecutionResult result = new CommandExecutionResult(null, null, true);
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);

            Assert.NotNull(response.Error.Data.Headers);
            Assert.True(response.Error.Data.Headers is Dictionary<string, object>);
            Dictionary<string, object> headers = (Dictionary<string, object>)response.Error.Data.Headers;
            Assert.Equal(1, headers.Count);
            Assert.True(headers.ContainsKey("x-ms-header"));
            Assert.Equal(new string[] { "value" }, headers["x-ms-header"]);

            Assert.Equal((long)System.Net.HttpStatusCode.BadGateway, response.Error.Data.StatusCode);
        }

        [Fact]
        public void HttpResponseDataInResult()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            System.Net.Http.HttpResponseMessage httpResponse = new System.Net.Http.HttpResponseMessage(System.Net.HttpStatusCode.Accepted);
            httpResponse.Headers.Add("x-ms-header", "value");
            tracer.HttpResponses.Add(httpResponse);

            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";
            request.HttpResponse = true;

            CommandExecutionResult result = new CommandExecutionResult(null, null, false);
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);

            Assert.NotNull(response.Result.Headers);
            Assert.True(response.Result.Headers is Dictionary<string, object>);
            Dictionary<string, object> headers = (Dictionary<string, object>)response.Result.Headers;
            Assert.Equal(1, headers.Count);
            Assert.True(headers.ContainsKey("x-ms-header"));
            Assert.Equal(new string[] { "value" }, headers["x-ms-header"]);

            Assert.Equal((long)System.Net.HttpStatusCode.Accepted, response.Result.StatusCode);
        }

        [Fact]
        public void HttpResponseDataInErrorNoHttpResponseEnabled()
        {
            MockServiceTracer tracer = new MockServiceTracer();
            System.Net.Http.HttpResponseMessage httpResponse = new System.Net.Http.HttpResponseMessage(System.Net.HttpStatusCode.BadGateway);
            httpResponse.Headers.Add("x-ms-header", "value");
            tracer.HttpResponses.Add(httpResponse);

            LiveTestRequest request = new LiveTestRequest();
            request.Id = "12345";
            request.JsonRpc = "2.0";

            CommandExecutionResult result = new CommandExecutionResult(null, null, true);
            LiveTestResponse response = request.MakeResponse(result, tracer, this.logger);

            Assert.Null(response.Error.Data.Headers);
            Assert.Equal(default(long), response.Error.Data.StatusCode);
        }
    }
}