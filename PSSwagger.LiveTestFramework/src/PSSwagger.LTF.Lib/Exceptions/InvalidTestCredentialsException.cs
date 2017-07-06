namespace PSSwagger.LTF.Lib
{
    using Interfaces;
    using Models;
    using System;
    using System.Globalization;

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