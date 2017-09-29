// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Credentials;
    using Interfaces;
    using Messages;
    using Models;

    /// <summary>
    /// Mock generated module that tracks if methods are called.
    /// </summary>
    public class MockGeneratedModule : GeneratedModule
    {
        public MockGeneratedModule(IRunspaceManager runspace) : base(runspace) { }

        public bool LoadCalled { get; set; }
        public bool ProcessRequestCalled { get; set; }

        public override CommandExecutionResult Load(bool force = false)
        {
            this.LoadCalled = true;
            return null;
        }

        public override CommandExecutionResult ProcessRequest(LiveTestRequest request, LiveTestCredentialFactory credentialsFactory)
        {
            this.ProcessRequestCalled = true;
            return null;
        }
    }
}