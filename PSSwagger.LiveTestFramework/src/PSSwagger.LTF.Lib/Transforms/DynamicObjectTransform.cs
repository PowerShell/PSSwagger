// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Transforms
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;

    /// <summary>
    /// Defines transform steps for a single type.
    /// </summary>
    public class DynamicObjectTransform
    {
        /// <summary>
        /// Gets or sets the type to apply transform to.
        /// </summary>
        public string Type { get; set; }

        /// <summary>
        /// Gets or sets the ordered list of transforms to apply to this type.
        /// </summary>
        public DynamicObjectTransformDefinition[] Transforms { get; set; }

        /// <summary>
        /// Checks if <paramref name="obj"/> exactly matches the Type property.
        /// </summary>
        /// <param name="obj">Object to check. Can be null.</param>
        /// <returns>False if null or <paramref name="obj"/>.GetType().FullName does not match this.Type; True otherwise.</returns>
        public bool CanTransform(object obj)
        {
            if (obj == null)
            {
                return false;
            }

            return obj.GetType().FullName.Equals(this.Type, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Transform the given object into one or more objects. For multi-step transforms, all steps should define an expected output type. Otherwise, the client should re-query all transformers.
        /// </summary>
        /// <param name="obj">Object to transform. Can be null.</param>
        /// <returns>Null if <paramref name="obj"/> is null. Otherwise, returns the result of valid transforms.</returns>
        public IEnumerable<object> Transform(object obj)
        {
            if (this.Transforms != null)
            {
                List<object> toTransform = new List<object>();
                List<object> transformResult = new List<object>();
                List<object> swap = null;
                toTransform.Add(obj);
                foreach (DynamicObjectTransformDefinition definition in this.Transforms)
                {
                    transformResult.Clear();
                    foreach (object transformObject in toTransform)
                    {
                        IEnumerable<object> newObjects = definition.Transform(transformObject);
                        if (!String.IsNullOrEmpty(definition.Result))
                        {
                            newObjects = newObjects.Where(o => o.GetType().FullName.Equals(definition.Result, StringComparison.OrdinalIgnoreCase));
                        }

                        transformResult.AddRange(newObjects);
                    }
                    
                    // Nothing to transform to the next phase, just return the previous phase
                    if (transformResult.Count == 0)
                    {
                        return toTransform;
                    }

                    swap = toTransform;
                    toTransform = transformResult;
                    transformResult = swap;
                }

                // The result of the last phase will be in toTransform
                return toTransform;
            }

            return null;
        }
    }
}