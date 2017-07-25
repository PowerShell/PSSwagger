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

        public LiveTestResponse MakeResponse(CommandExecutionResult commandResult, IServiceTracer tracer, Logger logger)
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
                response.Error.Data = GetLiveTestResult(commandResult.Errors, tracer);
            }
            else
            {
                if (logger != null)
                {
                    logger.LogAsync("Command executed successfully.");
                }

                response.Result = GetLiveTestResult(commandResult.Results, tracer);
            }

            return response;
        }

        public LiveTestResponse MakeResponse(Exception ex, int errorCode)
        {
            LiveTestResponse response = MakeBaseResponse();
            response.Error = new LiveTestError();
            response.Error.Code = errorCode;
            response.Error.Data.Response = ex;
            return response;
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
                        if (headerValues.Length == 1)
                        {
                            headersDictionary[header.Key] = headerValues[0];
                        }
                        else if (headerValues.Length > 1)
                        {
                            headersDictionary[header.Key] = headerValues;
                        }
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