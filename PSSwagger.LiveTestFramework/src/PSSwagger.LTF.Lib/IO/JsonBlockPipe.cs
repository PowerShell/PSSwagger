namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using System;
    using System.Threading.Tasks;

    /// <summary>
    /// Read valid JSON blocks.
    /// </summary>
    public class JsonBlockPipe : IInputPipe
    {
        private IInputPipe characterReader;
        
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="characterReader">InputPipe to use for reading single characters.</param>
        public JsonBlockPipe(IInputPipe characterReader)
        {
            this.characterReader = characterReader;
        }

        /// <summary>
        /// Not implemented for JsonBlockPipe.
        /// </summary>
        public char ReadChar()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Read a single valid JSON block. Ignores any characters until the first { is read. Ends when the matching } character is read.
        /// </summary>
        /// <typeparam name="T">Type of block to read and deserialize.</typeparam>
        /// <returns>Block of type <typeparamref name="T"/>.</returns>
        public async Task<T> ReadBlockAsync<T>() where T : class
        {
            string jsonString = String.Empty;
            int openBraces = 0;
            while (openBraces > 0 || String.IsNullOrEmpty(jsonString))
            {
                char c = this.characterReader.ReadChar();
                switch (c)
                {
                    case '{':
                        openBraces++;
                        jsonString += c;
                        break;
                    case '}':
                        if (openBraces > 0)
                        {
                            openBraces--;
                            jsonString += c;
                        }
                        break;
                    default:
                        if (openBraces > 0)
                        {
                            jsonString += c;
                        }
                        break;
                }
            }

            return Newtonsoft.Json.JsonConvert.DeserializeObject<T>(jsonString);
        }

        /// <summary>
        /// Not implemented for JsonBlockPipe.
        /// </summary>
        public string ReadLine()
        {
            throw new NotImplementedException();
        }
    }
}