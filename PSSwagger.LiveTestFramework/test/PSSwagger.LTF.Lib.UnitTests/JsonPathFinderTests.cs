// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Json;
    using System.Linq;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for JsonPathFinder type.
    /// </summary>
    public class JsonPathFinderTests
    {
        private readonly ITestOutputHelper output;
        public JsonPathFinderTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        [Fact]
        public void ParentNodeOfChildNotNull()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("test").SingleOrDefault();
            Assert.NotNull(childFinder.Parent);
        }

        [Fact]
        public void ParentOfRootIsNull()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            Assert.Null(finder.Parent);
        }

        [Fact]
        public void FindExistingNodes()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("test").SingleOrDefault();
            Assert.NotNull(childFinder);
        }

        [Fact]
        public void FindNodesCasing()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("TEST").SingleOrDefault();
            Assert.Null(childFinder);
        }

        [Fact]
        public void FindNoNodes()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("notATest").SingleOrDefault();
            Assert.Null(childFinder);
        }

        [Fact]
        public void RootDocumentKey()
        {
            string json = "{\"test\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            Assert.Null(finder.Key);
        }

        [Fact]
        public void FindKeyOfObject()
        {
            string json = "{\"test\":{\"sub\":{}}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("..sub").SingleOrDefault();
            Assert.NotNull(childFinder);
            Assert.Equal("sub", childFinder.Key);
        }

        [Fact]
        public void FindKeyOfArray()
        {
            string json = "{\"test\":{\"sub\":[]}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("..sub").SingleOrDefault();
            Assert.NotNull(childFinder);
            Assert.Equal("sub", childFinder.Key);
        }

        [Fact]
        public void FindKeyOfValue()
        {
            string json = "{\"test\":{\"sub\":5}";
            JsonPathFinder finder = new JsonPathFinder(json);
            JsonPathFinder childFinder = finder.Find("..sub").SingleOrDefault();
            Assert.NotNull(childFinder);
            Assert.Equal("sub", childFinder.Key);
        }
    }
}