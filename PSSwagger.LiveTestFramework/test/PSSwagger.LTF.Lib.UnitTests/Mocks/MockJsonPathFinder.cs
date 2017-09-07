// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Json;
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Provides parsing for a JSON file.
    /// </summary>
    public class MockJsonPathFinder : JsonPathFinder
    {
        public JsonPathFinder ParentMock { get; set; }
        public string KeyMock { get; set; }
        public object ValueMock { get; set; }
        public string PathMock { get; set; }
        public Dictionary<string, List<JsonPathFinder>> QueryMocks { get; set; }
        public IList<JsonPathFinder> ChildrenMocks { get; set; }
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
            this.ChildrenMocks = new List<JsonPathFinder>();
        }

        public MockJsonPathFinder MakeDummyParent(int depth = 1)
        {
            MockJsonPathFinder currentLowestParent = new MockJsonPathFinder() { ParentMock = this };
            this.ChildrenMocks.Add(currentLowestParent);
            while (--depth > 0)
            {
                MockJsonPathFinder nextLowestParent = new MockJsonPathFinder() { ParentMock = currentLowestParent };
                currentLowestParent.ChildrenMocks.Add(nextLowestParent);
                currentLowestParent = nextLowestParent;
            }

            return currentLowestParent;
        }

        public MockJsonPathFinder Container(int depth = 1)
        {
            MockJsonPathFinder currentHighestParent = new MockJsonPathFinder();
            currentHighestParent.ChildrenMocks.Add(this);
            this.ParentMock = currentHighestParent;
            while (--depth > 0)
            {
                MockJsonPathFinder nextHighestParent = new MockJsonPathFinder();
                nextHighestParent.ChildrenMocks.Add(this);
                currentHighestParent.ParentMock = nextHighestParent;
                currentHighestParent = nextHighestParent;
            }

            return currentHighestParent;
        }

        public override IEnumerable<JsonPathFinder> Find(string jsonQuery)
        {
            if (this.QueryMocks.ContainsKey(jsonQuery))
            {
                return this.QueryMocks[jsonQuery];
            }

            return new List<JsonPathFinder>();
        }

        public override IEnumerable<JsonPathFinder> Children()
        {
            foreach (JsonPathFinder child in this.ChildrenMocks)
            {
                yield return child;
            }
        }

        public override string Path
        {
            get
            {
                return this.PathMock;
            }
        }
    }
}