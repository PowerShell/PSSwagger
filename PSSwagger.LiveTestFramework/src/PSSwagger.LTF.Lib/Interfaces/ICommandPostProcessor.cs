// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Interfaces
{
    using Models;

    /// <summary>
    /// Process command results before returning to client.
    /// </summary>
    public interface ICommandPostProcessor
    {
        CommandExecutionResult Process(CommandExecutionResult result);
    }
}