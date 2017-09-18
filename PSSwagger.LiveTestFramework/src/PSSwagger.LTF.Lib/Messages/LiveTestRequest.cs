// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    using Interfaces;
    using Logging;
    using Models;
    using Newtonsoft.Json;
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Net.Http;
    using Transforms;

    /// <summary>
    /// An Azure Live Test Framework JSON-RPC request.
    /// </summary>
    public class LiveTestRequest : JsonRpcBase
    {
        #region Language Server Protocol error codes
        private const int InvalidRequest = -32600;
        #endregion

        public string Method { get; set; }
        public Dictionary<string, object> Params { get; set; }
        [JsonIgnore]
        public string OperationId { get; set; }
        [JsonIgnore]
        public bool HttpResponse { get; set; }

        public LiveTestResponse MakeResponse(CommandExecutionResult commandResult, IServiceTracer tracer, IList<DynamicObjectTransform> transforms, Logger logger)
        {
            LiveTestResponse response = MakeBaseResponse();
            if (commandResult.HadErrors)
            {
                if (logger != null)
                {
                    logger.LogAsync("Command failed with errors.");
                    commandResult.LogErrors(logger);
                }

                response.Error = new LiveTestError();
                response.Error.Code = InvalidRequest;
                List<object> errors = new List<object>();
                foreach (object originalError in commandResult.Errors)
                {
                    errors.AddRange(TransformObject(originalError, transforms));
                }

                response.Error.Data = errors.Count == 0 ? null : errors.Count == 1 ? errors[0] : errors;
                if (this.HttpResponse)
                {
                    HttpResponseMessage responseMessage = tracer.HttpResponses.LastOrDefault();
                    if (responseMessage != null)
                    {
                        // Kill the Content property - doesn't work with Newtonsoft.Json serialization
                        HttpResponseMessage clonedMessage = new HttpResponseMessage(responseMessage.StatusCode);
                        foreach (var header in responseMessage.Headers)
                        {
                            clonedMessage.Headers.Add(header.Key, header.Value);
                        }

                        clonedMessage.ReasonPhrase = responseMessage.ReasonPhrase;
                        clonedMessage.RequestMessage = responseMessage.RequestMessage;
                        clonedMessage.Version = responseMessage.Version;
                        response.Error.HttpResponse = clonedMessage;
                    }
                }
            }
            else
            {
                if (logger != null)
                {
                    logger.LogAsync("Command executed successfully.");
                }

                List<object> results = new List<object>();
                foreach (object originalResult in commandResult.Results)
                {
                    results.AddRange(TransformObject(originalResult, transforms));
                }

                response.Result = GetLiveTestResult(results, tracer);
            }

            return response;
        }

        public LiveTestResponse MakeResponse(Exception ex, int errorCode)
        {
            LiveTestResponse response = MakeBaseResponse();
            response.Error = new LiveTestError();
            response.Error.Code = errorCode;
            response.Error.Data = ex;
            return response;
        }

        private IEnumerable<object> TransformObject(object obj, IList<DynamicObjectTransform> transforms)
        {
            bool transformed = false;
            foreach (object result in transforms.Where(t => t.CanTransform(obj)).SelectMany(t => t.Transform(obj)))
            {
                transformed = true;
                IEnumerable<object> transformedResults = TransformObject(result, transforms);
                if (transformedResults != null)
                {
                    foreach (object innerResult in transformedResults)
                    {
                        yield return innerResult;
                    }
                }
            }

            if (!transformed)
            {
                yield return obj;
            }
        }

        private LiveTestResult GetLiveTestResult(IEnumerable<object> resultsEnumerable, IServiceTracer tracer)
        {
            LiveTestResult result = new LiveTestResult();
            object[] resultsArray = resultsEnumerable == null ? null : resultsEnumerable.ToArray();
            if (resultsArray == null || resultsArray.Length == 0)
            {
                result.Response = null;
            }
            else if (resultsArray.Length == 1)
            {
                result.Response = resultsArray[0];
            }
            else
            {
                result.Response = resultsArray;
            }

            if (this.HttpResponse)
            {
                HttpResponseMessage responseMessage = tracer.HttpResponses.LastOrDefault();
                if (responseMessage != null)
                {
                    result.StatusCode = (long)responseMessage.StatusCode;
                    Dictionary<string, object> headersDictionary = new Dictionary<string, object>();
                    foreach (KeyValuePair<string, IEnumerable<string>> header in responseMessage.Headers)
                    {
                        string[] headerValues = header.Value.ToArray();
                        // Microsoft.Rest.ClientRuntime.Test expects all headers as arrays
                        headersDictionary[header.Key] = headerValues;
                    }

                    result.Headers = headersDictionary;
                }
            }

            return result;
        }

        private LiveTestResponse MakeBaseResponse()
        {
            LiveTestResponse response = new LiveTestResponse();
            response.Id = this.Id;
            response.JsonRpc = this.JsonRpc;
            return response;
        }
    }
}