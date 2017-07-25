// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Messages
{
    using System.Collections.Generic;

    /// <summary>
    /// An Azure Live Test Framework extended credentials object.
    /// </summary>
    public class LiveTestCredentials
    {
        public string Type { get; set; }
        public Dictionary<string, object> Properties { get; set; }

        public LiveTestCredentials()
        {
            this.Properties = new Dictionary<string, object>();
        }
    }
}