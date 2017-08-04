#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################
function New-Trie {
    return @{}
}

function Add-WordToTrie {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Word,
        [Parameter(Mandatory=$true)]
        [hashtable]$Trie
    )

    $CurrentLevel = $Trie
    $Word = $Word.ToLower()
    $letter = $Word[0]

    if (-not $CurrentLevel.ContainsKey($letter)) {
        $CurrentLevel[$letter] = @{}
    }

    if ($Word.Length -gt 1) {
        $CurrentLevel[$letter] = Add-WordToTrie -Trie $CurrentLevel[$letter] -Word $Word.Substring(1)
    } else {
        $CurrentLevel[$letter]['IsLeaf'] = $true
    }

    return $CurrentLevel
}

function Test-Trie {
    param(
        [Parameter(Mandatory=$true)]
        [char]$Letter,
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [hashtable]$Trie
    )

    $Letter = [char]::ToLower($Letter)
    if ($Trie.ContainsKey($Letter)) {
        return $Trie[$Letter]
    }

    return $null
}

function Test-TrieLeaf {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [hashtable]$Trie
    )

    return $Trie -and $Trie.ContainsKey('IsLeaf')
}