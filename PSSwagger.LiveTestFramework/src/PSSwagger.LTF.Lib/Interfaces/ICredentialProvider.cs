// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    /// <summary>
    /// Handle credentials.
    /// </summary>
    public interface ICredentialProvider
    {
        /// <summary>
        /// Add the current credential information to the given command or the given command's runspace.
        /// </summary>
        void Process(ICommandBuilder command);

        /// <summary>
        /// Set an inner property with the given name (case-insensitive) to the given value.
        /// </summary>
        /// <param name="property">Case-insensitive property name.</param>
        /// <param name="value">New value of property.</param>
        void Set(string property, object value);
    }
}