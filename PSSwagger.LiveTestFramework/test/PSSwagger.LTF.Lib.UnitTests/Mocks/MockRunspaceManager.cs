namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using System.Collections;
    using Messages;
    using Interfaces;
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Mock runspace that tracks if methods are called.
    /// </summary>
    public class MockRunspaceManager : IRunspaceManager
    {
        public Dictionary<string, GeneratedModule> ModuleMocks { get; private set; }
        public MockCommandBuilder Builder { get; private set; }
        public bool GetModuleInfoCalled { get; private set; }

        public MockRunspaceManager()
        {
            this.ModuleMocks = new Dictionary<string, GeneratedModule>();
            this.Builder = new MockCommandBuilder();
        }

        public ICommandBuilder CreateCommand()
        {
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

        public IEnumerable Invoke(string script)
        {
            throw new NotImplementedException();
        }

        public void SetSessionVariable(string variableName, object variableValue)
        {
            throw new NotImplementedException();
        }
    }
}