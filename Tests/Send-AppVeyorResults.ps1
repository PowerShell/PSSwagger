[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $appVeyorUrl,

    [Parameter(Mandatory=$true)]
    [string]
    $testResultRootDir,

    [Parameter(Mandatory=$false)]
    [string]
    $testResultFilePattern = "*TestResults.xml"
)

Write-Host "Uploading test results to AppVeyor: $appVeyorUrl"
Get-ChildItem -Path $testResultRootDir -Filter $testResultFilePattern -File -Recurse | ForEach-Object {
    Write-Host "Uploading file: $($_.FullName)"
    (New-Object 'System.Net.WebClient').UploadFile($appVeyorUrl, "$($_.FullName)")
}