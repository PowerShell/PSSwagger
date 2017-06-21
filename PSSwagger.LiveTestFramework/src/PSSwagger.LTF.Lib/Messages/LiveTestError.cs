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
    }
}