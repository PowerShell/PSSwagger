// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    /// <summary>
    /// Common JSON-RPC properties.
    /// </summary>
    public class JsonRpcBase
    {
        public string JsonRpc { get; set; }
        public string Id { get; set; }
    }
}