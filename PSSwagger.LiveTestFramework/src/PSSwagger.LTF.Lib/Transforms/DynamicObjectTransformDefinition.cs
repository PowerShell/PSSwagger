// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
using System.Collections.Generic;
using System.Reflection;

namespace PSSwagger.LTF.Lib.Transforms
{
    /// <summary>
    /// Defines a single transform step.
    /// </summary>
    public class DynamicObjectTransformDefinition
    {
        /// <summary>
        /// Gets or sets the transform type. Supported: 'select'
        /// </summary>
        public string Query { get; set; }

        /// <summary>
        /// Gets or sets the property to select. Valid for query types: 'select'
        /// </summary>
        public string Property { get; set; }

        /// <summary>
        /// Gets or sets the result type. Optional. If defined, subsequent transforms will only take place if the output type matches this type. This optimizes multi-step transforms.
        /// </summary>
        public string Result { get; set; }

        public IEnumerable<object> Transform(object obj)
        {
            if (!string.IsNullOrEmpty(this.Query))
            {
                switch (this.Query.ToLowerInvariant())
                {
                    case "select":
                        yield return Select(obj);
                        break;
                }
            }
        }

        private object Select(object obj)
        {
            PropertyInfo pi = obj.GetType().GetProperty(this.Property);
            if (pi != null)
            {
                return pi.GetValue(obj);
            }

            return null;
        }
    }
}