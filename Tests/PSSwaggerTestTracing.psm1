class PSSwaggerTestClientTracing : Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerClientTracingBase {
	[void] WriteToTraceStream([string]$message) {
		Write-Host -Message $message
	}
}

function New-PSSwaggerTestClientTracing {
	[CmdletBinding()]
	param()
	
	return New-Object -TypeName PSSwaggerTestClientTracing
}