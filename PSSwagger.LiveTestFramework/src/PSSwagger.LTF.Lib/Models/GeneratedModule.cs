namespace PSSwagger.LTF.Lib.Models
{
    using Credentials;
    using Interfaces;
    using Messages;
    using System;
    using System.Collections;
    using System.Collections.Generic;

    /// <summary>
    /// Contains metadata for a generated module being tested.
    /// </summary>
    public class GeneratedModule
    {
        private IRunspaceManager runspace;

        public string ModulePath { get; set; }

        public IList<GeneratedModule> RequiredModules { get; private set; }

        public IDictionary<string, OperationData> Operations { get; private set; }

        public GeneratedModule(IRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.RequiredModules = new List<GeneratedModule>();
            this.Operations = new Dictionary<string, OperationData>();
        }

        public virtual CommandExecutionResult ProcessRequest(LiveTestRequest request, LiveTestCredentialFactory credentialsFactory)
        {
            return null;
        }

        public virtual CommandExecutionResult Load(bool force = false)
        {
            foreach (GeneratedModule requiredModule in this.RequiredModules)
            {
                requiredModule.Load(force: force);
            }

            ICommandBuilder command = this.runspace.CreateCommand();
            command.Command = "Import-Module";
            if (!String.IsNullOrEmpty(ModulePath))
            {
                command.AddParameter("Name", this.ModulePath);
            }

            if (force)
            {
                command.AddParameter("Force", true);
            }

            return command.Invoke();
        }
    }
}