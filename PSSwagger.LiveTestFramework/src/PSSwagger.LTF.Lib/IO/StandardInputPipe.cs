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
        /// <summary>
        /// NotImplemented
        /// </summary>
        public Task<T> ReadBlockAsync<T>() where T : class
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Read a single character from System.Console.
        /// </summary>
        /// <returns>Character read.</returns>
        public char ReadChar()
        {
            return (char)Console.In.Read();
        }

        /// <summary>
        /// Read until the next new line character from System.Console.
        /// </summary>
        /// <returns>All text input up to but not including the new line character.</returns>
        public string ReadLine()
        {
            return Console.ReadLine();
        }
    }
}