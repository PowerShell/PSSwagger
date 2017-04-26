$script:PSCommandVerbMap = @{

    Access = 'Get'
    List = 'Get'
    Cat = 'Get'
    Type = 'Get'
    Dir = 'Get'
    Obtain = 'Get'
    Dump = 'Get'
    Acquire = 'Get'
    Examine = 'Get'
    Suggest = 'Get'

    Create = 'New'
    Generate = 'New'
    Allocate = 'New'
    Provision = 'New'
    Make = 'New'

    CreateOrUpdate = 'New,Set'
    Failover = 'Set'
    Assign = 'Set'
    Configure = 'Set'

    Activate = 'Initialize'

    Build = 'Build'
    Compile = 'Build'

    Deploy = 'Deploy'

    Apply = 'Add'
    Append = 'Add'
    Attach = 'Add'
    Concatenate = 'Add'
    Insert = 'Add'

    Delete = 'Remove'
    Cut = 'Remove'
    Dispose = 'Remove'
    Discard = 'Remove'
    
    Generalize = 'Reset'

    Patch = 'Update'
    Refresh = 'Update'
    Regenerate = 'Update' # Alternatives: Redo, New, Reset
    Reprocess = "Update" # Alternatives: Redo
    Upgrade = 'Update'
    Reimage = 'Update' # Alternatives: Format, Reset

    Validate = 'Test'
    Check = 'Test'
    Analyze = 'Test' 
    Is = 'Test'
    Evaluate = 'Test' # Alternatives: Invoke

    Power = 'Start'
    PowerOn = 'Start'
    Run = 'Start' # Alternatives: Invoke
    Trigger = 'Start'

    Pause = 'Suspend'
    
    Cancel = 'Stop'
    PowerOff = 'Stop'
    End = 'Stop'
    Shutdown = 'Stop'

    Reboot = 'Restart'
    ForceReboot = 'Restart'

    Finish = 'Complete'

    Wipe = 'Clear'
    Purge = 'Clear' # Alternatives: Remove
    Flush = 'Clear'
    Erase = 'Clear'
    Unmark = 'Clear'
    Unset = 'Clear'
    Nullify = 'Clear'

    Recover = 'Restore'

    Synchronize = 'Sync'
    Synch = 'Sync'

    Load = 'Import'

    Capture = 'Export' # Alternatives: Trace

    Migrate = 'Move' # Alternatives: Export
    Transfer = 'Move'
    Name = 'Move'

    Change = 'Rename'

    Swap = 'Switch' # Alternatives: Move
    
    Execute = 'Invoke'

    Discover = 'Find' # Alternatives: Search
    Locate = 'Find'

    Release = 'Publish' # Alternatives: Clear, Unlock

    Resubmit = 'Submit'
    
    Duplicate = 'Copy'
    Clone = 'Copy'
    Replicate = 'Copy'
    
    Into = 'Enter'    
   
    Combine = 'Join'
    Unite = 'Join'
    Associate = 'Join'
    
    Restrict = 'Lock'
    Secure = 'Lock'
    
    Unrestrict = 'Unlock'
    Unsecure = 'Unlock'
    
    Display = 'Show'
    Produce = 'Show'
    
    Bypass = 'Skip'
    Jump = 'Skip'
    
    Separate = 'Split'
}