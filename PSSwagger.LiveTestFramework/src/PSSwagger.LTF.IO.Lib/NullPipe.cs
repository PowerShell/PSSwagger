// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System.Threading.Tasks;
    using System;

    /// <summary>
    /// Ignores all IO. Returns defaults on read.
    /// </summary>
    public class NullPipe : IInputPipe, IOutputPipe
    {
        public void Flush()
        {
        }

        public async Task<T> ReadBlock<T>() where T : class
        {
            return default(T);
        }

        public Task<byte> ReadByte()
        {
            throw new NotImplementedException();
        }

        public async Task<char> ReadChar()
        {
            throw new NotImplementedException();
        }

        public async Task<string> ReadLine()
        {
            return default(string);
        }

        public async Task Write(char b)
        {
        }

        public async Task WriteBlock<T>(T msg) where T : class
        {
        }

        public async Task WriteLine(string line)
        {
        }
    }
}