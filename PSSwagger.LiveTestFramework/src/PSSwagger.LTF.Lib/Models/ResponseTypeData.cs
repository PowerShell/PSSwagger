// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Contains metadata for a single command output type.
    /// </summary>
    public class ResponseTypeData
    {
        /// <summary>
        /// Gets or sets type data retrieved from specification(s).
        /// </summary>
        public IList<RuntimeTypeData> SpecificationData { get; set; }

        /// <summary>
        /// Gets or sets type data retrieved from the module.
        /// </summary>
        public RuntimeTypeData ModuleData { get; set; }

        /// <summary>
        /// Gets merged type data.
        /// </summary>
        public RuntimeTypeData TypeData { get; private set; }

        /// <summary>
        /// Gets or sets the .NET type for the page container, if any.
        /// </summary>
        public Type PageType { get; set; }

        public ResponseTypeData()
        {
            this.SpecificationData = new List<RuntimeTypeData>();
        }

        /// <summary>
        /// Complete creation of this response type by merging all sources of data.
        /// </summary>
        public void Complete()
        {
            this.TypeData = this.ModuleData;
            RuntimeTypeData specificationData = FindBestMatchingSpecification(this.ModuleData.Type);
            if (specificationData != null)
            {
                this.TypeData.MergeWith(specificationData);
            }
        }

        /// <summary>
        /// Find the item in SpecificationData whose properties best match the given .NET type.
        /// </summary>
        private RuntimeTypeData FindBestMatchingSpecification(Type netType)
        {
            RuntimeTypeData bestMatch = null;
            int bestMatchingPropertiesCount = 0;
            Dictionary<string, System.Reflection.PropertyInfo> netProperties = new Dictionary<string, System.Reflection.PropertyInfo>();
            foreach (System.Reflection.PropertyInfo pi in netType.GetProperties())
            {
                netProperties[pi.Name.ToLowerInvariant()] = pi;
            }

            foreach (RuntimeTypeData candidate in this.SpecificationData)
            {
                int matchingProperties = 0;
                foreach (string propertyName in candidate.Properties.Keys)
                {
                    if (netProperties.ContainsKey(propertyName) && (candidate.Properties[propertyName].Type == null || candidate.Properties[propertyName].Type.Type == null || candidate.Properties[propertyName].Type.Type.Equals(netProperties[propertyName].PropertyType)))
                    {
                        matchingProperties++;
                    }
                }

                if (bestMatch == null || bestMatchingPropertiesCount < matchingProperties)
                {
                    bestMatchingPropertiesCount = matchingProperties;
                    bestMatch = candidate;
                }
            }

            return bestMatch;
        }
    }
}