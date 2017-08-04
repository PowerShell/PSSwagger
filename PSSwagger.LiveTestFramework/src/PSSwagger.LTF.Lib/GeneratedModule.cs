namespace PSSwagger.LTF.Lib
{
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

        public IList<GeneratedModule> RequiredModules { get; set; }

        public GeneratedModule(IRunspaceManager runspace)
        {
            this.runspace = runspace;
            this.RequiredModules = new List<GeneratedModule>();
        }

        public virtual IEnumerable ProcessRequest(LiveTestRequest request)
        {
            return null;
        }

        public virtual void Load(bool force = false)
        {
            foreach (GeneratedModule requiredModule in this.RequiredModules)
            {
                requiredModule.Load(force: force);
            }

            ICommandBuilder command = this.runspace.CreateCommand();
            command.Command = "Import-Module";
            if (!String.IsNullOrEmpty(ModulePath))
            {
                command.AddParameter("Name", this.ModulePath, switchParameter: false);
            }

            if (force)
            {
                command.AddParameter("Force", true, switchParameter: true);
            }

            command.Invoke();
        }
    }
}