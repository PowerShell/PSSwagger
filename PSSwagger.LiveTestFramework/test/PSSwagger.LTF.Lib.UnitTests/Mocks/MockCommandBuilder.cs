// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Models;
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

    /// <summary>
    /// Mock command builder. Collects parameters and history of Invoke calls.
    /// </summary>
    public class MockCommandBuilder : ICommandBuilder
    {
        private IRunspaceManager runspace;
        public Dictionary<string, object> Parameters { get; private set; }
        public string Command { get; set; }
        public IList<string> InvokeHistory { get; private set; }
        public CommandExecutionResult MockResult { get; set; }
        public IRunspaceManager Runspace
        {
            get
            {
                return runspace;
            }
        }

        public MockCommandBuilder(MockRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.Parameters = new Dictionary<string, object>();
            this.InvokeHistory = new List<string>();
        }

        public ICommandBuilder AddParameter(string parameterName, object parameterValue)
        {
            this.Parameters[parameterName] = parameterValue;
            return this;
        }

        public CommandExecutionResult Invoke()
        {
            // Format for mock is: command [parameterName parameterValue.ToString() isSwitch]+
            string invokeString = this.Command;
            if (this.Parameters.Keys.Count > 0)
            {
                foreach (string key in this.Parameters.Keys)
                {
                    string encodedVal = this.Parameters[key] == null ? "null" : this.Parameters[key].ToString();
                    if (this.Parameters[key] is System.Management.Automation.PSCredential)
                    {
                        System.Management.Automation.PSCredential specificType = (System.Management.Automation.PSCredential)this.Parameters[key];
                        string password = String.Empty;
                        IntPtr valuePtr = IntPtr.Zero;
                        try
                        {
                            valuePtr = Marshal.SecureStringToGlobalAllocUnicode(specificType.Password);
                            password = Marshal.PtrToStringUni(valuePtr);
                        }
                        finally
                        {
                            Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
                        }

                        encodedVal = "(" + specificType.UserName + " " + password + ")";
                    }

                    invokeString += String.Format(" [{0} {1}]", key, encodedVal);
                }
            }

            this.runspace.Invoke(invokeString);

            return this.MockResult;
        }
    }
}