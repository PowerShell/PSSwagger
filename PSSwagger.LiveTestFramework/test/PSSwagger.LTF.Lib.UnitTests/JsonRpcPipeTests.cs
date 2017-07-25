// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using IO;
    using System.Threading.Tasks;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for JsonRpcPipe type.
    /// </summary>
    public class JsonRpcPipeTests
    {
        private readonly ITestOutputHelper output;
        public JsonRpcPipeTests(ITestOutputHelper output)
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
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            SimpleObject data = new SimpleObject();
            data.BooleanProp = true;
            data.StringProp = "test";
            data.NumberProp = 456;
            stringPipe.BufferJsonRpcBlock(data);
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            SimpleObject result = await reader.ReadBlock<SimpleObject>();
            Assert.Equal(data.StringProp, result.StringProp);
            Assert.Equal(data.BooleanProp, result.BooleanProp);
            Assert.Equal(data.NumberProp, result.NumberProp);
        }

        /// <summary>
        /// Test reading an object with a child object.
        /// </summary>
        [Fact]
        public async Task ReadParentChildRelationship()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            ParentChildObject data = new ParentChildObject();
            data.ParentProp = "parent";
            data.Child = new SimpleObject()
            {
                StringProp = "test",
                BooleanProp = true,
                NumberProp = 456
            };
            stringPipe.BufferJsonRpcBlock(data);
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            ParentChildObject result = await reader.ReadBlock<ParentChildObject>();
            Assert.Equal(data.ParentProp, result.ParentProp);
            Assert.NotNull(data.Child);
            Assert.Equal(data.Child.StringProp, result.Child.StringProp);
            Assert.Equal(data.Child.BooleanProp, result.Child.BooleanProp);
            Assert.Equal(data.Child.NumberProp, result.Child.NumberProp);
        }

        /// <summary>
        /// Test reading an object that subclasses another object.
        /// </summary>
        [Fact]
        public async Task ReadSubclassRelationship()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            SubObject data = new SubObject()
            {
                StringProp = "test",
                BooleanProp = true,
                NumberProp = 456,
                Id = 12345
            };
            stringPipe.BufferJsonRpcBlock(data);
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            SubObject result = await reader.ReadBlock<SubObject>();
            Assert.Equal(data.StringProp, result.StringProp);
            Assert.Equal(data.BooleanProp, result.BooleanProp);
            Assert.Equal(data.NumberProp, result.NumberProp);
            Assert.Equal(data.Id, result.Id);
        }

        /// <summary>
        /// Test reading multiple objects with garbage in the middle.
        /// </summary>
        [Fact]
        public async Task ReadMultipleObjects()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            SimpleObject data1 = new SimpleObject()
            {
                BooleanProp = true,
                StringProp = "test",
                NumberProp = 456,
            };
            SimpleObject data2 = new SimpleObject()
            {
                BooleanProp = false,
                StringProp = "test2",
                NumberProp = 123,
            };
            stringPipe.BufferJsonRpcBlock(new object[] { data1, data2 });
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            SimpleObject result = await reader.ReadBlock<SimpleObject>();
            Assert.Equal(data1.StringProp, result.StringProp);
            Assert.Equal(data1.BooleanProp, result.BooleanProp);
            Assert.Equal(data1.NumberProp, result.NumberProp);

            result = await reader.ReadBlock<SimpleObject>();
            Assert.Equal(data2.StringProp, result.StringProp);
            Assert.Equal(data2.BooleanProp, result.BooleanProp);
            Assert.Equal(data2.NumberProp, result.NumberProp);
        }

        /// <summary>
        /// Test reading multiple objects with garbage in the middle.
        /// </summary>
        [Fact]
        public async Task ReadMessageWithOptionalHeaders()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            SimpleObject data = new SimpleObject()
            {
                BooleanProp = true,
                StringProp = "test",
                NumberProp = 456,
            };
            stringPipe.BufferJsonRpcBlock(data, type: "test");
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            SimpleObject result = await reader.ReadBlock<SimpleObject>();
            Assert.Equal(data.StringProp, result.StringProp);
            Assert.Equal(data.BooleanProp, result.BooleanProp);
            Assert.Equal(data.NumberProp, result.NumberProp);
        }

        [Fact]
        public async Task WriteMessageWithHeaders()
        {
            Mocks.StringPipe stringPipe = new Mocks.StringPipe();
            Mocks.StringPipe outputPipe = new Mocks.StringPipe();
            SimpleObject data = new SimpleObject()
            {
                BooleanProp = true,
                StringProp = "test",
                NumberProp = 456,
            };
            JsonRpcPipe reader = new JsonRpcPipe(stringPipe, outputPipe);
            await reader.WriteBlock<SimpleObject>(data);
            string output = outputPipe.OutputBuffer.ToString();
            Assert.Equal("Content-Length: 57\r\nContent-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n{\"StringProp\":\"test\",\"BooleanProp\":true,\"NumberProp\":456}\r\n", output);
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