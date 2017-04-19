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

function Register-PSSwaggerClientTracing {
	[CmdletBinding()]
	param(
		[PSSwaggerClientTracing]$TracerObject
	)
	
	[Microsoft.Rest.ServiceClientTracing]::AddTracingInterceptor($TracerObject)
}

function Unregister-PSSwaggerClientTracing {
	[CmdletBinding()]
	param(
		[PSSwaggerClientTracing]$TracerObject
	)
	
	[Microsoft.Rest.ServiceClientTracing]::RemoveTracingInterceptor($TracerObject)
}

Export-ModuleMember -Function *