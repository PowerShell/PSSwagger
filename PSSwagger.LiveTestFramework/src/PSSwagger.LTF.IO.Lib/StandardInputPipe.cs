// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.Collections.Concurrent;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>
    /// Read from STDIN.
    /// </summary>
    public class StandardInputPipe : IInputPipe
    {
        private ConcurrentQueue<byte> byteQueue = new ConcurrentQueue<byte>();

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

        public async Task<byte> ReadByte()
        {
            while (byteQueue.Count > 0)
            {
                byte b;
                if (byteQueue.TryDequeue(out b))
                {
                    return b;
                }
            }

            while (true)
            {
                while (byteQueue.Count > 0)
                {
                    byte b;
                    if (byteQueue.TryDequeue(out b))
                    {
                        return b;
                    }
                }

                char c = await ReadChar();
                foreach (byte b in Encoding.UTF8.GetBytes(new char[] { c }))
                {
                    byteQueue.Enqueue(b);
                }
            }
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