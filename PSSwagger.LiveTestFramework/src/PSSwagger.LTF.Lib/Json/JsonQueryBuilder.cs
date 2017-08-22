// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Json
{
    using System.Text;

    /// <summary>
    /// Provides JSON Path query building operations.
    /// </summary>
    public class JsonQueryBuilder
    {
        private StringBuilder queryBuilder = new StringBuilder();
        private bool appendDot = false;

        public JsonQueryBuilder() { }

        public JsonQueryBuilder(string jsonPath)
        {
            queryBuilder.Append(jsonPath.Replace("#", "$").Replace("/", "."));
        }

        public JsonQueryBuilder RecursiveDescent()
        {
            appendDot = false;
            this.queryBuilder.Append("..");
            return this;
        }

        public JsonQueryBuilder Property(string name)
        {
            if (appendDot)
            {
                this.queryBuilder.Append(".");
            }
            this.queryBuilder.Append(name);
            appendDot = true;
            return this;
        }

        public JsonQueryBuilder Any()
        {
            if (appendDot)
            {
                this.queryBuilder.Append(".");
            }
            this.queryBuilder.Append("*");
            appendDot = true;
            return this;
        }

        public JsonQueryBuilder ArrayIndex(JsonQueryBuilder filter)
        {
            this.queryBuilder.Append("[");
            this.queryBuilder.Append(filter.ToQuery());
            this.queryBuilder.Append("]");
            return this;
        }

        public JsonQueryBuilder HasProperty(string property)
        {
            this.queryBuilder.Append("@.");
            this.queryBuilder.Append(property);
            return this;
        }

        public JsonQueryBuilder Filter(JsonQueryBuilder exp)
        {
            this.queryBuilder.Append("?(");
            this.queryBuilder.Append(exp.ToQuery());
            this.queryBuilder.Append(")");
            return this;
        }

        public string ToQuery()
        {
            return this.queryBuilder.ToString();
        }
    }
}