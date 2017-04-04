class PowerShellServiceClientTracer : Microsoft.PowerShell.Commands.PSSwagger.PowerShellServiceClientTracerBase {
	[void] WriteToTraceStream([string]$message) {
		Write-Verbose -Message $message
	}
}

function New-PowerShellServiceClientTracer {
	[CmdletBinding()]
	param()
	
	return New-Object -TypeName PowerShellServiceClientTracer
}

function Set-ServiceClientTracing {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[bool]$Enabled = $false
	)
	
	[Microsoft.Rest.ServiceClientTracing]::IsEnabled = $Enabled
}

Export-ModuleMember -Function *