namespace PSSwagger.LTF.Lib.PowerShell
{
    using Interfaces;
    using System;
    using System.Collections;

    /// <summary>
    /// Build a PowerShell command.
    /// </summary>
    public class PowerShellCommand : ICommandBuilder
    {
        public string Command
        {
            get
            {
                throw new NotImplementedException();
            }

            set
            {
                throw new NotImplementedException();
            }
        }

        public ICommandBuilder AddParameter(string parameterName, object parameterValue, bool switchParameter)
        {
            throw new NotImplementedException();
        }

        public IEnumerable Invoke()
        {
            throw new NotImplementedException();
        }
    }
}