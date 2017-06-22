namespace PSSwagger.LTF.Lib.UnitTests.Mocks
{
    using Interfaces;
    using Messages;
    using System.Collections;

    /// <summary>
    /// Mock generated module that tracks if methods are called.
    /// </summary>
    public class MockGeneratedModule : GeneratedModule
    {
        public MockGeneratedModule(IRunspaceManager runspace) : base(runspace) { }

        public bool LoadCalled { get; set; }
        public bool ProcessRequestCalled { get; set; }

        public override void Load(bool force = false)
        {
            this.LoadCalled = true;
        }

        public override IEnumerable ProcessRequest(LiveTestRequest request)
        {
            this.ProcessRequestCalled = true;
            return null;
        }
    }
}