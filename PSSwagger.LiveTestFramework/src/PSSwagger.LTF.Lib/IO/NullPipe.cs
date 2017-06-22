namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System.Threading.Tasks;

    /// <summary>
    /// Ignores all IO. Returns defaults on read.
    /// </summary>
    public class NullPipe : IInputPipe, IOutputPipe
    {
        public void Flush()
        {
        }

        public char ReadChar()
        {
            return default(char);
        }

        public void Write(char b)
        {
        }

        public async Task<T> ReadBlockAsync<T>() where T : class
        {
            return default(T);
        }

        public async Task WriteBlockAsync<T>(T msg) where T : class
        {
        }

        public string ReadLine()
        {
            return default(string);
        }

        public void WriteLine(string line)
        {
        }
    }
}