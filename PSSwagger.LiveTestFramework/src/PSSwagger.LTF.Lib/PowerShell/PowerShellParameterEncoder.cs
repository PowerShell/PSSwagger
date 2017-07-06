namespace PSSwagger.LTF.Lib.PowerShell
{
    using PSSwagger.LTF.Lib.Interfaces;
    using System;
    using System.Globalization;
    using System.Text;

    /// <summary>
    /// Encodes values into PowerShell objects.
    /// </summary>
    public class PowerShellParameterEncoder : IParameterEncoder
    {
        /// <summary>
        /// Encode the given object into something understandable by PowerShell.
        /// </summary>
        /// <param name="parameterValue">Original parameter value.</param>
        /// <returns>Encoded parameter value.</returns>
        public object Encode(object parameterValue)
        {
            return this.EncodeInternal(parameterValue as dynamic);
        }

        private object EncodeInternal(string parameterValue)
        {
            if (String.IsNullOrWhiteSpace(parameterValue))
            {
                return parameterValue;
            }

            // Escape single quotes
            StringBuilder escapedString = new StringBuilder();
            escapedString.Append("'");
            foreach (char c in parameterValue)
            {
                escapedString.Append(c);
                if (c == '\'')
                {
                    escapedString.Append(c);
                }
            }

            escapedString.Append("'");
            return escapedString.ToString();
        }

        private object EncodeInternal(object parameterValue)
        {
            return parameterValue;
        }
    }
}