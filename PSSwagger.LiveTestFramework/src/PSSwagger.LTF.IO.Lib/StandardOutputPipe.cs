// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
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
        public async Task Write(char b)
        {
            Console.Write(b);
        }

        public Task WriteBlock<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// NotImplemented
        /// </summary>
        public Task WriteBlockAsync<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        public async Task WriteLine(string line)
        {
            Console.WriteLine(line);
        }
    }
}