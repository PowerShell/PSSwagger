// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Messages;
    using System;
    using System.Collections.Generic;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// Test interface for pushing LiveTestRequest blocks to input and getting LiveTestResponse from output.
    /// </summary>
    public class TestBlockPipe : IInputPipe, IOutputPipe
    {
        public List<LiveTestResponse> Responses { get; private set; }
        public Queue<LiveTestRequest> Requests { get; private set; }

        public TestBlockPipe()
        {
            this.Responses = new List<LiveTestResponse>();
            this.Requests = new Queue<LiveTestRequest>();
        }

        public void Flush()
        {
        }

        public Task<char> ReadChar()
        {
            throw new NotImplementedException();
        }

        public Task Write(char b)
        {
            throw new NotImplementedException();
        }

        public Task<string> ReadLine()
        {
            throw new NotImplementedException();
        }

        public async Task<T> ReadBlock<T>() where T : class
        {
            if (typeof(T) != typeof(LiveTestRequest))
            {
                throw new NotImplementedException();
            }

            while (this.Requests.Count == 0)
            {
                Thread.Sleep(1);
            }

            return this.Requests.Dequeue() as T;
        }

        public Task WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        public async Task WriteBlock<T>(T msg) where T : class
        {
            if (!(msg is LiveTestResponse))
            {
                throw new NotImplementedException();
            }

            this.Responses.Add(msg as LiveTestResponse);
        }

        public Task<byte> ReadByte()
        {
            throw new NotImplementedException();
        }
    }
}