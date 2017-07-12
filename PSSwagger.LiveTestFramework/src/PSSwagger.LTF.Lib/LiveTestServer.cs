namespace PSSwagger.LTF.Lib
{
    using Credentials;
    using Interfaces;
    using Logging;
    using Messages;
    using Models;
    using System;
    using System.Threading;
    using System.Threading.Tasks;

    public class LiveTestServerStartParams
    {
        public IInputPipe Input { get; set; }
        public IOutputPipe Output { get; set; }
        public Logger Logger { get; set; }
        public IRunspaceManager RunspaceManager { get; set; }
        public string ModulePath { get; set; }
        public LiveTestCredentialFactory CredentialFactory { get; set; }
    }

    /// <summary>
    /// Main class for starting and interacting with the live test server.
    /// </summary>
    public class LiveTestServer
    {
        private LiveTestServerStartParams parameters;
        private GeneratedModule currentModule;
        private Thread messageReadThread;

        public IInputPipe Input { get; private set; }
        public IOutputPipe Output { get; private set; }
        public bool IsRunning { get; private set; }
        public LiveTestServer(LiveTestServerStartParams parms)
        {
            if (parms == null)
            {
                throw new ArgumentNullException("parms");
            }
            if (parms.Input == null)
            {
                throw new ArgumentNullException("parms.Input");
            }
            if (parms.Output == null)
            {
                throw new ArgumentNullException("parms.Output");
            }
            if (parms.RunspaceManager == null)
            {
                throw new ArgumentNullException("parms.RunspaceManager");
            }
            if (parms.CredentialFactory == null)
            {
                throw new ArgumentNullException("parms.CredentialFactory");
            }
            if (String.IsNullOrEmpty(parms.ModulePath))
            {
                throw new ArgumentNullException("parms.ModulePath");
            }

            this.parameters = parms;
            this.Input = parms.Input;
            this.Output = parms.Output;
            this.IsRunning = false;
            this.currentModule = null;
            this.messageReadThread = null;
        }

        public async Task RunAsync()
        {
            if (this.IsRunning)
            {
                throw new InvalidOperationException("Server is already running.");
            }
            
            // Retrieve all module information using the current runspace manager
            this.currentModule = this.parameters.RunspaceManager.GetModuleInfo(this.parameters.ModulePath);

            this.IsRunning = true;

            // Start message read thread
            this.messageReadThread = new Thread(async () =>
            {
                while (this.IsRunning)
                {
                    try
                    {
                        LiveTestRequest msg = await this.Input.ReadBlock<LiveTestRequest>();
                        if (this.IsRunning)
                        {
                            if (this.parameters.Logger != null)
                            {
                                this.parameters.Logger.LogAsync("Processing message: {0}", msg);
                            }
                            try
                            {
                                Task.Run(() => this.currentModule.ProcessRequest(msg, this.parameters.CredentialFactory));
                            } catch (Exception eProcess)
                            {
                                // TODO: Log
                            }
                        }
                    } catch (Exception eRead)
                    {
                        // TODO: Log
                    }
                }
            }) { IsBackground = true };
            this.messageReadThread.Start();
        }

        public void Stop()
        {
            this.IsRunning = false;
            // For core CLR, the thread will still be waiting for input. The next message, depending on when it comes in, may be ignored.
#if !CORECLR
            this.messageReadThread.Abort();
            this.messageReadThread = null;
#endif
        }
    }
}
