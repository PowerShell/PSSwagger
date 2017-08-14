// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Credentials
{
    using Interfaces;
    using Logging;
    using Messages;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Handle creation of credential providers.
    /// </summary>
    public class LiveTestCredentialFactory
    {
        protected IDictionary<string, Func<Logger, ICredentialProvider>> providers = new Dictionary<string, Func<Logger, ICredentialProvider>>()
        {
            { "azure", (logger) => new AzureCredentialProvider(logger) }
        };

        /// <summary>
        /// Create all credential providers specified by the given request, assuming the __reserved parameter has alreayd been converted by TranslateCredentialsObjects.
        /// </summary>
        /// <param name="request"></param>
        /// <param name="logger"></param>
        /// <returns></returns>
        public virtual IEnumerable<ICredentialProvider> Create(LiveTestRequest request, Logger logger)
        {
            if (request.Params != null && request.Params.ContainsKey("__reserved"))
            {
                Dictionary<string, object> reservedParams = (Dictionary<string, object>)request.Params["__reserved"];
                LiveTestCredentials[] arr = (LiveTestCredentials[])reservedParams["credentials"];
                foreach (LiveTestCredentials credentials in arr)
                {
                    ICredentialProvider provider = null;
                    string credType = String.IsNullOrEmpty(credentials.Type) ? "azure" : credentials.Type.ToLowerInvariant();
                    if (this.providers.ContainsKey(credType))
                    {
                        provider = this.providers[credType](logger);
                    }

                    if (provider != null)
                    {
                        foreach (string property in credentials.Properties.Keys)
                        {
                            provider.Set(property, credentials.Properties[property]);
                        }

                        yield return provider;
                    }
                }
            }
        }

        /// <summary>
        /// On first read, <paramref name="request"/> may contain a __reserved property with a generic JSON object. That object should have a credentials property.
        /// This method exists to convert the generic object of the credentials property into a strongly typed array of LiveTestCredentials objects.
        /// 
        /// After processing, the __reserved property will be transformed into a Dictionary&lt;string, object&gt; object. The credentials key will point to an array of LiveTestCredentials objects.
        /// </summary>
        /// <param name="request">Request object to transform.</param>
        public virtual void TranslateCredentialsObjects(LiveTestRequest request)
        {
            // Check if request requires conversion
            if (request.Params != null && request.Params.ContainsKey("__reserved") && request.Params["__reserved"] is JObject)
            {
                JObject reservedParams = (JObject)request.Params["__reserved"];
                Dictionary<string, object> reservedParamsDict = new Dictionary<string, object>();
                foreach (JProperty property in reservedParams.Properties())
                {
                    if (property.Name.Equals("credentials", StringComparison.OrdinalIgnoreCase))
                    {
                        List<LiveTestCredentials> credsList = new List<LiveTestCredentials>();
                        if (property.Value is JObject)
                        {
                            // Single credentials object
                            credsList.Add(GetCredentials((JObject)property.Value));
                        }
                        else if (property.Value is JArray)
                        {
                            // Array of credentials objects
                            foreach (JToken obj in (JArray)property.Value)
                            {
                                credsList.Add(GetCredentials((JObject)obj));
                            }
                        }

                        reservedParamsDict[property.Name] = credsList.ToArray();
                    } else if (property.Name.Equals("httpResponse", StringComparison.OrdinalIgnoreCase))
                    {
                        request.HttpResponse = property.Value.Value<bool>();
                    }
                    else
                    {
                        reservedParamsDict[property.Name] = property.Value;
                    }
                }

                request.Params["__reserved"] = reservedParamsDict;
            }
        }

        private LiveTestCredentials GetCredentials(JObject credsObject)
        {
            LiveTestCredentials creds = new LiveTestCredentials();
            foreach (JProperty credsProperty in credsObject.Properties())
            {
                if (credsProperty.Name.Equals("x-ps-credtype", StringComparison.OrdinalIgnoreCase))
                {
                    creds.Type = credsProperty.Value.ToString();
                }
                else
                {
                    creds.Properties[credsProperty.Name] = credsProperty.Value;
                }
            }

            if (String.IsNullOrEmpty(creds.Type))
            {
                creds.Type = "azure";
            }

            return creds;
        }
    }
}