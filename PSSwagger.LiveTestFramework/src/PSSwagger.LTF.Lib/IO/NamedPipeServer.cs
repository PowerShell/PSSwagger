namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.IO;
    using System.IO.Pipes;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// I/O operations for named pipe server.
    /// </summary>
    public class NamedPipeServer : IOutputPipe, IInputPipe, IDisposable
    {
        private NamedPipeServerStream stream;
        private StreamReader reader;

        /// <summary>
        /// Create a named pipe server on the local machine.
        /// </summary>
        /// <param name="pipeName">Name of pipe.</param>
        public NamedPipeServer(string pipeName)
        {
            this.stream = new NamedPipeServerStream(pipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous);
            this.reader = null;
            this.stream.BeginWaitForConnection(new AsyncCallback((IAsyncResult r) => {
                ((NamedPipeServerStream)r.AsyncState).EndWaitForConnection(r);
                this.reader = new StreamReader((NamedPipeServerStream)r.AsyncState);
            }), this.stream);
        }

        /// <summary>
        /// Dispose the inner StreamReader and NamedPipeServerStream.
        /// </summary>
        public void Dispose()
        {
            if (this.reader != null)
            {
                this.reader.Dispose();
            }
            if (this.stream != null)
            {
                this.stream.Dispose();
            }
        }

        /// <summary>
        /// Flush the inner NamedPipeServerStream.
        /// </summary>
        public void Flush()
        {
            this.stream.Flush();
        }

        /// <summary>
        /// Read a single character.
        /// </summary>
        /// <returns>Character read.</returns>
        public char ReadChar()
        {
            WaitForConnection();
            return (char)reader.Read();
        }

        /// <summary>
        /// Write a single character.
        /// </summary>
        /// <param name="b">Character to write.</param>
        public void Write(char b)
        {
            WaitForConnection();
            byte[] buf = BitConverter.GetBytes(b);
            this.stream.Write(buf, 0, buf.Length);
        }

        /// <summary>
        /// Write the given string then a new line in UTF-8.
        /// </summary>
        /// <param name="line">Line to write, not including new line.</param>
        public void WriteLine(string line)
        {
            WaitForConnection();
            byte[] buf = Encoding.UTF8.GetBytes(line);
            byte[] newLine = Encoding.UTF8.GetBytes(Environment.NewLine);
            byte[] charBuf = new byte[buf.Length + newLine.Length];
            Array.Copy(buf, charBuf, buf.Length);
            Array.Copy(newLine, 0, charBuf, buf.Length, newLine.Length);
            this.stream.Write(charBuf, 0, charBuf.Length);
        }

        /// <summary>
        /// Read until the next new line character.
        /// </summary>
        /// <returns>All text input up to but not including the new line character.</returns>
        public string ReadLine()
        {
            WaitForConnection();
            return this.reader.ReadLine();
        }

        /// <summary>
        /// NotImplemented
        /// </summary>
        public Task WriteBlockAsync<T>(T msg) where T : class
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

        /// <summary>
        /// Sleep until a client connects.
        /// </summary>
        private void WaitForConnection()
        {
            while (!this.stream.IsConnected)
            {
                Thread.Sleep(1);
            }
        }
    }
}