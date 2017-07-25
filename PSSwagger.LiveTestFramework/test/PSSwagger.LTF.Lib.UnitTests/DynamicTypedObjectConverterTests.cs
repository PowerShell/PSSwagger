// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Converters;
    using Models;
    using Newtonsoft.Json;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for DynamicTypedObjectConverter type.
    /// </summary>
    public class DynamicTypedObjectConverterTests
    {
        private readonly ITestOutputHelper output;
        public DynamicTypedObjectConverterTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        [Fact]
        public void ConvertObjectWithRenames()
        {
            string json = "{\"prop\":\"test\",\"booleanproperty\":true}";
            RuntimeTypeData typeData = new RuntimeTypeData();
            typeData.Type = typeof(DynamicTypedObjectConverterTestsObject);
            typeData.Properties.Add("property", new ParameterData()
            {
                 JsonName = "prop",
                 Name = "property",
                 Type = new RuntimeTypeData()
                 {
                     Type = typeof(string)
                 }
            });
            DynamicTypedObjectConverter converter = new DynamicTypedObjectConverter(typeData);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(converter);

            DynamicTypedObjectConverterTestsObject result = JsonConvert.DeserializeObject<DynamicTypedObjectConverterTestsObject>(json, settings);
            Assert.NotNull(result);
            Assert.Equal("test", result.Property);
            Assert.True(result.BooleanProperty);

            string reserialized = JsonConvert.SerializeObject(result, settings);
            Assert.Equal(json, reserialized);
        }

        [Fact]
        public void ConvertNestedObject()
        {
            string json = "{ \"obj\": { \"prop\": \"test\", \"booleanproperty\": true }, \"unconvertedobject\": { \"prop\": \"5\" } }";
            string expectedJson = "{\"obj\":{\"prop\":\"test\",\"booleanproperty\":true},\"unconvertedobject\":{\"Property\":null}}";
            RuntimeTypeData childTypeData = new RuntimeTypeData();
            childTypeData.Type = typeof(DynamicTypedObjectConverterTestsObject);
            childTypeData.Properties.Add("property", new ParameterData()
            {
                JsonName = "prop",
                Name = "property",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            });
            RuntimeTypeData parentTypeData = new RuntimeTypeData();
            parentTypeData.Type = typeof(DynamicTypedObjectConverterTestsNestedObject);
            parentTypeData.Properties.Add("object", new ParameterData()
            {
                JsonName = "obj",
                Name = "object",
                Type = childTypeData
            });
            DynamicTypedObjectConverter childConverter = new DynamicTypedObjectConverter(childTypeData);
            DynamicTypedObjectConverter parentConverter = new DynamicTypedObjectConverter(parentTypeData);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(childConverter);
            settings.Converters.Add(parentConverter);

            DynamicTypedObjectConverterTestsNestedObject result = JsonConvert.DeserializeObject<DynamicTypedObjectConverterTestsNestedObject>(json, settings);
            Assert.NotNull(result);
            Assert.NotNull(result.Object);
            Assert.Equal("test", result.Object.Property);
            Assert.True(result.Object.BooleanProperty);
            Assert.NotNull(result.UnconvertedObject);
            Assert.Null(result.UnconvertedObject.Property);

            string reserialized = JsonConvert.SerializeObject(result, settings);
            Assert.Equal(expectedJson, reserialized);
        }
    }

    public class DynamicTypedObjectConverterTestsObject
    {
        public string Property { get; set; }
        public bool BooleanProperty { get; set; }
    }

    public class DynamicTypedObjectConverterTestsNestedObject
    {
        public DynamicTypedObjectConverterTestsObject Object { get; set; }
        public DynamicTypedObjectConverterTestsUnconvertedObject UnconvertedObject { get; set; }
    }

    public class DynamicTypedObjectConverterTestsUnconvertedObject
    {
        public string Property { get; set; }
    }
}