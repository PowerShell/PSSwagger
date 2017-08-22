// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    /// <summary>
    /// An Azure Live Test Framework JSON-RPC response.
    /// </summary>
    public class LiveTestResponse : JsonRpcBase
    {
        public LiveTestResult Result { get; set; }
        public LiveTestError Error { get; set; }
    }
}