// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib
{
    using Interfaces;
    using Models;
    using System;
    using System.Globalization;

    /// <summary>
    /// Exception thrown when a command fails to execute.
    /// </summary>
    public class CommandFailedException : Exception
    {
        public ICommandBuilder Command { get; private set; }
        public CommandExecutionResult Result { get; private set; }
        public string UserMessage { get; private set; }

        public CommandFailedException(ICommandBuilder command, CommandExecutionResult result) : this(command, result, String.Empty) { }

        public CommandFailedException(ICommandBuilder command, CommandExecutionResult result, string message)
        {
            this.Command = command;
            this.Result = result;
            this.UserMessage = message;
        }

        public override string Message
        {
            get
            {
                string msg;
                if (this.Command != null)
                {
                    msg = String.Format(CultureInfo.CurrentCulture, "Failed to execute command '{0}'. Reason: {1}", this.Command.Command, this.UserMessage);
                } else
                {
                    msg = this.UserMessage;
                }

                return msg;
            }
        }
    }
}