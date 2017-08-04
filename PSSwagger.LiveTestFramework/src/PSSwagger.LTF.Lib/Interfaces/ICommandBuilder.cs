namespace PSSwagger.LTF.Lib.Interfaces
{
    using System.Collections;

    /// <summary>
    /// Build commands to execute test operations.
    /// </summary>
    public interface ICommandBuilder
    {
        /// <summary>
        /// Gets or sets the current command.
        /// </summary>
        string Command { get; set; }

        /// <summary>
        /// Adds the given parameter.
        /// </summary>
        /// <param name="parameterName">Case insensitive name of parameter.</param>
        /// <param name="parameterValue">Parameter value.</param>
        /// <param name="switchParameter">True if parameter should be used as a switch (<paramref name="parameterValue" must be a boolean/ >). False otherwise.</param>
        /// <returns>This command builder.</returns>
        ICommandBuilder AddParameter(string parameterName, object parameterValue, bool switchParameter);
        
        /// <summary>
        /// Execute the command in the parent runspace.
        /// </summary>
        /// <returns>Results of command.</returns>
        IEnumerable Invoke();
    }
}