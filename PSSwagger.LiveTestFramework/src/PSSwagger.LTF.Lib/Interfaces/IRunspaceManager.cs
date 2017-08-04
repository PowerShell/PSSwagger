namespace PSSwagger.LTF.Lib.Interfaces
{
    using System.Collections;

    /// <summary>
    /// Manages the execution space for running test commands.
    /// </summary>
    public interface IRunspaceManager
    {
        /// <summary>
        /// Execute a given script string in this runspace.
        /// </summary>
        /// <param name="script">Script string to execute.</param>
        /// <returns>Result of script execution.</returns>
        IEnumerable Invoke(string script);

        /// <summary>
        /// Create an ICommandBuilder for this runspace.
        /// </summary>
        /// <returns>ICommandBuilder for this runspace.</returns>
        ICommandBuilder CreateCommand();

        /// <summary>
        /// Parse module information in the context of this runspace.
        /// </summary>
        /// <param name="modulePath">Path to module or module name.</param>
        /// <returns>Parsed module information struct.</returns>
        GeneratedModule GetModuleInfo(string modulePath);

        /// <summary>
        /// Set a variable for this runspace session.
        /// </summary>
        /// <param name="variableName">Name of variable.</param>
        /// <param name="variableValue">Value of variable.</param>
        void SetSessionVariable(string variableName, object variableValue);
    }
}