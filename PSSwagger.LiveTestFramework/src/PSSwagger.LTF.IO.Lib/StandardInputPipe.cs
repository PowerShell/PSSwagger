namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.Threading.Tasks;

    /// <summary>
    /// Read from STDIN.
    /// </summary>
    public class StandardInputPipe : IInputPipe
    {
        public Task<T> ReadBlock<T>() where T : class
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// NotImplemented
        /// </summary>
        public Task<T> ReadBlockAsync<T>() where T : class
        {
            throw new NotImplementedException();
        }

        public Task<byte> ReadByte()
        {
            throw new NotImplementedException();
        }

        public async Task<char> ReadChar()
        {
            return (char)Console.In.Read();
        }

        public async Task<string> ReadLine()
        {
            return Console.In.ReadLine();
        }
    }
}