<#
.DESCRIPTION
  Builds the PSSwagger.LiveTestFramework module.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $OutputDirectory
)

<#
.DESCRIPTION
  Remove the output directory if it exists then create it.
#>
function Prepare-OutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [string]
        $SrcPath
    )

    Write-Verbose -Message "Converting all C# files to code files"
    
    & $SrcPath\ConvertFrom-CSharpFiles.ps1
}

<#
.DESCRIPTION
  Copies PowerShell module files to the output directory (.psd1 and .psm1)
#>
function Copy-PowerShellModuleFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$true)]
        [string]
        $RepoPath
    )

    Copy-Item -Path (Join-Path -Path $repoPath -ChildPath 'PSSwagger.LiveTestFramework.psd1') -Destination (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psd1') -Verbose
    Copy-Item -Path (Join-Path -Path $repoPath -ChildPath 'PSSwagger.LiveTestFramework.psm1') -Destination (Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psm1') -Verbose
}

<#
.DESCRIPTION
  Copies all code files in the correct directory structure to the output directory.
#>
function Copy-CodeProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputDirectory,

        [Parameter(Mandatory=$true)]
        [string]
        $SrcPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Project
    )

    Get-ChildItem -Path (Join-Path -Path $srcPath -ChildPath $Project | Join-Path -ChildPath '*.Code.ps1') -File | ForEach-Object {
        $dir = $_.Directory
        $subPath = "\"
        while ($dir -and $dir.FullName -ne $srcPath) {
            $subPath = Join-Path $dir.Name -ChildPath $dirName
            $dir = $dir.Parent
        }
        $outputDir = Join-Path -Path $OutputDirectory -ChildPath 'src' | Join-Path -ChildPath $subPath
        if (-not (Test-Path -Path $outputDir -PathType Container)) {
            $null = New-Item -Path $outputDir -ItemType Container -Force
        }
        $outputFilePath = Join-Path -Path $outputDir -ChildPath $_.Name
            
        Copy-Item -Path $_.FullName -Destination $outputFilePath -Verbose
    }
}

<#
.DESCRIPTION
  Retrieves the release info file.
#>
function Get-ReleaseInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $RepoPath
    )

    Get-Content -Path (Join-Path -Path $RepoPath -ChildPath 'release.json') | ConvertFrom-Json
}

<#
.DESCRIPTION
  Replaces dynamic info in the module manifest, like ModuleVersion.
#>
function Set-ModuleManifestInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Release,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputDirectory
    )

    $psd1Path = Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework.psd1'
    $manifestContent = Get-Content -Path $psd1Path
    $manifestContent = $manifestContent.Replace("ModuleVersion = '9.9.9'", "ModuleVersion = '$($Release.version)'")
    $manifestContent | Out-File -FilePath $psd1Path
}

$srcPath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$release = Get-ReleaseInfo -RepoPath $PSScriptRoot
$moduleOutputDirectory = Join-Path -Path $OutputDirectory -ChildPath 'PSSwagger.LiveTestFramework' | Join-Path -ChildPath $release.version
Prepare-OutputDirectory -OutputDirectory $moduleOutputDirectory
Convert-CSharpFiles -SrcPath $srcPath

# Copy PowerShell files
Copy-PowerShellModuleFiles -OutputDirectory $moduleOutputDirectory -RepoPath $PSScriptRoot

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