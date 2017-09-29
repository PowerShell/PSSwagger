# Azure Live Test Framework RPC Server for PSSwagger-generated modules
PSSwagger.LiveTestFramework is a PowerShell module containing a C#-based implementation of the Azure Test Framework protocol, based off the Visual Studio Code Language Server Protocol, which in turn is based off JSON-RPC. While we use the Azure Test Framework protocol as a base, we make a small extension upon the protocol to enable non-Azure modules to test against the server.

This module's test server is meant to act as a facade between test code and SDK or client implementations.

Live service <-> PSSwagger-generated module <-> PSSwagger.LiveTestFramework <-> Test code

## Why use the Azure Test Framework protocol over just calling the PSSwagger-generated module directly?
When you, as the service owner, have multiple language SDKs you need to test, you don't want to have to write duplicate test code. Using a JSON-RPC-based test protocol allows you to write test code once. In general, the flow when you adopt the Azure Test Framework protocol is this:

Live service <-> Language-specific SDK <-> Language-specific test server <-> Test code

# Other Documentation
TODO