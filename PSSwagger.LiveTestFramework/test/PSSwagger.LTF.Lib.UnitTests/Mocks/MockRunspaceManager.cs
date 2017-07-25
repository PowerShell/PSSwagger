// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Models;
    using System.Collections.Generic;

    /// <summary>
    /// Mock runspace that tracks if methods are called.
    /// </summary>
    public class MockRunspaceManager : IRunspaceManager
    {
        private int commandBuilderIndex = 0;
        public Dictionary<string, GeneratedModule> ModuleMocks { get; private set; }
        public IList<MockCommandBuilder> CommandBuilders { get; private set; }
        public bool GetModuleInfoCalled { get; private set; }
        public IList<object> InvokeHistory { get; private set; }
        public MockRunspaceManager()
        {
            this.ModuleMocks = new Dictionary<string, GeneratedModule>();
            this.CommandBuilders = new List<MockCommandBuilder>();
            this.InvokeHistory = new List<object>();
        }

        public ICommandBuilder CreateCommand()
        {
            MockCommandBuilder builder;
            if (this.CommandBuilders.Count <= commandBuilderIndex)
            {
                builder = new MockCommandBuilder(this);
                this.CommandBuilders.Add(builder);
            } else
            {
                builder = this.CommandBuilders[commandBuilderIndex++];
            }

            return builder;
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
    }
}