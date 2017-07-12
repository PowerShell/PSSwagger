namespace PSSwagger.LTF.Lib.Converters
{
    using System;
    using Newtonsoft.Json;
    using Models;

    /// <summary>
    /// Converts JSON objects into a LiveTestRequest.
    /// </summary>
    public class LiveTestRequestConverter : JsonConverter
    {
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="module">Module containing all operations and data this converter should handle.</param>
        public LiveTestRequestConverter(GeneratedModule module)
        {

        }

        /// <summary>
        /// Register this converter and all type converters underneath.
        /// </summary>
        /// <param name="settings">Serializer settings to register all converters to.</param>
        public void RegisterSelf(JsonSerializerSettings settings)
        {

        }

        public override bool CanConvert(Type objectType)
        {
            throw new NotImplementedException();
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            throw new NotImplementedException();
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            throw new NotImplementedException();
        }
    }
}