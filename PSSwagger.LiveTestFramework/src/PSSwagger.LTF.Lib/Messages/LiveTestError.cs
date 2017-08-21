// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    /// <summary>
    /// Error response from test operation.
    /// </summary>
    public class LiveTestError
    {
        public long Code { get; set; }
        public string Message { get; set; }
        public LiveTestResult Data { get; set; }

        public LiveTestError()
        {
            this.Data = new LiveTestResult();
        }
    }
}