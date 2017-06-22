namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.Threading.Tasks;

    /// <summary>
    /// Read from STDOUT.
    /// </summary>
    public class StandardOutputPipe : IOutputPipe
    {
        /// <summary>
        /// Write a single character to System.Console.
        /// </summary>
        /// <param name="b">Character to write.</param>
        public void Write(char b)
        {
            Console.Write(b);
        }

        /// <summary>
        /// NotImplemented
        /// </summary>
        public Task WriteBlockAsync<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Write the given string then a new line to System.Console.
        /// </summary>
        /// <param name="line">Line to write, not including new line.</param>
        public void WriteLine(string line)
        {
            Console.WriteLine(line);
        }
    }
}