namespace PSSwagger.LTF.Lib.UnitTests
{
    using Mocks;
    using PowerShell;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for PowerShellParameterEncoder type.
    /// </summary>
    public class PowerShellParameterEncoderTests
    {
        private readonly XUnitOutputPipe output;
        public PowerShellParameterEncoderTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
        }

        /// <summary>
        /// Test that an escaped string value is encoded correctly.
        /// </summary>
        [Fact]
        public void ConvertsEscapedString()
        {
            object testValue = "This is a \"string\" that is also \\\"escaped\\\" and contains the 'little' ones.";
            PowerShellParameterEncoder encoder = new PowerShellParameterEncoder();
            object actualValue = encoder.Encode(testValue);
            object expectedValue = "'This is a \"string\" that is also \\\"escaped\\\" and contains the ''little'' ones.'";
            Assert.Equal(expectedValue, actualValue);
        }
    }
}