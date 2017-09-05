function New-Guitar
{
    [CmdletBinding(DefaultParameterSetName='Guitar_Create')]
    param(    
        [Parameter(Mandatory = $true, ParameterSetName = 'Guitar_Create')]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true, ParameterSetName = 'Guitar_CreateByName')]
        [System.String]
        $Name
    )

    Write-Host 'test'
}

function Get-Guitar
{
    [CmdletBinding(DefaultParameterSetName='Guitar_Get')]
	[OutputType([System.String])]
    param(    
        [Parameter(Mandatory = $true, ParameterSetName = 'Guitar_GetById')]
        [System.String]
        $Id
    )

    Write-Host 'test'
}

Export-ModuleMember -Function New-Guitar,Get-Guitar