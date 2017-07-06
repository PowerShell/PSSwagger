namespace PSSwagger.LTF.Lib.Credentials
{
    using Interfaces;
    using Logging;
    using Models;
    using System;
    using System.Globalization;
    using System.Management.Automation;
    using System.Security;

    /// <summary>
    /// Handle Azure Service Principal credentials.
    /// </summary>
    public class AzureCredentialProvider : ICredentialProvider
    {
        private Logger logger;

        public string TenantId { get; private set; }
        public string ClientId { get; private set; }
        public string Secret { get; private set; }

        public AzureCredentialProvider(Logger logger)
        {
            this.logger = logger;
        }

        public void Process(ICommandBuilder command)
        {
            if (String.IsNullOrEmpty(this.TenantId) || String.IsNullOrEmpty(this.ClientId) || String.IsNullOrEmpty(this.Secret))
            {
                throw new InvalidTestCredentialsException();
            }

            ICommandBuilder importAzureModule = command.Runspace.CreateCommand();
            importAzureModule.Command = "Import-Module";
            importAzureModule.AddParameter("Name", "AzureRM.Profile");
            CommandExecutionResult importAzureModuleResult = importAzureModule.Invoke();
            if (importAzureModuleResult.HadErrors)
            {
                importAzureModuleResult.LogErrors(this.logger);
                throw new CommandFailedException(importAzureModule, importAzureModuleResult);
            }

            ICommandBuilder addAzureRmAccount = command.Runspace.CreateCommand();
            addAzureRmAccount.Command = "Add-AzureRmAccount";
            SecureString ss = new SecureString();
            foreach (char c in this.Secret)
            {
                ss.AppendChar(c);
            }

            PSCredential credential = new PSCredential(this.ClientId, ss);
            addAzureRmAccount.AddParameter("Credential", credential);
            addAzureRmAccount.AddParameter("TenantId", this.TenantId);
            addAzureRmAccount.AddParameter("ServicePrincipal", true);
            CommandExecutionResult addAzureRmAccountResult = addAzureRmAccount.Invoke();
            if (addAzureRmAccountResult.HadErrors)
            {
                addAzureRmAccountResult.LogErrors(this.logger);
                throw new CommandFailedException(addAzureRmAccount, addAzureRmAccountResult);
            }
        }

        public void Set(string property, object value)
        {
            if (property.Equals("tenantid", StringComparison.OrdinalIgnoreCase))
            {
                this.TenantId = value.ToString();
            } else if (property.Equals("clientid", StringComparison.OrdinalIgnoreCase))
            {
                this.ClientId = value.ToString();
            } else if (property.Equals("secret", StringComparison.OrdinalIgnoreCase))
            {
                this.Secret = value.ToString();
            }
        }
    }
}