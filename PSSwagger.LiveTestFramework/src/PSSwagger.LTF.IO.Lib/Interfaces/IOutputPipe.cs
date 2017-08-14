// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using System.Threading.Tasks;

    /// <summary>
    /// Generic output pipe.
    /// </summary>
    public interface IOutputPipe
    {
        /// <summary>
        /// Write a single character.
        /// </summary>
        /// <param name="b">Character to write.</param>
        Task Write(char b);

        /// <summary>
        /// Write the given string then a new line.
        /// </summary>
        /// <param name="line">Line to write, not including new line.</param>
        Task WriteLine(string line);

        /// <summary>
        /// Serialize and write the given block.
        /// </summary>
        /// <typeparam name="T">Block type to write.</typeparam>
        /// <param name="msg">Block to write.</param>
        /// <returns>Async task.</returns>
        Task WriteBlock<T>(T msg) where T : class;
    }
}