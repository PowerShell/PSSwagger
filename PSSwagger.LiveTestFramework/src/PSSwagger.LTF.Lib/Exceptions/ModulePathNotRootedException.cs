// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib
{
    using System;
    using System.Globalization;

    /// <summary>
    /// Exception thrown when a command fails to execute.
    /// </summary>
    public class ModulePathNotRootedException : Exception
    {
        public string Path { get; private set; }

        public ModulePathNotRootedException(string path)
        {
            this.Path = path;
        }

        public override string Message
        {
            get
            {
                return String.Format(CultureInfo.CurrentCulture, "Module path must be an absolute path. Path: {0}", this.Path);
            }
        }
    }
}