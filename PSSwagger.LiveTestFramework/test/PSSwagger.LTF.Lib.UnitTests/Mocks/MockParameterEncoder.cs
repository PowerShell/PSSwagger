namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;

    /// <summary>
    /// Dummy parameter encoder.
    /// </summary>
    public class MockParameterEncoder : IParameterEncoder
    {
        public bool EncodeCalled { get; set; }
        public object Encode(object parameterValue)
        {
            this.EncodeCalled = true;
            return parameterValue;
        }
    }
}