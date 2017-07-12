namespace PSSwagger.LTF.Lib.Models
{
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Contains metadata for a single Type whose properties differ from its JSON object representation.
    /// </summary>
    public class TypeData
    {
        /// <summary>
        /// Type represented.
        /// </summary>
        public Type Type { get; set; }

        /// <summary>
        /// Properties of this type. Keyed on the JSON representation.
        /// </summary>
        public IDictionary<string, ParameterData> Properties { get; private set; }

        public TypeData()
        {
            this.Properties = new Dictionary<string, ParameterData>();
        }
    }
}