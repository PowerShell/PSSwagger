namespace PSSwagger.LTF.Lib.Models
{
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

        public OperationData(string operationId, string command)
        {
            this.Command = command;
            this.OperationId = operationId;
            this.Parameters = new Dictionary<string, ParameterData>();
        }
    }
}