class PSSwaggerClientTracing : Microsoft.PowerShell.Commands.PSSwagger.PSSwaggerClientTracingBase {
	[void] WriteToTraceStream([string]$message) {
		Write-Verbose -Message $message
	}
}

function New-PSSwaggerClientTracingInternal {
	[CmdletBinding()]
	param()
	
	return New-Object -TypeName PSSwaggerClientTracing
}

function Register-PSSwaggerClientTracingInternal {
	[CmdletBinding()]
	param(
		[PSSwaggerClientTracing]$TracerObject
	)
	
	[Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor($TracerObject)
}

function Unregister-PSSwaggerClientTracingInternal {
	[CmdletBinding()]
	param(
		[PSSwaggerClientTracing]$TracerObject
	)
	
	[Microsoft.Rest.ServiceClientTracing]::RemoveTracingInterceptor($TracerObject)
}

Export-ModuleMember -Function *