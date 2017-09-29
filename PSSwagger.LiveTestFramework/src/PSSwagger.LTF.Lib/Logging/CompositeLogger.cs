// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Logging
{
    using Interfaces;
    using Newtonsoft.Json;
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Globalization;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>
    /// Logging interface.
    /// </summary>
    public class CompositeLogger : Logger
    {
        private IList<Logger> InternalLoggers { get; set; }

        public CompositeLogger() : base(null, null)
        {
            this.InternalLoggers = new List<Logger>();
        }

        public CompositeLogger AddLogger(Logger logger)
        {
            if (logger == null)
            {
                throw new ArgumentNullException("logger");
            }

            this.InternalLoggers.Add(logger);
            return this;
        }

        /// <summary>
        /// Log a single message to output pipe.
        /// </summary>
        /// <param name="message">Message to log.</param>
        public override void Log(string message, params object[] args)
        {
            if (String.IsNullOrEmpty(message))
            {
                return;
            }

            foreach (Logger logger in this.InternalLoggers)
            {
                logger.Log(message, args);
            }
        }

        /// <summary>
        /// Serialize objects into JSON then asynchronously log the final formatted message. Recommended to run this log in a Task.Run context so the object serialization is also async.
        /// </summary>
        /// <param name="message">Message with format parameters.</param>
        /// <param name="objs">Objects to serialize.</param>
        public override async Task LogAsync(string message, params object[] objs)
        {
            if (String.IsNullOrEmpty(message))
            {
                return;
            }

            foreach (Logger logger in this.InternalLoggers)
            {
                logger.LogAsync(message);
            }
        }

        /// <summary>
        /// Log a single message to error pipe.
        /// </summary>
        /// <param name="message"></param>
        public void LogError(string message)
        {
            if (String.IsNullOrEmpty(message))
            {
                return;
            }

            foreach (Logger logger in this.InternalLoggers)
            {
                logger.LogError(message);
            }
        }
    }
}