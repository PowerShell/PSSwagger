Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
   Determines if a result matches the given filter.

.PARAMETER  Result
    Result to filter

.PARAMETER  Filter
    Filter to apply
#>
function Test-FilteredResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Result,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Filter
    )

    $ErrorActionPreference = 'Stop'
    if ($Filter.Type -eq 'wildcard') {
        Test-WildcardFilterOnResult -Filter $Filter -Result $Result
    } elseif ($Filter.Type -eq 'equalityOperator') {
        Test-EqualityFilterOnResult -Filter $Filter -Result $Result
    }
}

function Test-WildcardFilterOnResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Result,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Filter
    )

    foreach ($char in $Filter.Value) {
        if ($char -ne $Filter.Character) {
            $regex += "[$char]"
        } else {
            $regex += ".*"
        }
    }

    $regex = $regex.Replace($Filter.Character, ".*")
    ($Result.($Filter.Property)) -match $regex
}

function Test-EqualityFilterOnResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Result,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Filter
    )

    if ($Filter.Operation -eq '<') {
        ($Result.($Filter.Property) -lt $Filter.Value)
    } elseif ($Filter.Operation -eq '<=') {
        ($Result.($Filter.Property) -le $Filter.Value)
    } elseif ($Filter.Operation -eq '=') {
        ($Result.($Filter.Property) -eq $Filter.Value)
    } elseif ($Filter.Operation -eq '>=') {
        ($Result.($Filter.Property) -ge $Filter.Value)
    } elseif ($Filter.Operation -eq '>') {
        ($Result.($Filter.Property) -gt $Filter.Value)
    }
}