<#
.DESCRIPTION
  This script loads the required modules for PSSwagger.LiveTestFramework.Tests and then loads PSSwagger.LiveTestFramework.Tests itself, assuming we're in the PSSwagger repo.
#>
[CmdletBinding()]
param()

$topLevel = git rev-parse --show-toplevel
if (-not $topLevel) {
    Write-Error "Not in git repo. Rerun after navigating to the correct git repo and using git init."
    return
}

Write-Verbose -Message "Git repo root: $topLevel"
Import-Module (Join-Path -Path $topLevel -ChildPath PSSwagger | Join-Path -ChildPath PSSwaggerUtility) -Force
Import-Module (Join-Path -Path $topLevel -ChildPath PSSwagger.LiveTestFramework | Join-Path -ChildPath test | Join-Path -ChildPath PSSwagger.LiveTestFramework.Tests.psd1) -Force