// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using System.Threading.Tasks;

    /// <summary>
    /// Generic input pipe.
    /// </summary>
    public interface IInputPipe
    {
        /// <summary>
        /// Read a single byte.
        /// </summary>
        /// <returns>Byte read.</returns>
        Task<byte> ReadByte();

        /// <summary>
        /// Read a single character.
        /// </summary>
        /// <returns>Character read.</returns>
        Task<char> ReadChar();

        /// <summary>
        /// Read until the next new line character.
        /// </summary>
        /// <returns>All text input up to but not including the new line character.</returns>
        Task<string> ReadLine();

        /// <summary>
        /// Read a single block of type <typeparamref name="T"/>.
        /// </summary>
        /// <typeparam name="T">Type of block to read and deserialize.</typeparam>
        /// <returns>Block of type <typeparamref name="T"/>.</returns>
        Task<T> ReadBlock<T>() where T : class;
    }
}