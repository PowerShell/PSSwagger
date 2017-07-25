// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Converters;
    using Messages;
    using Models;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for LiveTestRequestConverter type.
    /// </summary>
    public class LiveTestRequestConverterTests
    {
        private readonly ITestOutputHelper output;
        public LiveTestRequestConverterTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        [Fact]
        public void ConvertsMappedParameter()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            test.Parameters["parm"] = new ParameterData()
            {
                Name = "parm",
                JsonName = "jsonParm",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(converter);

            string json = "{\"method\":\"A.testOperationId\",\"jsonrpc\":\"2.0\",\"id\":\"0\",\"params\":{\"jsonparm\":\"testValue\"}}";
            LiveTestRequest request = JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            Assert.NotNull(request);
            Assert.Equal("0", request.Id);
            Assert.Equal("2.0", request.JsonRpc);
            Assert.Equal("A.testOperationId", request.Method);
            Assert.Equal("testoperationid", request.OperationId);
            Assert.True(request.Params.ContainsKey("parm"));
            Assert.Equal(typeof(string), request.Params["parm"].GetType());
            Assert.Equal("testValue", request.Params["parm"] as string);

            string reserialized = JsonConvert.SerializeObject(request, settings);
            Assert.Equal(json, reserialized);
        }

        [Fact]
        public void ConvertsMappedPropertyOfParameter()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            RuntimeTypeData jsonParmData = new RuntimeTypeData()
            {
                Type = typeof(LiveTestRequestConverterTestsObject)
            };
            jsonParmData.Properties["property"] = new ParameterData()
            {
                Name = "property",
                JsonName = "prop",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };
            test.Parameters["jsonparm"] = new ParameterData()
            {
                Name = "jsonParm",
                Type = jsonParmData
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(converter);
            settings.Converters.Add(new DynamicTypedObjectConverter(jsonParmData));

            string json = "{\"method\":\"A.testOperationId\",\"jsonrpc\":\"2.0\",\"id\":\"0\",\"params\":{\"jsonparm\":{\"prop\":\"testValue\"}}}";
            LiveTestRequest request = JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            Assert.NotNull(request);
            Assert.Equal("0", request.Id);
            Assert.Equal("2.0", request.JsonRpc);
            Assert.Equal("A.testOperationId", request.Method);
            Assert.Equal("testoperationid", request.OperationId);
            Assert.True(request.Params.ContainsKey("jsonparm"));
            Assert.Equal(typeof(LiveTestRequestConverterTestsObject), request.Params["jsonparm"].GetType());
            Assert.Equal("testValue", ((LiveTestRequestConverterTestsObject)request.Params["jsonparm"]).Property);

            string reserialized = JsonConvert.SerializeObject(request, settings);
            Assert.Equal(json, reserialized);
        }

        [Fact]
        public void ConvertsPrimitiveParameters()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            test.Parameters["string"] = new ParameterData()
            {
                Name = "string",
                JsonName = "stringparm",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };
            test.Parameters["bool"] = new ParameterData()
            {
                Name = "bool",
                JsonName = "boolparm",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(bool)
                }
            };
            test.Parameters["array"] = new ParameterData()
            {
                Name = "array",
                JsonName = "arrayparm",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(bool[])
                }
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            converter.RegisterSelf(settings);

            string json = "{\"method\":\"A.testOperationId\",\"jsonrpc\":\"2.0\",\"id\":\"0\",\"params\":{\"stringparm\":\"testValue\",\"boolparm\":true,\"arrayparm\":[true,false]}}";
            LiveTestRequest request = JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            Assert.NotNull(request);
            Assert.Equal("0", request.Id);
            Assert.Equal("2.0", request.JsonRpc);
            Assert.Equal("A.testOperationId", request.Method);
            Assert.Equal("testoperationid", request.OperationId);
            Assert.True(request.Params.ContainsKey("string"));
            Assert.Equal(typeof(string), request.Params["string"].GetType());
            Assert.Equal("testValue", (string)request.Params["string"]);
            Assert.True(request.Params.ContainsKey("bool"));
            Assert.Equal(typeof(bool), request.Params["bool"].GetType());
            Assert.True((bool)request.Params["bool"]);
            Assert.True(request.Params.ContainsKey("array"));
            Assert.Equal(typeof(bool[]), request.Params["array"].GetType());
            Assert.Equal(2, ((bool[])request.Params["array"]).Length);
            Assert.True(((bool[])request.Params["array"])[0]);
            Assert.False(((bool[])request.Params["array"])[1]);

            string reserialized = JsonConvert.SerializeObject(request, settings);
            Assert.Equal(json, reserialized);
        }

        [Fact]
        public void ConvertsNullParameters()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            test.Parameters["string"] = new ParameterData()
            {
                Name = "string",
                JsonName = "stringparm",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(converter);

            string json = "{\"method\":\"A.testOperationId\",\"jsonrpc\":\"2.0\",\"id\":\"0\",\"params\":{\"stringparm\":null}}";
            LiveTestRequest request = JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            Assert.NotNull(request);
            Assert.Equal("0", request.Id);
            Assert.Equal("2.0", request.JsonRpc);
            Assert.Equal("A.testOperationId", request.Method);
            Assert.Equal("testoperationid", request.OperationId);
            Assert.True(request.Params.ContainsKey("string"));
            Assert.Null((string)request.Params["string"]);
        }

        [Fact]
        public void ReservedParameterStaysJObject()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            test.Parameters["__reserved"] = new ParameterData()
            {
                Name = "__reserved",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.Converters.Add(converter);

            string json = "{\"method\":\"A.testOperationId\",\"jsonrpc\":\"2.0\",\"id\":\"0\",\"params\":{\"__reserved\":{}}}";
            LiveTestRequest request = JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            Assert.NotNull(request);
            Assert.Equal("0", request.Id);
            Assert.Equal("2.0", request.JsonRpc);
            Assert.Equal("A.testOperationId", request.Method);
            Assert.Equal("testoperationid", request.OperationId);
            Assert.True(request.Params.ContainsKey("__reserved"));
            Assert.Equal(typeof(JObject), request.Params["__reserved"].GetType());
        }

        [Fact]
        public void RegistersAllSubConverters()
        {
            GeneratedModule module = new GeneratedModule(null);
            OperationData test = new OperationData("testoperationid", "Get-Test");
            module.Operations["testoperationid"] = test;
            RuntimeTypeData jsonParmData = new RuntimeTypeData()
            {
                Type = typeof(LiveTestRequestConverterTestsObject)
            };
            jsonParmData.Properties["property"] = new ParameterData()
            {
                Name = "property",
                JsonName = "prop",
                Type = new RuntimeTypeData()
                {
                    Type = typeof(string)
                }
            };
            test.Parameters["jsonparm"] = new ParameterData()
            {
                Name = "jsonParm",
                Type = jsonParmData
            };

            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            JsonSerializerSettings settings = new JsonSerializerSettings();
            converter.RegisterSelf(settings);

            // 1. LiveTestRequestConverter
            // 2. DynamicTypedObjectConverter for LiveTestRequestConverterTestsObject
            Assert.Equal(2, settings.Converters.Count);
        }
    }

    public class LiveTestRequestConverterTestsObject
    {
        public string Property { get; set; }
    }
}