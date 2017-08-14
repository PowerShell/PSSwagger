// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Xunit.Abstractions;

    /// <summary>
    /// Read from STDOUT.
    /// </summary>
    public class XUnitOutputPipe : IOutputPipe
    {
        private ITestOutputHelper output;
        private bool logAsErrors;

        public IList<string> Errors { get; set; }

        public XUnitOutputPipe(ITestOutputHelper output, bool logAsErrors = false)
        {
            this.output = output;
            this.logAsErrors = logAsErrors;
            this.Errors = new List<string>();
        }

        /// <summary>
        /// Write a single character + newline to inner ITestOutputHelper.
        /// </summary>
        /// <param name="b">Character to write.</param>
        public async Task Write(char b)
        {
            if (this.logAsErrors)
            {
                this.Errors.Add(b.ToString());
            }
            this.output.WriteLine(b.ToString());
        }

        /// <summary>
        /// Serialize <param name="msg" /> into JSON then write to inner ITestOutputHelper.
        /// </summary>
        public async Task WriteBlock<T>(T msg) where T : class
        {
            if (msg != null)
            {
                string json = Newtonsoft.Json.JsonConvert.SerializeObject(msg);
                if (this.logAsErrors)
                {
                    this.Errors.Add(json);
                }
                this.output.WriteLine(json);
            }
        }

        /// <summary>
        /// Write the given string then a new line to inner ITestOutputHelper.
        /// </summary>
        /// <param name="line">Line to write, not including new line.</param>
        public async Task WriteLine(string line)
        {
            if (this.logAsErrors)
            {
                this.Errors.Add(line);
            }
            this.output.WriteLine(line);
        }
    }
}