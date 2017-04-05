class PSSwaggerClientTracing : Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerClientTracingBase {
	[void] WriteToTraceStream([string]$message) {
		Write-Verbose -Message $message
	}
}

function New-PSSwaggerClientTracing {
	[CmdletBinding()]
	param()
	
	return New-Object -TypeName PSSwaggerClientTracing
}

function Enable-ServiceClientTracing {
	[CmdletBinding()]
	param()
	
	[Microsoft.Rest.ServiceClientTracing]::IsEnabled = $true
}

function Disable-ServiceClientTracing {
	[CmdletBinding()]
	param()
	
	[Microsoft.Rest.ServiceClientTracing]::IsEnabled = $false
}

Export-ModuleMember -Function *