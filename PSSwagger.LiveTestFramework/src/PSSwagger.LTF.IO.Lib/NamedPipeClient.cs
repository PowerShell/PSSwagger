// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.IO;
    using System.IO.Pipes;
    using System.Threading;
    using System.Threading.Tasks;

    public delegate void NamedPipeClientDataReceived(string message);

    /// <summary>
    /// I/O operations for named pipe client.
    /// </summary>
    public class NamedPipeClient : IInputPipe, IOutputPipe, IDisposable
    {
        private NamedPipeClientStream stream;
        private StreamReader reader;
        private StreamWriter writer;

        /// <summary>
        /// Fired when the client reads a new line of data in its asynchronous processing thread.
        /// </summary>
        public event NamedPipeClientDataReceived OnDataReceived;

        /// <summary>
        /// Gets if the named pipe client is connected.
        /// </summary>
        public bool IsConnected
        {
            get
            {
                return this.stream.IsConnected;
            }
        }

        /// <summary>
        /// Gets if the named pipe client has more inbound data.
        /// </summary>
        public bool HasMoreData
        {
            get
            {
                try
                {
                    return this.stream.InBufferSize > 0;
                } catch (Exception)
                {
                    return false;
                }
            }
        }


        /// <summary>
        /// Create a named pipe client on the local machine.
        /// </summary>
        /// <param name="pipeName">Name of pipe.</param>
        public NamedPipeClient(string pipeName)
        {
            this.stream = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut);
            this.reader = null;
            this.writer = null;
        }

        /// <summary>
        /// Connect to the named pipe.
        /// </summary>
        public void Connect()
        {
            this.stream.Connect();
            this.reader = new StreamReader(this.stream);
            this.writer = new StreamWriter(this.stream);
        }

        /// <summary>
        /// Start the data processing thread.
        /// </summary>
        public void BeginProcessing()
        {
            new Thread(async () =>
            {
                while (this.stream.IsConnected)
                {
                    string line = await this.ReadLine();
                    if (OnDataReceived != null)
                    {
                        OnDataReceived.Invoke(line);
                    }
                }
            }){ IsBackground = true }.Start();
        }

        /// <summary>
        /// Dispose the StreamReader, StreamWriter, and NamedClientPipeStream.
        /// </summary>
        public void Dispose()
        {
            if (this.reader != null)
            {
                this.reader.Dispose();
            }
            if (this.writer != null)
            {
                this.writer.Dispose();
            }
            if (this.stream != null)
            {
                this.stream.Dispose();
            }
        }

        /// <summary>
        /// Flush the NamedClientPipeStream.
        /// </summary>
        public void Flush()
        {
            this.stream.Flush();
        }

        /// <summary>
        /// Read a single character.
        /// </summary>
        /// <returns>Character read.</returns>
        public async Task<char> ReadChar()
        {
            return (char)this.reader.Read();
        }

        /// <summary>
        /// Write a single character.
        /// </summary>
        /// <param name="b">Character to write.</param>
        public void Write(char b)
        {
            this.writer.Write(b);
        }

        /// <summary>
        /// Write the given string then a new line.
        /// </summary>
        /// <param name="line">Line to write, not including new line.</param>
        public void WriteLine(string line)
        {
            this.writer.WriteLine(line);
        }

        public async Task<string> ReadLine()
        {
            return this.reader.ReadLine();
        }

        public Task<T> ReadBlock<T>() where T : class
        {
            throw new NotImplementedException();
        }

        Task IOutputPipe.Write(char b)
        {
            throw new NotImplementedException();
        }

        Task IOutputPipe.WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        public Task WriteBlock<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        public Task<byte> ReadByte()
        {
            throw new NotImplementedException();
        }
    }
}