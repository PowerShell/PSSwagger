// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using Logging;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;

    /// <summary>
    /// Contains command results.
    /// </summary>
    public class CommandExecutionResult
    {
        /// <summary>
        /// Gets the results of a single command execution.
        /// </summary>
        public IEnumerable<object> Results { get; private set; }

        /// <summary>
        /// Gets the error records from a single command execution.
        /// </summary>
        public IEnumerable<object> Errors { get; private set; }

        /// <summary>
        /// Gets flag indicating if command resulted in one or more errors.
        /// </summary>
        public bool HadErrors { get; private set; }

        public CommandExecutionResult(IEnumerable<object> results, IEnumerable<object> errors, bool hadErrors)
        {
            this.Results = results;
            this.Errors = errors;
            this.HadErrors = hadErrors;
        }

        public void LogErrors(Logger logger)
        {
            if (this.Errors != null)
            {
                foreach (object error in this.Errors)
                {
                    LogError(error, logger);
                }
            }
        }

        private void LogError(object error, Logger logger)
        {
            if (error is Collection<object>)
            {
                foreach (object innerError in (Collection<object>)error)
                {
                    LogError(innerError, logger);
                }
            }
            else
            {
                if (logger != null)
                {
                    logger.LogError(error.ToString());
                }
            }
        }
    }
}