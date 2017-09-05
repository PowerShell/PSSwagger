// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using Interfaces;
    using System.Collections.Generic;

    /// <summary>
    /// Contains metadata for a single operation.
    /// </summary>
    public class OperationData
    {
        /// <summary>
        /// Gets the operation ID as specified by the Open API spec.
        /// </summary>
        public string OperationId { get; private set; }

        /// <summary>
        /// Gets the command corresponding to this operation.
        /// </summary>
        public string Command { get; private set; }

        /// <summary>
        /// Gets or sets the parameters for this operation.
        /// </summary>
        public Dictionary<string, ParameterData> Parameters { get; set; }

        /// <summary>
        /// Gets type data for the expected response Type, if any. PSSwagger currently picks the first response within the 200-299 status code range, if any.
        /// </summary>
        public ResponseTypeData ResponseType { get; set; }

        /// <summary>
        /// Gets the list of post processors.
        /// </summary>
        public IList<ICommandPostProcessor> PostProcessors { get; private set; }

        public OperationData(string operationId, string command)
        {
            this.Command = command;
            this.OperationId = operationId;
            this.Parameters = new Dictionary<string, ParameterData>();
            this.ResponseType = null;
            this.PostProcessors = new List<ICommandPostProcessor>();
        }
    }
}