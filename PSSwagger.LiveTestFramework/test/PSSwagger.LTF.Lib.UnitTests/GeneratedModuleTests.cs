// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Converters;
    using Json;
    using Messages;
    using Mocks;
    using Models;
    using System.Collections.Generic;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for GeneratedModule type.
    /// </summary>
    public class GeneratedModuleTests
    {
        private readonly ITestOutputHelper output;
        public GeneratedModuleTests(ITestOutputHelper output)
        {
            this.output = output;
        }

        /// <summary>
        /// Test that a simple module executes the expected load command.
        /// </summary>
        [Fact]
        public void BasicLoadTest()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "test.psd1";
            module.Load();

            Assert.Equal("Import-Module", runspace.CommandBuilders[0].Command);
            Assert.True(runspace.CommandBuilders[0].Parameters.ContainsKey("Name"));
            Assert.Equal("test.psd1", runspace.CommandBuilders[0].Parameters["Name"]);
        }

        /// <summary>
        /// Test the expected command when force load == true.
        /// </summary>
        [Fact]
        public void ForceLoadTest()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "test.psd1";
            module.Load(force: true);

            Assert.Equal("Import-Module", runspace.CommandBuilders[0].Command);
            Assert.True(runspace.CommandBuilders[0].Parameters.ContainsKey("Name"));
            Assert.Equal("test.psd1", runspace.CommandBuilders[0].Parameters["Name"]);
            Assert.True(runspace.CommandBuilders[0].Parameters.ContainsKey("Force"));
            Assert.True((bool)runspace.CommandBuilders[0].Parameters["Force"]);
        }

        /// <summary>
        /// Test the expected command when module path is a module name instead of a full path.
        /// </summary>
        [Fact]
        public void LoadWithName()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.ModulePath = "PackageManagement";
            module.Load();

            Assert.Equal("Import-Module", runspace.CommandBuilders[0].Command);
            Assert.True(runspace.CommandBuilders[0].Parameters.ContainsKey("Name"));
            Assert.Equal("PackageManagement", runspace.CommandBuilders[0].Parameters["Name"]);
        }

        /// <summary>
        /// Test the expected commands when the given module has required modules.
        /// </summary>
        [Fact]
        public void LoadWithRequiredModules()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            GeneratedModule requiredModule = new GeneratedModule(runspace);
            requiredModule.ModulePath = "PowerShellGet";
            module.ModulePath = "PackageManagement";
            module.RequiredModules.Add(requiredModule);
            module.Load();

            Assert.Equal("import-module [name powershellget]", ((string)runspace.InvokeHistory[0]).ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement]", ((string)runspace.InvokeHistory[1]).ToLowerInvariant());
        }

        /// <summary>
        /// Test that all import commands inherit the force attribute.
        /// </summary>
        [Fact]
        public void ForceIsPropogatedToAllModules()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            GeneratedModule requiredModule = new GeneratedModule(runspace);
            GeneratedModule requiredModuleSub = new GeneratedModule(runspace);
            requiredModuleSub.ModulePath = "psreadline";
            requiredModule.ModulePath = "PowerShellGet";
            requiredModule.RequiredModules.Add(requiredModuleSub);
            module.ModulePath = "PackageManagement";
            module.RequiredModules.Add(requiredModule);
            module.Load(force: true);

            Assert.Equal("import-module [name psreadline] [force true]", ((string)runspace.InvokeHistory[0]).ToLowerInvariant());
            Assert.Equal("import-module [name powershellget] [force true]", ((string)runspace.InvokeHistory[1]).ToLowerInvariant());
            Assert.Equal("import-module [name packagemanagement] [force true]", ((string)runspace.InvokeHistory[2]).ToLowerInvariant());
        }

        [Fact]
        public void ProcessOperationSimpleParameters()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.Operations["thing_get"] = new OperationData("Thing_Get", "Get-Thing")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "Integer", new ParameterData() { Name = "Integer", Type = new RuntimeTypeData(typeof(int)) } },
                    { "Boolean", new ParameterData() { Name = "Boolean", Type = new RuntimeTypeData(typeof(bool)) } },
                    { "Decimal", new ParameterData() { Name = "Decimal", Type = new RuntimeTypeData(typeof(double)) } },
                    { "String", new ParameterData() { Name = "String", Type = new RuntimeTypeData(typeof(string)) } }
                }
            };

            MockTestCredentialFactory credentialsFactory = new MockTestCredentialFactory();
            LiveTestRequest request = new LiveTestRequest();
            request.Method = "Things.Thing_Get";
            request.OperationId = "Thing_Get";
            request.Params = new Dictionary<string, object>();
            request.Params["integer"] = 5;
            request.Params["boolean"] = true;
            request.Params["decimal"] = 1.2;
            request.Params["string"] = "testValue";

            CommandExecutionResult result = module.ProcessRequest(request, credentialsFactory);
            Assert.Equal(1, runspace.InvokeHistory.Count);
            Assert.Equal("Get-Thing [Integer 5] [Boolean True] [Decimal 1.2] [String testValue]", ((string)runspace.InvokeHistory[0]));
        }

        [Fact]
        public void ProcessOperationComplexParameters()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.Operations["thing_get"] = new OperationData("Thing_Get", "Get-Thing")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "Parameter", new ParameterData() { Name = "Parameter", Type = new RuntimeTypeData(typeof(GeneratedModuleTestsObject)) } }
                }
            };

            MockTestCredentialFactory credentialsFactory = new MockTestCredentialFactory();
            LiveTestRequest request = new LiveTestRequest();
            request.Method = "Things.Thing_Get";
            request.OperationId = "Thing_Get";
            request.Params = new Dictionary<string, object>();
            request.Params["parameter"] = new GeneratedModuleTestsObject()
            {
                String = "testValue",
                Number = 500,
                Object = new GeneratedModuleTestsSubObject()
                {
                    Decimal = 1.2,
                    Boolean = true
                }
            };

            CommandExecutionResult result = module.ProcessRequest(request, credentialsFactory);
            Assert.Equal(1, runspace.InvokeHistory.Count);
            Assert.Equal("Get-Thing [Parameter {[String testValue] [Number 500] [Object [Decimal 1.2] [Boolean True]]}]", (string)runspace.InvokeHistory[0]);
        }

        [Fact]
        public void ProcessOperationWithCredentials()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.Operations["thing_get"] = new OperationData("Thing_Get", "Get-Thing");

            MockTestCredentialFactory credentialsFactory = new MockTestCredentialFactory();
            credentialsFactory.RegisterProvider("commandbased", new CommandBasedCredentialProvider());
            credentialsFactory.RegisterProvider("parameterbased", new ParameterBasedCredentialProvider());
            LiveTestRequest request = new LiveTestRequest();
            request.Method = "Things.Thing_Get";
            request.OperationId = "Thing_Get";
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
                                                Type = "commandBased",
                                                Properties = new Dictionary<string, object>()
                                                {
                                                    { "tenantId", "testTenantId" },
                                                    { "clientId", "testClientId" },
                                                    { "secret", "testSecret" }
                                                }
                                            }, new LiveTestCredentials()
                                            {
                                                Type = "parameterBased",
                                                Properties = new Dictionary<string, object>()
                                                {
                                                    { "tenantId", "testTenantId" },
                                                    { "clientId", "testClientId" },
                                                    { "secret", "testSecret" }
                                                }
                                            } }
                        }
                    }
                }
            };
            request.Params["parameter"] = new GeneratedModuleTestsObject()
            {
                String = "testValue",
                Number = 500,
                Object = new GeneratedModuleTestsSubObject()
                {
                    Decimal = 1.2,
                    Boolean = true
                }
            };

            CommandExecutionResult result = module.ProcessRequest(request, credentialsFactory);
            Assert.Equal(2, runspace.InvokeHistory.Count);
            Assert.Equal("Login-Account", (string)runspace.InvokeHistory[0]);
            Assert.Equal("Login-Account [CredentialKey testCredentials]", (string)runspace.InvokeHistory[1]);
        }

        [Fact]
        public void ProcessOperationFromJsonFull()
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            GeneratedModule module = new GeneratedModule(runspace);
            module.Operations["thing_get"] = new OperationData("Thing_Get", "Get-Thing")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "parameter", new ParameterData() { Name = "Parameter", Type = new RuntimeTypeData(typeof(GeneratedModuleTestsObject)) } }
                }
            };

            string json = "{\"method\":\"Things.Thing_Get\",\"params\":{\"__reserved\":{\"credentials\":[{\"x-ps-credtype\":\"commandBased\",\"tenantId\":\"testTenantId\",\"clientId\":\"testClientId\",\"secret\":\"testSecret\"},{\"x-ps-credtype\":\"parameterBased\",\"tenantId\":\"testTenantId\",\"clientId\":\"testClientId\",\"secret\":\"testSecret\"}]},\"parameter\":{\"string\":\"testValue\",\"number\":500,\"object\":{\"decimal\":1.2,\"boolean\":true}}}}";
            LiveTestRequestConverter converter = new LiveTestRequestConverter(module);
            Newtonsoft.Json.JsonSerializerSettings settings = new Newtonsoft.Json.JsonSerializerSettings();
            converter.RegisterSelf(settings);

            MockTestCredentialFactory credentialsFactory = new MockTestCredentialFactory();
            credentialsFactory.RegisterProvider("commandbased", new CommandBasedCredentialProvider());
            credentialsFactory.RegisterProvider("parameterbased", new ParameterBasedCredentialProvider());

            LiveTestRequest request = Newtonsoft.Json.JsonConvert.DeserializeObject<LiveTestRequest>(json, settings);
            CommandExecutionResult result = module.ProcessRequest(request, credentialsFactory);
            Assert.Equal("Login-Account [parameter {[String testValue] [Number 500] [Object [Decimal 1.2] [Boolean True]]}]", (string)runspace.InvokeHistory[0]);
            Assert.Equal("Login-Account [parameter {[String testValue] [Number 500] [Object [Decimal 1.2] [Boolean True]]}] [CredentialKey testCredentials]", (string)runspace.InvokeHistory[1]);
        }

        [Fact]
        public void ParameterRenamedUsingAutoRestExt()
        {
            GeneratedModule expectedModule, testModule;
            GetLoadMetadataFromSpecificationTestData(out expectedModule, out testModule);

            MockJsonPathFinder rootFinder = new MockJsonPathFinder()
            {
                KeyMock = "root",
                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                {
                    { "paths", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            KeyMock = "paths",
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "pathItem",
                                    ChildrenMocks = new List<JsonPathFinder>()
                                    {
                                        new MockJsonPathFinder()
                                        {
                                            KeyMock = "getOperation",
                                            QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                            {
                                                { "operationId", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ValueMock = "operationid"
                                                    }
                                                } },
                                                { "parameters", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ChildrenMocks = new List<JsonPathFinder>()
                                                        {
                                                            new MockJsonPathFinder()
                                                            {
                                                                PathMock = "dummy",
                                                                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                                {
                                                                    { "name", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "nameFromSpec"
                                                                        }
                                                                    } },
                                                                    { "x-ms-client-name", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "psParameterName"
                                                                        }
                                                                    } }
                                                                }
                                                            }
                                                        }
                                                    }
                                                } }
                                            }
                                        }.Container()
                                    }
                                }.Container()
                            }
                        }
                    } }
                }
            };

            testModule.LoadMetadataFromSpecification(rootFinder);

            AssertModulesArEqual(expectedModule, testModule);
        }

        [Fact]
        public void ExtendedPathsParameterRenamedUsingAutoRestExt()
        {
            GeneratedModule expectedModule, testModule;
            GetLoadMetadataFromSpecificationTestData(out expectedModule, out testModule);

            MockJsonPathFinder rootFinder = new MockJsonPathFinder()
            {
                KeyMock = "root",
                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                {
                    { "x-ms-paths", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            KeyMock = "x-ms-paths",
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "pathItem",
                                    ChildrenMocks = new List<JsonPathFinder>()
                                    {
                                        new MockJsonPathFinder()
                                        {
                                            KeyMock = "getOperation",
                                            QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                            {
                                                { "operationId", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ValueMock = "operationid"
                                                    }
                                                } },
                                                { "parameters", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ChildrenMocks = new List<JsonPathFinder>()
                                                        {
                                                            new MockJsonPathFinder()
                                                            {
                                                                PathMock = "dummy",
                                                                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                                {
                                                                    { "name", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "nameFromSpec"
                                                                        }
                                                                    } },
                                                                    { "x-ms-client-name", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "psParameterName"
                                                                        }
                                                                    } }
                                                                }
                                                            }
                                                        }
                                                    }
                                                } }
                                            }
                                        }.Container()
                                    }
                                }.Container()
                            }
                        }
                    } }
                }
            };

            testModule.LoadMetadataFromSpecification(rootFinder);

            AssertModulesArEqual(expectedModule, testModule);
        }

        [Fact]
        public void FlattenedParameterRenamedUsingAutoRestExt()
        {
            GeneratedModule expectedModule, testModule;
            GetLoadMetadataFromSpecificationTestData(out expectedModule, out testModule);

            MockJsonPathFinder rootFinder = new MockJsonPathFinder()
            {
                KeyMock = "root",
                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                {
                    { "paths", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            KeyMock = "paths",
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "pathItem",
                                    ChildrenMocks = new List<JsonPathFinder>()
                                    {
                                        new MockJsonPathFinder()
                                        {
                                            KeyMock = "getOperation",
                                            QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                            {
                                                { "operationId", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ValueMock = "operationid"
                                                    }
                                                } },
                                                { "parameters", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ChildrenMocks = new List<JsonPathFinder>()
                                                        {
                                                            new MockJsonPathFinder()
                                                            {
                                                                PathMock = "dummy",
                                                                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                                {
                                                                    { "x-ms-client-flatten", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = true
                                                                        }
                                                                    } },
                                                                    { "..$ref", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "#/definitions/object"
                                                                        }
                                                                    } }
                                                                }
                                                            }
                                                        }
                                                    }
                                                } }
                                            }
                                        }.Container()
                                    }
                                }.Container()
                            }
                        }
                    } },
                    { "definitions", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "object",
                                    PathMock = "#/definitions/object",
                                    QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                    {
                                        { "properties", new List<JsonPathFinder>()
                                        {
                                            new MockJsonPathFinder()
                                            {
                                                ChildrenMocks = new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        KeyMock = "nameFromSpec",
                                                        QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                        {
                                                            { "x-ms-client-name", new List<JsonPathFinder>()
                                                            {
                                                                new MockJsonPathFinder()
                                                                {
                                                                    ValueMock = "psParameterName"
                                                                }
                                                            } }
                                                        }
                                                    }.Container()
                                                }
                                            }
                                        } }
                                    }
                                }.Container()
                            }
                        }
                    } }
                }
            };

            testModule.LoadMetadataFromSpecification(rootFinder);

            AssertModulesArEqual(expectedModule, testModule);
        }

        [Fact]
        public void NestedFlattenedParameterRenamedUsingAutoRest()
        {
            GeneratedModule expectedModule, testModule;
            GetLoadMetadataFromSpecificationTestData(out expectedModule, out testModule);

            MockJsonPathFinder rootFinder = new MockJsonPathFinder()
            {
                KeyMock = "root",
                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                {
                    { "paths", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            KeyMock = "paths",
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "pathItem",
                                    ChildrenMocks = new List<JsonPathFinder>()
                                    {
                                        new MockJsonPathFinder()
                                        {
                                            KeyMock = "getOperation",
                                            QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                            {
                                                { "operationId", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ValueMock = "operationid"
                                                    }
                                                } },
                                                { "parameters", new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        ChildrenMocks = new List<JsonPathFinder>()
                                                        {
                                                            new MockJsonPathFinder()
                                                            {
                                                                PathMock = "dummy",
                                                                QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                                {
                                                                    { "x-ms-client-flatten", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = true
                                                                        }
                                                                    } },
                                                                    { "..$ref", new List<JsonPathFinder>()
                                                                    {
                                                                        new MockJsonPathFinder()
                                                                        {
                                                                            ValueMock = "#/definitions/object"
                                                                        }
                                                                    } }
                                                                }
                                                            }
                                                        }
                                                    }
                                                } }
                                            }
                                        }.Container()
                                    }
                                }.Container()
                            }
                        }
                    } },
                    { "definitions", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            ChildrenMocks = new List<JsonPathFinder>()
                            {
                                new MockJsonPathFinder()
                                {
                                    KeyMock = "object",
                                    PathMock = "#/definitions/object",
                                    QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                    {
                                        { "properties", new List<JsonPathFinder>()
                                        {
                                            new MockJsonPathFinder()
                                            {
                                                ChildrenMocks = new List<JsonPathFinder>()
                                                {
                                                    new MockJsonPathFinder()
                                                    {
                                                        KeyMock = "properties",
                                                        QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                        {
                                                            { "x-ms-client-flatten", new List<JsonPathFinder>()
                                                            {
                                                                new MockJsonPathFinder()
                                                                {
                                                                    ValueMock = true
                                                                }
                                                            } },
                                                            { "$ref", new List<JsonPathFinder>()
                                                            {
                                                                new MockJsonPathFinder()
                                                                {
                                                                    ValueMock = "#/definitions/nestedObject"
                                                                }
                                                            } }
                                                        }
                                                    }.Container()
                                                }
                                            }
                                        } }
                                    }
                                }.Container()
                            }
                        }
                    } },
                    { "$.definitions.nestedObject", new List<JsonPathFinder>()
                    {
                        new MockJsonPathFinder()
                        {
                            KeyMock = "nestedObject",
                            PathMock = "#/definitions/nestedObject",
                            QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                {
                                    { "properties", new List<JsonPathFinder>()
                                    {
                                        new MockJsonPathFinder()
                                        {
                                            ChildrenMocks = new List<JsonPathFinder>()
                                            {
                                                new MockJsonPathFinder()
                                                {
                                                    KeyMock = "nameFromSpec",
                                                    QueryMocks = new Dictionary<string, List<JsonPathFinder>>()
                                                    {
                                                        { "x-ms-client-name", new List<JsonPathFinder>()
                                                        {
                                                            new MockJsonPathFinder()
                                                            {
                                                                ValueMock = "psParameterName"
                                                            }
                                                        } }
                                                    }
                                                }.Container()
                                            }
                                        }
                                    } }
                                }
                        } }
                    }
                }
            };

            testModule.LoadMetadataFromSpecification(rootFinder);

            AssertModulesArEqual(expectedModule, testModule);
        }

        private void AssertModulesArEqual(GeneratedModule expectedModule, GeneratedModule actualModule)
        {
            Assert.Equal(expectedModule.Operations.Count, actualModule.Operations.Count);
            foreach (string key in expectedModule.Operations.Keys)
            {
                Assert.True(actualModule.Operations.ContainsKey(key));
                foreach (string pkey in expectedModule.Operations[key].Parameters.Keys)
                {
                    Assert.True(actualModule.Operations[key].Parameters.ContainsKey(pkey));
                    Assert.Equal(expectedModule.Operations[key].Parameters[pkey].Name, actualModule.Operations[key].Parameters[pkey].Name);
                    Assert.Equal(expectedModule.Operations[key].Parameters[pkey].JsonName, actualModule.Operations[key].Parameters[pkey].JsonName);
                }
            }
        }

        private void GetLoadMetadataFromSpecificationTestData(out GeneratedModule expectedModule, out GeneratedModule testModule)
        {
            MockRunspaceManager runspace = new MockRunspaceManager();
            expectedModule = new GeneratedModule(runspace);
            expectedModule.Operations["operationid"] = new OperationData("operationid", "command")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "psparametername", new ParameterData()
                        {
                             Name = "psparametername",
                             JsonName = "namefromspec"
                        }
                    }
                },
                ResponseType = new ResponseTypeData()
                {
                    ModuleData = new RuntimeTypeData()
                    {
                        Type = typeof(GeneratedModuleTestsSubObject)
                    }
                }
            };
            expectedModule.Operations["operationid"].ResponseType.SpecificationData.Add(new RuntimeTypeData()
            {
                Properties = new Dictionary<string, ParameterData>()
                        {
                            { "pspropertyname", new ParameterData()
                                {
                                     Name = "pspropertyname",
                                     JsonName = "propertynamefromspec"
                                }
                            }
                        }
            });
            expectedModule.Operations["operationid"].ResponseType.Complete();

            testModule = new GeneratedModule(runspace);
            testModule.Operations["operationid"] = new OperationData("operationid", "command")
            {
                Parameters = new Dictionary<string, ParameterData>()
                {
                    { "psparametername", new ParameterData()
                        {
                             Name = "psparametername"
                        }
                    }
                },
                ResponseType = new ResponseTypeData()
                {
                    ModuleData = new RuntimeTypeData()
                    {
                        Type = typeof(GeneratedModuleTestsSubObject)
                    }
                }
            };
        }
    }

    public class GeneratedModuleTestsObject
    {
        public string String { get; set; }
        public long Number { get; set; }
        public GeneratedModuleTestsSubObject Object { get; set; }
        public override string ToString()
        {
            return string.Format("{{[String {0}] [Number {1}] [Object {2}]}}", String, Number, Object);
        }
    }

    public class GeneratedModuleTestsSubObject
    {
        public double Decimal { get; set; }
        public bool Boolean { get; set; }
        public override string ToString()
        {
            return string.Format("[Decimal {0}] [Boolean {1}]", Decimal, Boolean);
        }
    }
}