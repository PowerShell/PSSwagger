namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using System;
    using System.Collections;
    using System.Collections.Generic;

    /// <summary>
    /// Mock command builder. Collects parameters and history of Invoke calls.
    /// </summary>
    public class MockCommandBuilder : ICommandBuilder
    {
        public Dictionary<string, Tuple<object, bool>> Parameters { get; private set; }
        public string Command { get; set; }
        public IList<string> InvokeHistory { get; private set; }

        public MockCommandBuilder()
        {
            this.Parameters = new Dictionary<string, Tuple<object, bool>>();
            this.InvokeHistory = new List<string>();
        }

        public ICommandBuilder AddParameter(string parameterName, object parameterValue, bool switchParameter = false)
        {
            this.Parameters[parameterName] = new Tuple<object, bool>(parameterValue, switchParameter);
            return this;
        }

        public IEnumerable Invoke()
        {
            // Format for mock is: command [parameterName parameterValue.ToString() isSwitch]+
            string invokeString = this.Command;
            if (this.Parameters.Keys.Count > 0)
            {
                foreach (string key in this.Parameters.Keys)
                {
                    invokeString += String.Format(" [{0} {1} {2}]", key, this.Parameters[key].Item1.ToString(), this.Parameters[key].Item2);
                }
            }

            this.InvokeHistory.Add(invokeString);

            return null;
        }
    }
}