#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger.Common.Helpers Module
#
#########################################################################################

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