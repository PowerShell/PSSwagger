// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.UnitTests
{
    using Credentials;
    using Interfaces;
    using Logging;
    using Messages;
    using Mocks;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Xunit;
    using Xunit.Abstractions;

    /// <summary>
    /// Tests for LiveTestCredentialFactory type.
    /// </summary>
    public class LiveTestCredentialFactoryTests
    {
        private const string credTypeProperty = "x-ps-credtype";
        private readonly XUnitOutputPipe output;
        private readonly XUnitOutputPipe error;
        private readonly Logger logger;
        public LiveTestCredentialFactoryTests(ITestOutputHelper output)
        {
            this.output = new XUnitOutputPipe(output);
            this.error = new XUnitOutputPipe(output, logAsErrors: true);
            this.logger = new Logger(this.output, this.error);
        }

        /// <summary>
        /// Test that no x-ps-credtype property defaults to Azure auth.
        /// </summary>
        [Fact]
        public void NoCredTypeProperty()
        {
            LiveTestRequest request = new LiveTestRequest();
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
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

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            IEnumerable<ICredentialProvider> result = test.Create(request, this.logger);
            Assert.Equal(1, result.Count());
            ICredentialProvider first = result.First();
            Assert.NotNull(first);
            Assert.IsType<AzureCredentialProvider>(first);
            AzureCredentialProvider provider = (AzureCredentialProvider)first;
            Assert.Equal("testTenantId", provider.TenantId);
            Assert.Equal("testClientId", provider.ClientId);
            Assert.Equal("testSecret", provider.Secret);
        }

        /// <summary>
        /// Test that x-ps-credtype can be set to Azure.
        /// </summary>
        [Fact]
        public void AzureCredType()
        {
            LiveTestRequest request = new LiveTestRequest();
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
                                                Type = "azure",
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

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            IEnumerable<ICredentialProvider> result = test.Create(request, this.logger);
            Assert.Equal(1, result.Count());
            ICredentialProvider first = result.First();
            Assert.NotNull(first);
            Assert.IsType<AzureCredentialProvider>(first);
            AzureCredentialProvider provider = (AzureCredentialProvider)first;
            Assert.Equal("testTenantId", provider.TenantId);
            Assert.Equal("testClientId", provider.ClientId);
            Assert.Equal("testSecret", provider.Secret);
        }

        /// <summary>
        /// Test that Create ignores x-ps-credtype casing.
        /// </summary>
        [Fact]
        public void IgnoresCase()
        {
            LiveTestRequest request = new LiveTestRequest();
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
                                                Type = "AzUrE",
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

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            IEnumerable<ICredentialProvider> result = test.Create(request, this.logger);
            Assert.Equal(1, result.Count());
            ICredentialProvider first = result.First();
            Assert.NotNull(first);
            Assert.IsType<AzureCredentialProvider>(first);
            AzureCredentialProvider provider = (AzureCredentialProvider)first;
            Assert.Equal("testTenantId", provider.TenantId);
            Assert.Equal("testClientId", provider.ClientId);
            Assert.Equal("testSecret", provider.Secret);
        }

        /// <summary>
        /// Test behavior when the x-ps-credtype provider is unknown.
        /// </summary>
        [Fact]
        public void UnknownProvider()
        {
            LiveTestRequest request = new LiveTestRequest();
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
                                                Type = Path.GetRandomFileName(),
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

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            IEnumerable<ICredentialProvider> result = test.Create(request, this.logger);
            Assert.Equal(0, result.Count());
        }

        /// <summary>
        /// Test behavior when a mix of known and unknown providers is given.
        /// </summary>
        [Fact]
        public void MultipleProviders()
        {
            LiveTestRequest request = new LiveTestRequest();
            request.Params = new Dictionary<string, object>()
            {
                { "__reserved", new Dictionary<string, object>()
                    {
                        { "credentials", new LiveTestCredentials[] { new LiveTestCredentials()
                                            {
                                                Type = Path.GetRandomFileName(),
                                                Properties = new Dictionary<string, object>()
                                                {
                                                    { "tenantId", "testTenantId" },
                                                    { "clientId", "testClientId" },
                                                    { "secret", "testSecret" }
                                                }
                                            },
                                            new LiveTestCredentials()
                                            {
                                                Type = "azure",
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

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            IEnumerable<ICredentialProvider> result = test.Create(request, this.logger);
            Assert.Equal(1, result.Count());
            ICredentialProvider first = result.First();
            Assert.NotNull(first);
            Assert.IsType<AzureCredentialProvider>(first);
            AzureCredentialProvider provider = (AzureCredentialProvider)first;
            Assert.Equal("testTenantId", provider.TenantId);
            Assert.Equal("testClientId", provider.ClientId);
            Assert.Equal("testSecret", provider.Secret);
        }

        [Fact]
        public void TranslateWithoutExtension()
        {
            string requestJson = "{ \"params\": { \"__reserved\": { \"credentials\": { \"tenantId\": \"testTenantId\", \"clientId\": \"testClientId\", \"secret\": \"testSecret\" } } } }";
            LiveTestRequest request = Newtonsoft.Json.JsonConvert.DeserializeObject<LiveTestRequest>(requestJson);

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            test.TranslateCredentialsObjects(request);

            request.Params.ContainsKey("__reserved");
            Assert.True(request.Params["__reserved"] is Dictionary<string, object>);
            Dictionary<string, object> reservedParams = (Dictionary<string, object>)request.Params["__reserved"];

            Assert.True(reservedParams.ContainsKey("credentials"));
            Assert.True(((Dictionary<string, object>)request.Params["__reserved"])["credentials"] is LiveTestCredentials[]);
            LiveTestCredentials[] credsArray = (LiveTestCredentials[])reservedParams["credentials"];
            
            Assert.Equal(1, credsArray.Length);
            LiveTestCredentials result = credsArray[0];
            Assert.Equal("azure", result.Type);
            Assert.Equal("testTenantId", result.Properties["tenantId"].ToString());
            Assert.Equal("testClientId", result.Properties["clientId"].ToString());
            Assert.Equal("testSecret", result.Properties["secret"].ToString());
        }

        [Fact]
        public void TranslateWithExtension()
        {
            string requestJson = "{ \"params\": { \"__reserved\": { \"credentials\": { \"tenantId\": \"testTenantId\", \"clientId\": \"testClientId\", \"secret\": \"testSecret\", \"x-ps-credtype\": \"random\" } } } }";
            LiveTestRequest request = Newtonsoft.Json.JsonConvert.DeserializeObject<LiveTestRequest>(requestJson);

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            test.TranslateCredentialsObjects(request);

            request.Params.ContainsKey("__reserved");
            Assert.True(request.Params["__reserved"] is Dictionary<string, object>);
            Dictionary<string, object> reservedParams = (Dictionary<string, object>)request.Params["__reserved"];

            Assert.True(reservedParams.ContainsKey("credentials"));
            Assert.True(((Dictionary<string, object>)request.Params["__reserved"])["credentials"] is LiveTestCredentials[]);
            LiveTestCredentials[] credsArray = (LiveTestCredentials[])reservedParams["credentials"];

            Assert.Equal(1, credsArray.Length);
            LiveTestCredentials result = credsArray[0];
            Assert.Equal("random", result.Type);
            Assert.Equal("testTenantId", result.Properties["tenantId"].ToString());
            Assert.Equal("testClientId", result.Properties["clientId"].ToString());
            Assert.Equal("testSecret", result.Properties["secret"].ToString());
        }

        [Fact]
        public void TranslateMultipleCredentials()
        {
            string requestJson = "{ \"params\": { \"__reserved\": { \"credentials\": [{ \"tenantId\": \"testTenantId\", \"clientId\": \"testClientId\", \"secret\": \"testSecret\", \"x-ps-credtype\": \"random\" },{ \"tenantId\": \"testTenantId\", \"clientId\": \"testClientId\", \"secret\": \"testSecret\" }] } } }";
            LiveTestRequest request = Newtonsoft.Json.JsonConvert.DeserializeObject<LiveTestRequest>(requestJson);

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            test.TranslateCredentialsObjects(request);

            request.Params.ContainsKey("__reserved");
            Assert.True(request.Params["__reserved"] is Dictionary<string, object>);
            Dictionary<string, object> reservedParams = (Dictionary<string, object>)request.Params["__reserved"];

            Assert.True(reservedParams.ContainsKey("credentials"));
            Assert.True(((Dictionary<string, object>)request.Params["__reserved"])["credentials"] is LiveTestCredentials[]);
            LiveTestCredentials[] credsArray = (LiveTestCredentials[])reservedParams["credentials"];

            Assert.Equal(2, credsArray.Length);
            LiveTestCredentials result = credsArray[0];
            Assert.Equal("random", result.Type);
            Assert.Equal("testTenantId", result.Properties["tenantId"].ToString());
            Assert.Equal("testClientId", result.Properties["clientId"].ToString());
            Assert.Equal("testSecret", result.Properties["secret"].ToString());

            result = credsArray[1];
            Assert.Equal("azure", result.Type);
            Assert.Equal("testTenantId", result.Properties["tenantId"].ToString());
            Assert.Equal("testClientId", result.Properties["clientId"].ToString());
            Assert.Equal("testSecret", result.Properties["secret"].ToString());
        }

        [Fact]
        public void TranslateHttpResponseProperty()
        {
            string requestJson = "{ \"params\": { \"__reserved\": { \"httpResponse\": true } } }";
            LiveTestRequest request = Newtonsoft.Json.JsonConvert.DeserializeObject<LiveTestRequest>(requestJson);

            LiveTestCredentialFactory test = new LiveTestCredentialFactory();
            test.TranslateCredentialsObjects(request);

            request.Params.ContainsKey("__reserved");
            Assert.True(request.Params["__reserved"] is Dictionary<string, object>);
            Dictionary<string, object> reservedParams = (Dictionary<string, object>)request.Params["__reserved"];

            Assert.False(reservedParams.ContainsKey("httpResponse"));
            Assert.True(request.HttpResponse);
        }
    }
}