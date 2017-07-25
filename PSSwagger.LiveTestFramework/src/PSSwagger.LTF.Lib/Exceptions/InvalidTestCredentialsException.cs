// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib
{
    using System;

    /// <summary>
    /// Exception thrown when a command fails to execute.
    /// </summary>
    public class InvalidTestCredentialsException : Exception
    {
        public InvalidTestCredentialsException() : base("Test received an invalid credentials object.")
        {
        }
    }
}