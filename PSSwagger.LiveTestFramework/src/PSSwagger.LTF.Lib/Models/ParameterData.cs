// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    /// <summary>
    /// Contains metadata for a single parameter.
    /// </summary>
    public class ParameterData
    {
        /// <summary>
        /// Name of the parameter when calling a certain operation
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Name of the parameter when serialized as JSON.
        /// </summary>
        public string JsonName { get; set; }

        /// <summary>
        /// Gets or sets the JSON name used by the Azure C# SDK.
        /// </summary>
        public string SubNodeName { get; set; }

        /// <summary>
        /// Gets or sets the case-sensitive JSON name.
        /// </summary>
        public string RawJsonName { get; set; }

        /// <summary>
        /// Type of this parameter.
        /// </summary>
        public RuntimeTypeData Type { get; set; }

        public void MergeWith(ParameterData newData)
        {
            if (!string.IsNullOrEmpty(newData.Name))
            {
                this.Name = newData.Name;
            }

            if (!string.IsNullOrEmpty(newData.JsonName))
            {
                this.JsonName = newData.JsonName;
            }

            if (newData.Type != null)
            {
                if (this.Type != null)
                {
                    this.Type.MergeWith(newData.Type);
                } else
                {
                    this.Type = newData.Type;
                }
            }
        }

        public ParameterData Clone()
        {
            ParameterData data = new ParameterData();
            data.Name = this.Name;
            data.JsonName = this.JsonName;
            data.SubNodeName = this.SubNodeName;
            data.RawJsonName = this.RawJsonName;
            data.Type = this.Type == null ? null : this.Type.Clone();
            return data;
        }
    }
}