namespace PSSwagger.LTF.Lib.PowerShell
{
    using Interfaces;
    using System;
    using System.Collections;

    /// <summary>
    /// Manage a PowerShell runspace.
    /// </summary>
    public class PowerShellRunspace : IRunspaceManager
    {
        public ICommandBuilder CreateCommand()
        {
            throw new NotImplementedException();
        }

        public GeneratedModule GetModuleInfo(string modulePath)
        {
            throw new NotImplementedException();
        }

        public IEnumerable Invoke(string script)
        {
            throw new NotImplementedException();
        }

        public void SetSessionVariable(string variableName, object variableValue)
        {
            throw new NotImplementedException();
        }
    }
}