namespace PSSwagger.LTF.Lib.Interfaces
{
    /// <summary>
    /// Encodes a given parameter into a runspace language.
    /// </summary>
    public interface IParameterEncoder
    {
        /// <summary>
        /// Encode the given object into something understandable by a certain runspace (e.g. PowerShell).
        /// </summary>
        /// <param name="parameterValue">Original parameter value.</param>
        /// <returns>Encoded parameter value.</returns>
        object Encode(object parameterValue);
    }
}