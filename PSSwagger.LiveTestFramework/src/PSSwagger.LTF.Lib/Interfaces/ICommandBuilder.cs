// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using Models;

    /// <summary>
    /// Build commands to execute test operations.
    /// </summary>
    public interface ICommandBuilder
    {
        /// <summary>
        /// Gets or sets the current command.
        /// </summary>
        string Command { get; set; }

        /// <summary>
        /// Gets the parent runspace.
        /// </summary>
        IRunspaceManager Runspace { get; }

        /// <summary>
        /// Adds the given parameter.
        /// </summary>
        /// <param name="parameterName">Case insensitive name of parameter.</param>
        /// <param name="parameterValue">Parameter value.</param>
        /// <returns>This command builder.</returns>
        ICommandBuilder AddParameter(string parameterName, object parameterValue);

        /// <summary>
        /// Execute the command in the parent runspace.
        /// </summary>
        /// <returns>Results of command.</returns>
        CommandExecutionResult Invoke();
    }
}