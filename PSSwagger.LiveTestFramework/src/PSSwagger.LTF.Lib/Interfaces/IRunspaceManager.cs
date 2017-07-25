// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using Models;
    using System.Collections;
    using System.Collections.Generic;

    /// <summary>
    /// Manages the execution space for running test commands.
    /// </summary>
    public interface IRunspaceManager
    {
        /// <summary>
        /// Execute a given command in this runspace.
        /// </summary>
        /// <param name="command">Raw command to execute. The exact type depends on the runspace.</param>
        /// <returns>Result of command execution.</returns>
        CommandExecutionResult Invoke(object command);

        /// <summary>
        /// Create an ICommandBuilder for this runspace.
        /// </summary>
        /// <returns>ICommandBuilder for this runspace.</returns>
        ICommandBuilder CreateCommand();

        /// <summary>
        /// Parse module information in the context of this runspace.
        /// </summary>
        /// <param name="modulePath">Path to module or module name.</param>
        /// <returns>Parsed module information struct.</returns>
        GeneratedModule GetModuleInfo(string modulePath);
    }
}