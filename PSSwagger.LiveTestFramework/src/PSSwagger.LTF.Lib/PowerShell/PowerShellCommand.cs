// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.PowerShell
{
    using Interfaces;
    using Models;
    using System;
    using System.Management.Automation.Runspaces;

    /// <summary>
    /// Build a PowerShell command.
    /// </summary>
    public class PowerShellCommand : ICommandBuilder
    {
        private IRunspaceManager runspace;
        private Command powershellCommand;

        public string Command
        {
            get
            {
                if (powershellCommand != null)
                {
                    return powershellCommand.CommandText;
                }

                return String.Empty;
            }
            set
            {
                this.powershellCommand = new Command(value);
            }
        }

        public IRunspaceManager Runspace
        {
            get
            {
                return this.runspace;
            }
        }

        public PowerShellCommand(IRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.powershellCommand = null;
        }

        public ICommandBuilder AddParameter(string parameterName, object parameterValue)
        {
            if (String.IsNullOrEmpty(parameterName))
            {
                throw new ArgumentNullException("parameterName");
            }

            if (this.powershellCommand == null)
            {
                throw new InvalidOperationException("Set the Command property before using AddParameter.");
            }

            this.powershellCommand.Parameters.Add(parameterName, parameterValue);
            return this;
        }

        public CommandExecutionResult Invoke()
        {
            return this.runspace.Invoke(this.powershellCommand);
        }
    }
}