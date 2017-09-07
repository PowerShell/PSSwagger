// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Converters
{
    using Messages;
    using Models;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Reflection;

    /// <summary>
    /// Converts JSON objects into a LiveTestRequest.
    /// </summary>
    public class LiveTestRequestConverter : JsonConverter
    {
        private GeneratedModule module;

        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="module">Module containing all operations and data this converter should handle.</param>
        public LiveTestRequestConverter(GeneratedModule module)
        {
            this.module = module;
        }

        /// <summary>
        /// Register this converter and all type converters underneath.
        /// </summary>
        /// <param name="settings">Serializer settings to register all converters to.</param>
        public void RegisterSelf(JsonSerializerSettings settings)
        {
            settings.Converters.Add(this);
            foreach (OperationData operation in module.Operations.Values)
            {
                foreach (ParameterData parameter in operation.Parameters.Values)
                {
                    RegisterTypeConverter(parameter.Type, settings);
                }
                
                // Don't bother registering the ResponseType for a page response
                if (operation.ResponseType != null)
                {
                    RegisterTypeConverter(operation.ResponseType.TypeData, settings);
                }
            }
        }

        private void RegisterTypeConverter(RuntimeTypeData typeData, JsonSerializerSettings settings)
        {
            if (typeData != null && typeData.Type != null && typeData.Type.GetConstructor(new Type[] { }) != null && typeData.Properties.Count > 0)
            {
                Log("Registering JSON converter for type: {0}", typeData.Type.FullName);
                settings.Converters.Add(new DynamicTypedObjectConverter(typeData));
                foreach (ParameterData property in typeData.Properties.Values)
                {
                    RegisterTypeConverter(property.Type, settings);
                }
            }
        }

        public override bool CanConvert(Type objectType)
        {
            return objectType.Equals(typeof(LiveTestRequest));
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            JsonSerializer cleanSerializer = new JsonSerializer();
            LiveTestRequest request = cleanSerializer.Deserialize(reader, objectType) as LiveTestRequest;
            // Current test protocol states that the method is given as A.B_C, so ignore anything without a '.'.
            int dotIndex = request.Method.IndexOf('.');
            if (dotIndex != -1)
            {
                request.OperationId = request.Method.Substring(dotIndex+1).ToLowerInvariant();
                if (module.Operations.ContainsKey(request.OperationId))
                {
                    OperationData op = module.Operations[request.OperationId];
                    if (request.Params != null)
                    {
                        Dictionary<string, object> newParams = new Dictionary<string, object>();
                        foreach (string key in request.Params.Keys)
                        {
                            // Reserved parameter will be converted later.
                            if (key.Equals("__reserved", StringComparison.OrdinalIgnoreCase))
                            {
                                newParams[key] = request.Params[key];
                            }
                            else
                            {
                                ParameterData match = op.Parameters.Where((kvp) => !String.IsNullOrEmpty(kvp.Value.JsonName) &&
                                    kvp.Value.JsonName.Equals(key, StringComparison.OrdinalIgnoreCase)).Select((kvp) => kvp.Value).FirstOrDefault();
                                if (match == null && op.Parameters.ContainsKey(key.ToLowerInvariant()))
                                {
                                    match = op.Parameters[key.ToLowerInvariant()];
                                }
                                if (match != null)
                                {
                                    // This means that the parameter has been renamed from the spec name.
                                    object converted;
                                    if (ConvertObject(request.Params[key], match.Type.Type, serializer, out converted))
                                    {
                                        newParams[match.Name.ToLowerInvariant()] = converted;
                                    }
                                }
                            }
                        }

                        request.Params = newParams;
                    }
                }
            }
            
            return request;
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            if (value == null)
            {
                writer.WriteRawValue("null");
                return;
            }
            
            LiveTestRequest request = (LiveTestRequest)value;
            Dictionary<string, object> dict = new Dictionary<string, object>();
            foreach (PropertyInfo pi in value.GetType().GetProperties())
            {
                if (!pi.Name.Equals("params", StringComparison.OrdinalIgnoreCase) && pi.GetCustomAttribute(typeof(JsonIgnoreAttribute)) == null)
                {
                    object val = pi.GetValue(value);
                    if ((val != null) || serializer.NullValueHandling == NullValueHandling.Include)
                    {
                        dict[pi.Name.ToLowerInvariant()] = val;
                    }
                }
            }

            dict["params"] = request.Params;
            if (module.Operations.ContainsKey(request.OperationId))
            {
                OperationData op = module.Operations[request.OperationId];
                Dictionary<string, object> newParams = new Dictionary<string, object>();
                foreach (string key in request.Params.Keys)
                {
                    if (key.Equals("__reserved", StringComparison.OrdinalIgnoreCase))
                    {
                        newParams[key] = request.Params;
                    } else if (op.Parameters.ContainsKey(key))
                    {
                        // Decide if the JSON name or the PowerShell name should be used
                        if (!String.IsNullOrEmpty(op.Parameters[key].JsonName))
                        {
                            newParams[op.Parameters[key].JsonName.ToLowerInvariant()] = request.Params[key];
                        } else
                        {
                            newParams[op.Parameters[key].Name.ToLowerInvariant()] = request.Params[key];
                        }
                    }
                }

                dict["params"] = newParams;
            }

            serializer.Serialize(writer, dict);
        }

        private bool ConvertObject(object val, Type expectedType, JsonSerializer serializer, out object converted)
        {
            converted = null;
            bool success = true;
            if (val == null || val.GetType().Equals(expectedType))
            {
                converted = val;
            }
            else if (val is JToken)
            {
                converted = serializer.Deserialize(new JTokenReader(val as JToken), expectedType);
            }
            else
            {
                success = false;
            }

            return success;
        }

        private void Log(string msg, params object[] args)
        {
            if (this.module.Logger != null && !String.IsNullOrEmpty(msg))
            {
                this.module.Logger.Log(msg, args);
            }
        }
    }
}