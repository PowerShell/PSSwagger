// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Logging
{
    using Interfaces;
    using Newtonsoft.Json;
    using System;
    using System.Globalization;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>
    /// Logging interface.
    /// </summary>
    public class Logger
    {
        private IOutputPipe stdout;
        private IOutputPipe stderr;
        private bool timestamp;
        private bool loggingLevel;

        public JsonSerializerSettings JsonSerializerSettings { get; set; }

        public Logger(IOutputPipe stdout, IOutputPipe stderr, bool timestamp = true, bool loggingLevel = true)
        {
            this.stdout = stdout;
            this.stderr = stderr;
            this.timestamp = timestamp;
            this.loggingLevel = loggingLevel;
            this.JsonSerializerSettings = new JsonSerializerSettings();
        }

        /// <summary>
        /// Log a single message to output pipe.
        /// </summary>
        /// <param name="message">Message to log.</param>
        public virtual void Log(string message, params object[] args)
        {
            if (this.stdout != null)
            {
                string msg = message;
                if (args != null && args.Length > 0)
                {
                    msg = String.Format(message, args);
                }

                this.stdout.WriteLine(FormatMessage(msg, "info"));
            }
        }

        /// <summary>
        /// Serialize objects into JSON then asynchronously log the final formatted message. Recommended to run this log in a Task.Run context so the object serialization is also async.
        /// </summary>
        /// <param name="message">Message with format parameters.</param>
        /// <param name="objs">Objects to serialize.</param>
        public virtual async Task LogAsync(string message, params object[] objs)
        {
            string[] objSerialized = new string[objs.Length];
            for (int i = 0; i < objs.Length; i++)
            {
                object objToSerialize = objs[i];
                if (objToSerialize != null)
                {
                    if (objToSerialize is System.Management.Automation.PSObject)
                    {
                        objToSerialize = ((System.Management.Automation.PSObject)objToSerialize).ImmediateBaseObject;
                    }
                    objSerialized[i] = Newtonsoft.Json.JsonConvert.SerializeObject(objToSerialize, this.JsonSerializerSettings);
                } else
                {
                    objSerialized[i] = "null";
                }
            }

            this.Log(String.Format(CultureInfo.CurrentCulture, message, objSerialized));
        }

        /// <summary>
        /// Log a single message to error pipe.
        /// </summary>
        /// <param name="message"></param>
        public virtual void LogError(string message)
        {
            if (this.stderr != null)
            {
                this.stderr.WriteLine(FormatMessage(message, "error"));
            }
        }

        /// <summary>
        /// Format a message with log level and timestamp, if specified in the constructor.
        /// </summary>
        /// <param name="message">Message.</param>
        /// <param name="logLevel">Log level.</param>
        /// <returns>Formatted message.</returns>
        private string FormatMessage(string message, string logLevel)
        {
            StringBuilder sb = new StringBuilder();
            if (this.timestamp)
            {
                sb.AppendFormat("{0}: ", DateTime.Now.ToShortTimeString());
            }

            if (this.loggingLevel)
            {
                sb.AppendFormat("({0}) ", logLevel);
            }

            sb.Append(message);
            return sb.ToString();
        }
    }
}