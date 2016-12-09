param(
    [ValidateSet("All","UnitTest")]
    [string[]]$TestSuite = "All",
    [string[]]$TestName
)

$pesterParams = @{'ExcludeTag' = 'KnownIssue'; 'OutputFormat' = 'NUnitXml'; 'OutputFile' = 'TestResults.xml'}
if ($PSBoundParameters.ContainsKey('TestName')) {
    $pesterParams.TestName = $TestName
}

if ($TestSuite.Contains("All")) {
    Write-Verbose "Invoking all tests."
} else {
    $pesterParams.Tag = $TestSuite
}

Invoke-Pester @pesterParams