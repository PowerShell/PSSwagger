
#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Tests
#
#########################################################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $appVeyorUrl,

    [Parameter(Mandatory=$true)]
    [string]
    $testResultRootDir,

    [Parameter(Mandatory=$true)]
    [string]
    $testResultFilePattern,

    [Parameter(Mandatory=$false)]
    [string]
    $_garbage
)

Write-Host "Uploading test results to AppVeyor: $appVeyorUrl"
Write-Host "Searching path recursively for results: $testResultRootDir"
Write-Host "Test result pattern: $testResultFilePattern"
$webClient = New-Object 'System.Net.WebClient'
Get-ChildItem -Path "$testResultRootDir" -Filter $testResultFilePattern -File -Recurse | ForEach-Object {
    Write-Host "Uploading file: $($_.FullName)"
    $webClient.UploadFile($appVeyorUrl, "$($_.FullName)")
}
$blockRdp = $true
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/appveyor/ci/master/scripts/enable-rdp.ps1'))