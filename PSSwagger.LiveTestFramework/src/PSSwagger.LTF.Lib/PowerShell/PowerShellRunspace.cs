namespace PSSwagger.LTF.Lib.PowerShell
{
    using Interfaces;
    using Logging;
    using Models;
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Dynamic;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;

    /// <summary>
    /// Manage a PowerShell runspace.
    /// </summary>
    public class PowerShellRunspace : IRunspaceManager
    {
        private Logger logger;
        private Runspace runspace;
        public PowerShellRunspace(Logger logger)
        {
            this.runspace = RunspaceFactory.CreateRunspace();
            this.runspace.Open();
            this.logger = logger;
        }

        public ICommandBuilder CreateCommand()
        {
            return new PowerShellCommand(this);
        }

        public GeneratedModule GetModuleInfo(string modulePath)
        {
            if (this.logger != null)
            {
                this.logger.LogAsync(String.Format(CultureInfo.CurrentCulture, "Parsing module: {0}", modulePath));
            }
            string moduleName = String.Empty;
            GeneratedModule module = new GeneratedModule(this);
            module.ModulePath = modulePath;
            if (File.Exists(modulePath) || Directory.Exists(modulePath))
            {
                // First we have to run Test-ModuleManifest to get RequiredModules
                if (!Path.IsPathRooted(modulePath))
                {
                    throw new ModulePathNotRootedException(modulePath);
                }

                ICommandBuilder testModuleManifest = this.CreateCommand();
                testModuleManifest.Command = "Test-ModuleManifest";
                testModuleManifest.AddParameter("Path", modulePath);
                CommandExecutionResult result = testModuleManifest.Invoke();

                dynamic testResult = (result.Results.FirstOrDefault() as PSObject).AsDynamic();
                if (testResult == null)
                {
                    if (this.logger != null)
                    {
                        this.logger.LogError("No module object was returned by Test-ModuleManifest.");
                    }
                    throw new CommandFailedException(testModuleManifest, result, "Can't get module information for an invalid module.");
                }

                moduleName = testResult.Name;
                foreach (PSModuleInfo requiredModule in testResult.RequiredModules)
                {
                    GeneratedModule requiredModuleInfo = new GeneratedModule(this);
                    requiredModuleInfo.ModulePath = requiredModule.Name;
                    module.RequiredModules.Add(requiredModuleInfo);
                }
            } else
            {
                // Otherwise assume the input is a module name instead of a path and attempt a direct load
                moduleName = modulePath;
            }

            if (this.logger != null)
            {
                this.logger.LogAsync(String.Format(CultureInfo.CurrentCulture, "Loading module: {0}", moduleName));
            }
            CommandExecutionResult loadResult = module.Load();
            if (loadResult.HadErrors)
            {
                loadResult.LogErrors(this.logger);
                throw new CommandFailedException(null, loadResult, "Failed to load module.");
            }

            ICommandBuilder getModule = this.CreateCommand();
            getModule.Command = "Get-Module";
            getModule.AddParameter("Name", moduleName);
            CommandExecutionResult getModuleResult = getModule.Invoke();
            if (getModuleResult.HadErrors)
            {
                getModuleResult.LogErrors(this.logger);
                throw new CommandFailedException(getModule, getModuleResult, "Failed to get module after loading.");
            }

            dynamic moduleInfo = (getModuleResult.Results.First() as PSObject).AsDynamic();
            foreach (string entry in moduleInfo.ExportedCommands.Keys)
            {
                FunctionInfo commandInfo = moduleInfo.ExportedCommands[entry] as FunctionInfo;
                if (this.logger != null)
                {
                    this.logger.LogAsync("Parsing command: " + entry);
                }
                if (commandInfo != null)
                {
                    foreach (CommandParameterSetInfo parameterSet in commandInfo.ParameterSets)
                    {
                        OperationData operationData = new OperationData(parameterSet.Name, entry);
                        if (this.logger != null)
                        {
                            this.logger.LogAsync("Found operation: " + parameterSet.Name);
                        }
                        foreach (CommandParameterInfo commandParameterInfo in parameterSet.Parameters)
                        {
                            ParameterData parameterData = new ParameterData();
                            parameterData.Name = commandParameterInfo.Name;
                            operationData.Parameters.Add(parameterData.Name, parameterData);
                        }

                        module.Operations[operationData.OperationId] = operationData;
                    }
                }
            }

            return module;
        }

        public CommandExecutionResult Invoke(object command)
        {
            if (command is Command)
            {
                LogPowerShellCommand(command as Command);
                Pipeline pipeline = this.runspace.CreatePipeline();
                pipeline.Commands.Add((Command)command);
                IEnumerable<object> results = null;
                IEnumerable<object> errors = null;
                bool hadErrors = false;
                try
                {
                    Collection<PSObject> psResults = pipeline.Invoke();
                    results = psResults.AsEnumerable<object>();
                    hadErrors = pipeline.Error.Count > 0;
                    if (hadErrors)
                    {
                        errors = pipeline.Error.ReadToEnd().AsEnumerable<object>();
                    }
                } catch (Exception e)
                {
                    if (this.logger != null)
                    {
                        this.logger.LogError("Invoke ran into an exception: " + e.Message);
                    }
                    errors = new string[] { e.Message };
                    hadErrors = true;
                }

                return new CommandExecutionResult(results, errors, hadErrors);
            }

            return null;
        }

        private void LogPowerShellCommand(Command command)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.AppendFormat("Executing PowerShell command: {0}\n", command.CommandText);
            foreach (CommandParameter parameter in command.Parameters)
            {
                sb.AppendFormat(CultureInfo.InvariantCulture, "     {0} = {1}", parameter.Name, parameter.Value);
            }
            if (this.logger != null)
            {
                this.logger.LogAsync(sb.ToString());
            }
        }
    }
}