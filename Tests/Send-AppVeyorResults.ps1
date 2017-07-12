
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

    [Parameter(Mandatory=$true)]
    [string]
    $generatedModulesDir,

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
Write-Host "Zipping generated modules dir '$generatedModulesDir' assuming 7z is in path"
7z a .\Generated.zip $generatedModulesDir
Write-Host "Pushing generated modules zip to AppVeyor"
Push-AppveyorArtifact .\Generated.zip