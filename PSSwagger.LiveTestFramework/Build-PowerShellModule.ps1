<#
.DESCRIPTION
  Builds the PSSwagger.LiveTestFramework module.
#>
[CmdletBinding()]
param(
    [string]
    $OutputDirectory
)

<#
.DESCRIPTION
  Copy an item and log it to verbose stream.
#>
function Copy-ItemWithLog {
    [CmdletBinding()]
    param(
        [string]
        $Path,

        [string]
        $Destination
    )

    Write-Verbose -Message "Copying file $Path to $Destination..."
    Copy-Item @PSBoundParameters
}

<#
.DESCRIPTION
  Remove the output directory if it exists then create it.
#>
function Prepare-OutputDirectory {
    [CmdletBinding()]
    param(
        [string]
        $OutputDirectory
    )

    if (Test-Path -Path $OutputDirectory) {
        Write-Verbose -Message "Cleaning module directory"
        Remove-Item -Path $OutputDirectory -ErrorAction SilentlyContinue -Recurse -Force
    }

    Write-Verbose -Message "Creating module directory"
    $null = New-Item -Path $OutputDirectory -ItemType Container -Force
}

<#
.DESCRIPTION
  Converts all source C# files (.cs) to code files (.Code.ps1).
#>
function Convert-CSharpFiles {
    [CmdletBinding()]
    param(
        [string]
        $SrcPath
    )

    Write-Verbose -Message "Converting all C# files to code files"
    
    pushd $srcPath
    & .\ConvertFrom-CSharpFiles.ps1
    popd
}

<#
.DESCRIPTION
  Copies PowerShell module files to the output directory (.psd1 and .psm1)
#>
function Copy-PowerShellModuleFiles {
    [CmdletBinding()]
    param(
        [string]
        $OutputDirectory,

        [string]
        $RepoPath
    )

    Copy-ItemWithLog -Path (Join-Path -Path $repoPath -ChildPath 'PSSwagger.LiveTestFramework.psd1') -Destination (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psd1')
    Copy-ItemWithLog -Path (Join-Path -Path $repoPath -ChildPath 'PSSwagger.LiveTestFramework.psm1') -Destination (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psm1')
}

<#
.DESCRIPTION
  Copies all code files in the correct directory structure to the output directory.
#>
function Copy-CodeProject {
    [CmdletBinding()]
    param(
        [string]
        $OutputDirectory,

        [string]
        $SrcPath,

        [string]
        $Project
    )

    Get-ChildItem -Path (Join-Path -Path $srcPath -ChildPath $Project | Join-Path -ChildPath '*.Code.ps1') -File | ForEach-Object {
        $dir = $_.DirectoryName
        if (-not ($dir.Contains('vs-csproj'))) {
            # Better way to do this?
            $subPath = $dir.Replace($srcPath, '').Trim("/").Trim("\")
            $outputDir = Join-Path -Path $OutputDirectory -ChildPath 'src' | Join-Path -ChildPath $subPath
            if (-not (Test-Path -Path $outputDir)) {
                $null = New-Item -Path $outputDir -ItemType Container -Force
            }
            $outputFilePath = Join-Path -Path $outputDir -ChildPath $_.Name
            
            Copy-ItemWithLog -Path $_.FullName -Destination $outputFilePath
        }
    }
}

<#
.DESCRIPTION
  Retrieves the release info file.
#>
function Get-ReleaseInfo {
    [CmdletBinding()]
    param(
        [string]
        $RepoPath
    )

    Get-Content -Path (Join-Path -Path $RepoPath -ChildPath 'release.json') | ConvertFrom-Json
}

<#
.DESCRIPTION
  Copies misc. files that might not need signing.
#>
function Copy-MiscFiles {
    [CmdletBinding()]
    param(
        [string]
        $OutputDirectory,

        [string]
        $RepoPath
    )

    Copy-ItemWithLog -Path (Join-Path -Path $RepoPath -ChildPath 'release.json') -Destination (Join-Path -Path $OutputDirectory -ChildPath 'release.json')
}

<#
.DESCRIPTION
  Replaces dynamic info in the module manifest, like ModuleVersion.
#>
function Set-ModuleManifestInfo {
    [CmdletBinding()]
    param(
        [object]
        $Release,

        [string]
        $OutputDirectory
    )

    $manifestContent = Get-Content -Path (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psd1')
    $manifestContent = $manifestContent.Replace("ModuleVersion = '9.9.9'", "ModuleVersion = '$($Release.version)'")
    $manifestContent | Out-File -FilePath (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psd1')
}

$topLevel = git rev-parse --show-toplevel
if (-not $topLevel) {
    Write-Error -Message "Not in git repo. Rerun after navigating to the correct git repo and using git init."
    return
}

$repoPath = Join-Path -Path $topLevel -ChildPath 'PSSwagger.LiveTestFramework'
$srcPath = Join-Path -Path $repoPath -ChildPath 'src'
$release = Get-ReleaseInfo -RepoPath $repoPath
$moduleOutputDirectory = Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework' | Join-Path -ChildPath $release.version
Prepare-OutputDirectory -OutputDirectory $moduleOutputDirectory
Convert-CSharpFiles -SrcPath $srcPath

# Copy PowerShell files
Copy-PowerShellModuleFiles -OutputDirectory $moduleOutputDirectory -RepoPath $repoPath
Copy-MiscFiles -OutputDirectory $moduleOutputDirectory -RepoPath $repoPath

# Copy code files
# This should ignore csproj, intermediate cs files
# Currently this is a non-recursive search for *.Code.ps1 files
Copy-CodeProject -OutputDirectory $moduleOutputDirectory -SrcPath $srcPath -Project 'PSSwagger.LTF.Lib' 
Copy-CodeProject -OutputDirectory $moduleOutputDirectory -SrcPath $srcPath -Project 'PSSwagger.LTF.ConsoleServer' 

Set-ModuleManifestInfo -Release $release -OutputDirectory $moduleOutputDirectory

# This currently only works in some cases.
if (-not $?) {
    Write-Host "Module packaging completed with errors." -BackgroundColor DarkRed
} else {
    Write-Host "Module packaged successfully." -BackgroundColor DarkGreen
}