namespace PSSwagger.LTF.Lib
{
    using System.Collections.Generic;
    using System.Dynamic;
    using System.Management.Automation;

    /// <summary>
    /// Extensions to convert certain types to dynamic.
    /// </summary>
    public static class AsDynamicExtensions
    {
        /// <summary>
        /// Convert a generic PSObject to a dynamic object.
        /// </summary>
        /// <param name="obj">PSObject to convert.</param>
        /// <returns>dynamic object.</returns>
        public static dynamic AsDynamic(this PSObject obj)
        {
            if (obj == null)
            {
                return null;
            }

            dynamic expando = new ExpandoObject();
            foreach (PSPropertyInfo pi in obj.Properties)
            {
                ((IDictionary<string, object>)expando)[pi.Name] = pi.Value;
            }

            return expando;
        }
    }
}