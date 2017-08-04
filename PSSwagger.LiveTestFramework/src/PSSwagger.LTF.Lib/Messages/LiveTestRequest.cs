namespace PSSwagger.LTF.Lib.Messages
{
    using System.Collections.Generic;

    /// <summary>
    /// An Azure Live Test Framework JSON-RPC request.
    /// </summary>
    public class LiveTestRequest : JsonRpcBase
    {
        public string Method { get; set; }
        public Dictionary<string, object> Params { get; set; }
    }
}