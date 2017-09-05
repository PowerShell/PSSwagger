// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Contains metadata for a single Type whose properties differ from its JSON object representation.
    /// </summary>
    public class RuntimeTypeData
    {
        /// <summary>
        /// Type represented.
        /// </summary>
        public Type Type { get; set; }

        /// <summary>
        /// Type data for types used by collection types (e.g. System.Array).
        /// </summary>
        public IList<RuntimeTypeData> CollectionTypes { get; private set; }

        /// <summary>
        /// Properties of this type. Keyed on the JSON representation.
        /// </summary>
        public IDictionary<string, ParameterData> Properties { get; set; }

        public RuntimeTypeData() : this(null)
        {
        }

        public RuntimeTypeData(Type t)
        {
            this.Properties = new Dictionary<string, ParameterData>();
            this.Type = t;
            this.CollectionTypes = new List<RuntimeTypeData>();
        }

        public void MergeWith(RuntimeTypeData newData)
        {
            if (newData.Type != null)
            {
                this.Type = newData.Type;
            }

            if (newData.CollectionTypes != null)
            {
                this.CollectionTypes = newData.CollectionTypes;
            }

            if (newData.Properties != null)
            {
                this.Properties = newData.Properties;
            }
        }

        public RuntimeTypeData Clone()
        {
            RuntimeTypeData data = new RuntimeTypeData();
            data.Type = this.Type;
            foreach (RuntimeTypeData d in this.CollectionTypes)
            {
                data.CollectionTypes.Add(d.Clone());
            }

            foreach (string key in this.Properties.Keys)
            {
                data.Properties[key] = this.Properties[key].Clone();
            }

            return data;
        }
    }
}