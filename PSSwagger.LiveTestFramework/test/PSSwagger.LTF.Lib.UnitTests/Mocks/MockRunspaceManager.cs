namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using System.Collections;
    using Messages;
    using Interfaces;
    using System;
    using System.Collections.Generic;
    using Models;

    /// <summary>
    /// Mock runspace that tracks if methods are called.
    /// </summary>
    public class MockRunspaceManager : IRunspaceManager
    {
        public Dictionary<string, GeneratedModule> ModuleMocks { get; private set; }
        public MockCommandBuilder Builder { get; private set; }
        public bool GetModuleInfoCalled { get; private set; }
        public IList<object> InvokeHistory { get; private set; }
        public MockParameterEncoder Encoder { get; private set; }
        public MockRunspaceManager()
        {
            this.ModuleMocks = new Dictionary<string, GeneratedModule>();
            this.Builder = new MockCommandBuilder(this);
            this.InvokeHistory = new List<object>();
            this.Encoder = new MockParameterEncoder();
        }

        public ICommandBuilder CreateCommand()
        {
            this.Builder.Parameters.Clear();
            return this.Builder;
        }

        public GeneratedModule GetModuleInfo(string modulePath)
        {
            this.GetModuleInfoCalled = true;
            if (this.ModuleMocks.ContainsKey(modulePath))
            {
                return this.ModuleMocks[modulePath];
            }

            return null;
        }

        public CommandExecutionResult Invoke(object script)
        {
            this.InvokeHistory.Add(script);
            return null;
        }

        public IParameterEncoder CreateEncoder()
        {
            return this.Encoder;
        }
    }
}