// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.IO
{
    using Interfaces;
    using Newtonsoft.Json;
    using System;
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>
    /// Read/write valid JSON-RPC messages.
    /// </summary>
    public class JsonRpcPipe : IInputPipe, IOutputPipe
    {
        /// <summary>
        /// Constant to indicate that headers are done.
        /// </summary>
        private const string HeaderEndConstant = "end";
        private const string InputStreamClosedConstant = "closed";
        private IInputPipe characterReader;
        private IOutputPipe characterWriter;
        private ConcurrentQueue<object> blockQueue;

        /// <summary>
        /// Serialize settings used during serialization and deserialization. Use this to add converters/customizations.
        /// </summary>
        public JsonSerializerSettings JsonSerializerSettings { get; private set; }

        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="characterReader">InputPipe to use for reading single characters.</param>
        public JsonRpcPipe(IInputPipe characterReader, IOutputPipe characterWriter)
        {
            this.characterReader = characterReader;
            this.characterWriter = characterWriter;
            this.blockQueue = new ConcurrentQueue<object>();
            this.JsonSerializerSettings = new JsonSerializerSettings()
            {
                NullValueHandling = NullValueHandling.Ignore
            };
        }

        /// <summary>
        /// Read a single valid JSON-RPC block.
        /// </summary>
        /// <typeparam name="T">Type of block to read and deserialize.</typeparam>
        /// <returns>Block of type <typeparamref name="T"/>. Returns null if input stream has been closed.</returns>
        public async Task<T> ReadBlock<T>() where T : class
        {
            object returnObj = null;
            bool readFromPipe = true;
            while (blockQueue.Count > 0)
            {
                if (blockQueue.TryDequeue(out returnObj))
                {
                    readFromPipe = false;
                    break;
                }
            }

            if (readFromPipe)
            {
                Tuple<string, string> header = await ReadHeader();
                Dictionary<string, string> headers = new Dictionary<string, string>();
                do
                {
                    headers[header.Item1.ToLowerInvariant()] = header.Item2;
                } while ((header = await ReadHeader()) != null && !header.Item1.Equals(HeaderEndConstant) && !header.Item1.Equals(InputStreamClosedConstant));

                if (header.Item1.Equals(InputStreamClosedConstant))
                {
                    // Input stream closed - return null to indicate this
                    return null;
                }

                byte[] bytes = new byte[Int32.Parse(headers["content-length"])];
                for (int i = 0; i < bytes.Length; i++)
                {
                    bytes[i] = await this.characterReader.ReadByte();
                }

                string jsonString = Encoding.UTF8.GetString(bytes);

                if (jsonString.StartsWith("["))
                {
                    T[] arr = Newtonsoft.Json.JsonConvert.DeserializeObject<T[]>(jsonString, this.JsonSerializerSettings);
                    foreach (T obj in arr)
                    {
                        if (returnObj == null)
                        {
                            returnObj = obj;
                        }
                        else
                        {
                            this.blockQueue.Enqueue(obj);
                        }
                    }
                }
                else
                {
                    returnObj = Newtonsoft.Json.JsonConvert.DeserializeObject<T>(jsonString, this.JsonSerializerSettings);
                }
            }

            return (T)returnObj;
        }

        public Task Write(char b)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Serialize into a JSON-RPC string ending with newline. Content type is application/vscode-jsonrpc. Charset is UTF-8.
        /// </summary>
        /// <typeparam name="T">Type of message to serialize.</typeparam>
        /// <param name="msg">Message to serialize. Must not be null.</param>
        public async Task WriteBlock<T>(T msg) where T : class
        {
            string messageSerialized = Newtonsoft.Json.JsonConvert.SerializeObject(msg, this.JsonSerializerSettings);
            StringBuilder sb = new StringBuilder();
            // LSP states that content is encoded in UTF-8
            sb.Append("Content-Length: " + Encoding.UTF8.GetByteCount(messageSerialized) + "\r\n");
            sb.Append("Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n");
            sb.Append(messageSerialized);
            this.characterWriter.WriteLine(sb.ToString());
        }

        public Task WriteLine(string line)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Not implemented for JsonBlockPipe.
        /// </summary>
        public Task<char> ReadChar()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Not implemented for JsonBlockPipe.
        /// </summary>
        public Task<string> ReadLine()
        {
            throw new NotImplementedException();
        }

        public Task<byte> ReadByte()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Read a single JSON-RPC header. Returns HeaderEndConstant when \r\n follows a \r\n.
        /// </summary>
        /// <returns>Header name and header value.</returns>
        private async Task<Tuple<string, string>> ReadHeader()
        {
            // Cyclic buffer of last two characters - used to read \r\n
            char[] lastCharBuf = new char[2];
            lastCharBuf[0] = '\0';
            lastCharBuf[1] = '\0';
            // Current index of cyclic buffer
            int index = 0;
            bool endRead = false;
            // We expect the following format for headers: "headerName: headerValue"
            // These two variables help track if we've read the special colon and space between headerName and headervalue
            bool colonRead = false;
            bool spaceRead = false;
            string header = String.Empty;
            string val = String.Empty;
            while (!endRead)
            {
                char c = await this.characterReader.ReadChar();
                switch (c)
                {
                    case ':':
                        colonRead = true;
                        break;
                    case ' ':
                        if (colonRead)
                        {
                            spaceRead = true;
                        } else
                        {
                            val += c;
                        }
                        break;
                    case '\n':
                        break;
                    case '\r':
                        break;
                    case '\uffff':
                        // When this character is read, assume the input stream has been closed
                        return new Tuple<string, string>(InputStreamClosedConstant, String.Empty);
                    default:
                        if (spaceRead)
                        {
                            val += c;
                        } else
                        {
                            header += c;
                        }
                        break;
                }
                lastCharBuf[index] = c;
                endRead = lastCharBuf[index] == '\n' && lastCharBuf[1 - index] == '\r';
                index = 1 - index;
            }

            if (String.IsNullOrEmpty(header))
            {
                header = HeaderEndConstant;
            }

            return new Tuple<string, string>(header, val);
        }
    }
}