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