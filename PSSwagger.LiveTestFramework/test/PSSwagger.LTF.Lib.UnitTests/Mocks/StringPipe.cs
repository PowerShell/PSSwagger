namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Text;
    using Interfaces;

    /// <summary>
    /// Basic string input/output interface. Use BufferInputString to add a string to the read buffer.
    /// </summary>
    public class StringPipe : IInputPipe, IOutputPipe
    {
        private StringBuilder buffer;
        private int bufferIndex = 0;
        
        public StringPipe()
        {
            this.buffer = new StringBuilder();
        }

        public void Flush()
        {
        }

        public char ReadChar()
        {
            while (buffer.Length <= bufferIndex)
            {
                Thread.Sleep(1);
            }

            return buffer[bufferIndex++];
        }

        public void Write(char b)
        {
        }

        public void BufferInputString(string line)
        {
            this.buffer.Append(line);
        }

        public string ReadLine()
        {
            throw new NotImplementedException();
        }

        public Task<T> ReadBlockAsync<T>() where T : class
        {
            throw new NotImplementedException();
        }

        public void WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        public Task WriteBlockAsync<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }
    }
}