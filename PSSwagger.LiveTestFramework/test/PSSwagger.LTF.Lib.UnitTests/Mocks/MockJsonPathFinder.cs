// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Json;
    using System.Collections.Generic;

    /// <summary>
    /// Provides parsing for a JSON file.
    /// </summary>
    public class MockJsonPathFinder : JsonPathFinder
    {
        public JsonPathFinder ParentMock { get; set; }
        public string KeyMock { get; set; }
        public object ValueMock { get; set; }
        public Dictionary<string, List<JsonPathFinder>> QueryMocks { get; }
        public override JsonPathFinder Parent
        {
            get
            {
                return this.ParentMock;
            }
        }

        public override string Key
        {
            get
            {
                return this.KeyMock;
            }
        }

        public override T GetValue<T>()
        {
            return (T)this.ValueMock;
        }

        public MockJsonPathFinder()
        {
            this.QueryMocks = new Dictionary<string, List<JsonPathFinder>>();
        }

        public MockJsonPathFinder MakeDummyParent(int depth = 1)
        {
            MockJsonPathFinder currentLowestParent = new MockJsonPathFinder() { ParentMock = this };
            while (--depth > 0)
            {
                currentLowestParent = new MockJsonPathFinder() { ParentMock = currentLowestParent };
            }

            return currentLowestParent;
        }

        public override IEnumerable<JsonPathFinder> Find(string jsonQuery)
        {
            if (this.QueryMocks.ContainsKey(jsonQuery))
            {
                return this.QueryMocks[jsonQuery];
            }

            return null;
        }
    }
}