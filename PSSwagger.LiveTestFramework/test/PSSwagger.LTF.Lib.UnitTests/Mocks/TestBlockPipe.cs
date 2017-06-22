namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Text;
    using Interfaces;
    using Messages;
    using System.Collections.Generic;

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

        public char ReadChar()
        {
            throw new NotImplementedException();
        }

        public void Write(char b)
        {
            throw new NotImplementedException();
        }

        public string ReadLine()
        {
            throw new NotImplementedException();
        }

        public async Task<T> ReadBlockAsync<T>() where T : class
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

        public void WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        public async Task WriteBlockAsync<T>(T msg) where T : class
        {
            if (!(msg is LiveTestResponse))
            {
                throw new NotImplementedException();
            }

            this.Responses.Add(msg as LiveTestResponse);
        }
    }
}