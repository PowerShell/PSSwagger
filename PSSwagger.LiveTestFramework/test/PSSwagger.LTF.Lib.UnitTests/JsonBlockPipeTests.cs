namespace PSSwagger.LTF.Lib.UnitTests
{
    using IO;
    using System.Threading.Tasks;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for JsonBlockPipe type.
    /// </summary>
    public class JsonBlockPipeTests
    {
        private readonly ITestOutputHelper output;
        public JsonBlockPipeTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        /// <summary>
        /// Test reading a simple object.
        /// </summary>
        [Fact]
        public async Task ReadSimpleObject()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            stringPipe.BufferInputString("{ \"stringprop\": \"test\", \"booleanprop\": true, \"numberprop\": 456 }");
            JsonBlockPipe reader = new JsonBlockPipe(stringPipe);
            SimpleObject result = await reader.ReadBlockAsync<SimpleObject>();
            Assert.Equal("test", result.StringProp);
            Assert.True(result.BooleanProp);
            Assert.Equal((long)456, result.NumberProp);
        }

        /// <summary>
        /// Test that characters are ignored before and after a valid block.
        /// </summary>
        [Fact]
        public async Task IgnoreCharsBeforeAndAfter()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            stringPipe.BufferInputString("abc{ \"stringprop\": \"test\", \"booleanprop\": true, \"numberprop\": 456 }123");
            JsonBlockPipe reader = new JsonBlockPipe(stringPipe);
            SimpleObject result = await reader.ReadBlockAsync<SimpleObject>();
            Assert.Equal("test", result.StringProp);
            Assert.True(result.BooleanProp);
            Assert.Equal((long)456, result.NumberProp);
        }

        /// <summary>
        /// Test reading an object with a child object.
        /// </summary>
        [Fact]
        public async Task ReadParentChildRelationship()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            stringPipe.BufferInputString("{ \"parentprop\": \"parent\", \"child\": { \"stringprop\": \"test\", \"booleanprop\": true, \"numberprop\": 456 } }");
            JsonBlockPipe reader = new JsonBlockPipe(stringPipe);
            ParentChildObject result = await reader.ReadBlockAsync<ParentChildObject>();
            Assert.Equal("parent", result.ParentProp);
            Assert.Equal("test", result.Child.StringProp);
            Assert.True(result.Child.BooleanProp);
            Assert.Equal((long)456, result.Child.NumberProp);
        }

        /// <summary>
        /// Test reading an object that subclasses another object.
        /// </summary>
        [Fact]
        public async Task ReadSubclassRelationship()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            stringPipe.BufferInputString("{ \"stringprop\": \"test\", \"booleanprop\": true, \"numberprop\": 456, \"id\": 12345 }");
            JsonBlockPipe reader = new JsonBlockPipe(stringPipe);
            SubObject result = await reader.ReadBlockAsync<SubObject>();
            Assert.Equal("test", result.StringProp);
            Assert.True(result.BooleanProp);
            Assert.Equal((long)456, result.NumberProp);
            Assert.Equal((long)12345, result.Id);
        }

        /// <summary>
        /// Test reading multiple objects with garbage in the middle.
        /// </summary>
        [Fact]
        public async Task ReadMultipleObjects()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            stringPipe.BufferInputString("{ \"stringprop\": \"test\", \"booleanprop\": true, \"numberprop\": 456, \"id\": 12345 }garb");
            stringPipe.BufferInputString("age{ \"stringprop\": \"test2\", \"booleanprop\": true, \"numberprop\": 456, \"id\": 12345 }");
            JsonBlockPipe reader = new JsonBlockPipe(stringPipe);
            SubObject result = await reader.ReadBlockAsync<SubObject>();
            Assert.Equal("test", result.StringProp);
            Assert.True(result.BooleanProp);
            Assert.Equal((long)456, result.NumberProp);
            Assert.Equal((long)12345, result.Id);

            result = await reader.ReadBlockAsync<SubObject>();
            Assert.Equal("test2", result.StringProp);
            Assert.True(result.BooleanProp);
            Assert.Equal((long)456, result.NumberProp);
            Assert.Equal((long)12345, result.Id);
        }
    }

    /// <summary>
    /// Test object with simple properties.
    /// </summary>
    internal class SimpleObject
    {
        public string StringProp { get; set; }
        public bool BooleanProp { get; set; }
        public long NumberProp { get; set; }
    }

    /// <summary>
    /// Test object containing parent-child relationship.
    /// </summary>
    internal class ParentChildObject
    {
        public string ParentProp { get; set; }
        public SimpleObject Child { get; set; }
    }

    /// <summary>
    /// Inheritance test.
    /// </summary>
    internal class SubObject : SimpleObject
    {
        public long Id { get; set; }
    }
}