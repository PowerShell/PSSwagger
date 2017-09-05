// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Json
{
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;
    using System.Linq;

    /// <summary>
    /// Provides parsing for a JSON file.
    /// </summary>
    public class JsonPathFinder
    {
        private JToken root;
        private string rootPath = null;

        public virtual string Path
        {
            get
            {
                if (String.IsNullOrEmpty(this.rootPath))
                {
                    System.Text.StringBuilder sb = new System.Text.StringBuilder();
                    sb.Append("#/");
                    sb.Append(this.root.Path.Replace(".", "/").ToLowerInvariant());
                    this.rootPath = sb.ToString();
                }

                return this.rootPath;
            }
        }
        public virtual JsonPathFinder Parent
        {
            get
            {
                if (this.root.Parent != null)
                {
                    return new JsonPathFinder((JToken)this.root.Parent);
                }

                return null;
            }
        }

        public virtual string Key
        {
            get
            {
                string[] dotSplit = this.root.Path.Split(new char[] { '.' }, StringSplitOptions.RemoveEmptyEntries);
                if (dotSplit.Length > 1)
                {
                    return dotSplit[dotSplit.Length - 1];
                }

                return null;
            }
        }

        public virtual T GetValue<T>()
        {
            return this.root.ToObject<T>();
        }

        public JsonPathFinder()
        {
            this.root = null;
        }

        public JsonPathFinder(string json, JsonSerializerSettings settings = null)
        {
            JsonSerializerSettings serializationSettings;
            if (settings == null)
            {
                serializationSettings = new JsonSerializerSettings();
            }
            else
            {
                serializationSettings = settings;
            }

            this.root = JsonConvert.DeserializeObject<JToken>(json, serializationSettings);
        }

        public JsonPathFinder(JToken jToken)
        {
            this.root = jToken;
        }

        public virtual JsonPathFinder OpenContainer()
        {
            return this.Children().Single();
        }

        public virtual IEnumerable<JsonPathFinder> Find(JsonQueryBuilder queryBuilder)
        {
            return Find(queryBuilder.ToQuery());
        }

        public virtual IEnumerable<JsonPathFinder> Find(string jsonQuery)
        {
            foreach (JToken token in this.root.SelectTokens(jsonQuery))
            {
                yield return new JsonPathFinder(token);
            }
        }

        public virtual IEnumerable<JsonPathFinder> Children()
        {
            foreach (JToken token in this.root.Children())
            {
                yield return new JsonPathFinder(token);
            }
        }

        public override string ToString()
        {
            return this.root == null ? null : this.root.ToString();
        }
    }
}