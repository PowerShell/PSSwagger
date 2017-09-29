// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using System;
    using System.Collections.Generic;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// Basic string input/output interface. Use BufferInputString to add a string to the read buffer.
    /// </summary>
    public class StringPipe : IInputPipe, IOutputPipe
    {
        private StringBuilder buffer;
        private int bufferIndex = 0;
        private Queue<byte> byteQueue = new Queue<byte>();
        public StringBuilder OutputBuffer { get; private set; }
        public StringPipe()
        {
            this.buffer = new StringBuilder();
            this.OutputBuffer = new StringBuilder();
        }

        public void Flush()
        {
        }

        public async Task<char> ReadChar()
        {
            while (buffer.Length <= bufferIndex)
            {
                Thread.Sleep(1);
            }

            return buffer[bufferIndex++];
        }

        public async Task Write(char b)
        {
            this.OutputBuffer.Append(b);
        }

        public void BufferInputString(string str)
        {
            this.buffer.Append(str);
        }

        public void BufferJsonRpcBlock(object message, string type = null)
        {
            string messageSerialized = Newtonsoft.Json.JsonConvert.SerializeObject(message);
            StringBuilder sb = new StringBuilder();
            sb.Append("Content-Length: " + Encoding.ASCII.GetByteCount(messageSerialized) + "\r\n");
            if (!String.IsNullOrEmpty(type))
            {
                sb.Append("Content-Type: " + type + "\r\n");
            }
            sb.Append("\r\n");
            sb.Append(messageSerialized);
            this.buffer.Append(sb.ToString());
        }

        public Task<string> ReadLine()
        {
            throw new NotImplementedException();
        }

        public Task<T> ReadBlock<T>() where T : class
        {
            throw new NotImplementedException();
        }

        public async Task WriteLine(string line)
        {
            this.OutputBuffer.AppendLine(line);
        }

        public Task WriteBlock<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        public async Task<byte> ReadByte()
        {
            if (this.byteQueue.Count > 0)
            {
                return this.byteQueue.Dequeue();
            }

            while (buffer.Length <= bufferIndex)
            {
                Thread.Sleep(1);
            }

            foreach (byte b in Encoding.ASCII.GetBytes(new char[] { buffer[bufferIndex++] }))
            {
                this.byteQueue.Enqueue(b);
            }

            return this.byteQueue.Dequeue();
        }
    }
}