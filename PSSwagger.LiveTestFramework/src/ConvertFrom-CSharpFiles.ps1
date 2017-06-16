Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '*.cs') -Recurse -File | ForEach-Object {
    $dir = $_.DirectoryName
    # TODO: Ignore using .gitignore when we move PSSwagger.LiveTestFramework to a new repo
    if ((-not $dir.Contains('vs-csproj')) -and (-not $dir.Contains('obj')) -and (-not $dir.Contains('bin'))) {
        $null = Move-Item -Path $_.FullName -Destination (Join-Path -Path $dir -ChildPath "$($_.BaseName).Code.ps1") -Force
    }
}