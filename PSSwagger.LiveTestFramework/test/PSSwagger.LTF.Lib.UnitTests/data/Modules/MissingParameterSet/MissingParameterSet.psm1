function New-Guitar
{
    [CmdletBinding(DefaultParameterSetName='Guitar_CreateOrUpdate')]
    param(    
        [Parameter(Mandatory = $true, ParameterSetName = 'Guitar_Create')]
        [System.String]
        $Id,

        [System.String]
        $Name
    )

    Write-Host 'test'
}

function Get-Guitar
{
    [CmdletBinding(DefaultParameterSetName='Guitar_Get')]
    param(    
        [Parameter(Mandatory = $true, ParameterSetName = 'Guitar_GetById')]
        [System.String]
        $Id
    )

    Write-Host 'test'
}

Export-ModuleMember -Function New-Guitar,Get-Guitar