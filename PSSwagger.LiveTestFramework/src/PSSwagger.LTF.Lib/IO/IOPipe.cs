namespace PSSwagger.LTF.Lib.IO
{
    using System;
    using System.Threading.Tasks;

    /// <summary>
    /// Abstract class to represent a generic input/output pipe.
    /// </summary>
    public abstract class IOPipe
    {
        /// <summary>
        /// Read the next character from the pipe.
        /// </summary>
        /// <returns></returns>
        public abstract char ReadChar();

        /// <summary>
        /// Write a single character to the pipe.
        /// </summary>
        /// <param name="b"></param>
        public abstract void Write(char b);

        /// <summary>
        /// Flush any remaining bytes in the output buffer.
        /// </summary>
        public abstract void Flush();

        /// <summary>
        /// Write a line + the new line character to the output buffer.
        /// </summary>
        /// <param name="line"></param>
        public virtual void WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Read a line + the new line character. Should not return until the new line character has been read. Should not return the new line character.
        /// </summary>
        /// <param name="line"></param>
        public virtual string ReadLine()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Read a message block from the pipe.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public virtual async Task<T> ReadBlockAsync<T>()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Write and flush a message block to the pipe.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="msg"></param>
        public virtual async void WriteBlockAsync<T>(T msg)
        {
            throw new NotImplementedException();
        }
    }
}
