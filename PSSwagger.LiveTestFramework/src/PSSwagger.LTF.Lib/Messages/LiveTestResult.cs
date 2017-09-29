// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    /// <summary>
    /// Response data from test operation.
    /// </summary>
    public class LiveTestResult
    {
        public long StatusCode { get; set; }
        public object Headers { get; set; }
        public object Response { get; set; }
    }
}