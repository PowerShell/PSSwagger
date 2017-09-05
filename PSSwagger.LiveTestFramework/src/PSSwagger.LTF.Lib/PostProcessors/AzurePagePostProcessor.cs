// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.PostProcessors
{
    using PSSwagger.LTF.Lib.Interfaces;
    using System;
    using Models;
    using System.Collections.Generic;

    /// <summary>
    /// Transform the command result into a page of results.
    /// </summary>
    public class AzurePagePostProcessor : ICommandPostProcessor
    {
        private AzurePageType page;
        public AzurePagePostProcessor(AzurePageType page)
        {
            this.page = page;
        }

        public CommandExecutionResult Process(CommandExecutionResult result)
        {
            if (result.HadErrors)
            {
                return result;
            }

            // Because PowerShell flattens all items, nextLinkName is always null
            page.NextLink = null;
            foreach (object resultItem in result.Results)
            {
                page.Items.Add(resultItem);
            }

            CommandExecutionResult newResult = new CommandExecutionResult(new List<object>() { page.GetPage() }, result.Errors, result.HadErrors);
            return newResult;
        }
    }
}