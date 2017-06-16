Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '*.Code.ps1') -Recurse -File | ForEach-Object {
    $dir = $_.DirectoryName
    # TODO: Ignore using .gitignore when we move PSSwagger.LiveTestFramework to a new repo
    if ((-not $dir.Contains('vs-csproj')) -and (-not $dir.Contains('obj')) -and (-not $dir.Contains('bin'))) {
        $filename = $_.BaseName.Substring(0, ($_.BaseName.Length)-5)
        $null = Move-Item -Path $_.FullName -Destination (Join-Path -Path $dir -ChildPath "$filename.cs") -Force
    }
}