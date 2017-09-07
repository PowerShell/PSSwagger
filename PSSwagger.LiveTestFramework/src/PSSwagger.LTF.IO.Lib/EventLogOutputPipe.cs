// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.Diagnostics;
    using System.Threading.Tasks;

    /// <summary>
    /// Read from STDOUT.
    /// </summary>
    public class EventLogOutputPipe : IOutputPipe
    {
        public Task Write(char b)
        {
            throw new NotImplementedException();
        }

        public Task WriteBlock<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }
        
        public Task WriteBlockAsync<T>(T msg) where T : class
        {
            throw new NotImplementedException();
        }

        public async Task WriteLine(string line)
        {
            using (EventLog eventLog = new EventLog("Application"))
            {
                eventLog.Source = "Application";
                eventLog.WriteEntry(line);
            }
        }
    }
}