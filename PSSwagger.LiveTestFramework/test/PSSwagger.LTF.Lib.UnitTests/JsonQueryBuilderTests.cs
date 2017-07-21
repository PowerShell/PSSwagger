namespace PSSwagger.LTF.Lib.UnitTests
{
    using Converters;
    using Json;
    using Messages;
    using Mocks;
    using Models;
    using System.Collections.Generic;
    using System.Linq;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for JsonQueryBuilder type.
    /// </summary>
    public class JsonQueryBuilderTests
    {
        private readonly ITestOutputHelper output;
        public JsonQueryBuilderTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        [Fact]
        public void RecursiveDescent()
        {
            JsonQueryBuilder builder = new JsonQueryBuilder();
            string actualQuery = builder.RecursiveDescent().ToQuery();
            Assert.Equal("..", actualQuery);
        }

        [Fact]
        public void Property()
        {
            JsonQueryBuilder builder = new JsonQueryBuilder();
            string actualQuery = builder.Property("prop").ToQuery();
            Assert.Equal("prop", actualQuery);
        }

        [Fact]
        public void PropertyAfterRecursiveDescent()
        {
            JsonQueryBuilder builder = new JsonQueryBuilder();
            builder.RecursiveDescent();
            string actualQuery = builder.Property("prop").ToQuery();
            Assert.Equal("..prop", actualQuery);
        }

        [Fact]
        public void PropertyAfterProperty()
        {
            JsonQueryBuilder builder = new JsonQueryBuilder();
            builder.Property("test");
            string actualQuery = builder.Property("prop").ToQuery();
            Assert.Equal("test.prop", actualQuery);
        }

        [Fact]
        public void CreateFromJsonPath()
        {
            JsonQueryBuilder builder = new JsonQueryBuilder("#/definitions/object");
            string actualQuery = builder.ToQuery();
            Assert.Equal("$.definitions.object", actualQuery);
        }
    }
}