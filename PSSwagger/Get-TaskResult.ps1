Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

<#
.DESCRIPTION
   Get zero or more result items from a task. Optionally, skip N items or take only the top N items. If paged, assigns $PageResult.Result
   the page item result, and the returned result items are the items within the page.

.PARAMETER  TaskResult
    The started Task.

.PARAMETER  SkipInfo
    Object containing skip parameters or $null. Should contain the properties: 'Count', 'Max'

.PARAMETER  TopInfo
    Object containing top parameters or $null. Should contain the properties: 'Count', 'Max'

.PARAMETER  PageResult
    Object containing page result. Should contain the property: 'Result'

.PARAMETER  PageType
    Expected type of task result when the result is a page.
#>
function Get-TaskResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskResult,

        [Parameter(Mandatory=$false)]
        [PSObject]
        $SkipInfo = $null,

        [Parameter(Mandatory=$false)]
        [PSObject]
        $TopInfo = $null,

        [Parameter(Mandatory=$false)]
        [PSObject]
        $PageResult,

        [Parameter(Mandatory=$false)]
        [Type]
        $PageType
    )

    $ErrorActionPreference = 'Stop'               
    $null = $TaskResult.AsyncWaitHandle.WaitOne()               
    Write-Debug -Message "$($TaskResult | Out-String)"

    if ((Get-Member -InputObject $TaskResult -Name 'Result') -and
        $TaskResult.Result -and
        (Get-Member -InputObject $TaskResult.Result -Name 'Body') -and
        $TaskResult.Result.Body) {
        Write-Verbose -Message 'Operation completed successfully.'
        $result = $TaskResult.Result.Body
        Write-Debug -Message "$($result | Out-String)"
        if ($PageType -and ($result -is $PageType)) {
            if ($PageResult) {
                $PageResult.Page = $result
            }
            foreach ($item in $result) {
                if ($SkipInfo -and ($SkipInfo.Count++ -lt $SkipInfo.Max)) {
                }
                else {
                    if ((-not $TopInfo) -or ($TopInfo.Max -eq -1) -or ($TopInfo.Count++ -lt $TopInfo.Max)) {
                        $item
                    }
                    else {
                        break
                    }
                }
            }
        } else {
            $result
        }
    }
    elseif ($TaskResult.IsFaulted)
    {
        Write-Verbose -Message 'Operation failed.'
        if ($TaskResult.Exception) {
            if ((Get-Member -InputObject $TaskResult.Exception -Name 'InnerExceptions') -and $TaskResult.Exception.InnerExceptions) {
                foreach ($ex in $TaskResult.Exception.InnerExceptions) {
                    Write-Error -Exception $ex
                }
            }
            elseif ((Get-Member -InputObject $TaskResult.Exception -Name 'InnerException') -and $TaskResult.Exception.InnerException) {
                Write-Error -Exception $TaskResult.Exception.InnerException
            }
            else {
                Write-Error -Exception $TaskResult.Exception
            }
        }
    } 
    elseif ($TaskResult.IsCanceled)
    {
        Write-Verbose -Message 'Operation got cancelled.'
        Throw 'Operation got cancelled.'
    }
    else
    {
        Write-Verbose -Message 'Operation completed successfully.'
    }
}