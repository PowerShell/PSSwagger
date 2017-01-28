#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Localized PSSwagger.Resources.psd1
#
#########################################################################################

ConvertFrom-StringData @'
###PSLOC

    ConvertingSwaggerSpecToGithubContent=Converting SwaggerSpecUri to raw github content '{0}'
    SwaggerSpecDownloadedTo=Swagger spec from '{0}' is downloaded to '{1}'
    ExpandDefinition=Trying to expand the '{0}' defnition.
    UnableToExpandDefinition=Unable to expand the '{0}' definition in current iteration.
    UnapprovedVerb=Verb '{0}' not an approved verb.
    ReplacedVerb=Using Verb '{0}' in place of '{1}'.
    UsingNounVerb=Using Noun '{0}'. Using Verb '{1}'
    GenerateCodeUsingAutoRest=Generating CSharp Code using AutoRest
    GenerateAssemblyFromCode=Generating assembly from the CSharp code
    GeneratedAssembly=Generated '{0}' assembly
    UnableToGenerateAssembly=Unable to generate '{0}' assembly
    InvalidSwaggerSpecification=Invalid Swagger specification file. Info section doesn't exists.
    SwaggerSpecPathNotExist=Swagger file $SwaggerSpecPath does not exist. Check the path
    SamePropertyName=Same property name should not be defined in a definition with AllOf inheritance.
    DataTypeNotImplemented=Please get an implementation of '{0}' for '{1}'
    AutoRestNotInPath=Unable to find AutoRest.exe in PATH environment. Ensure the PATH is updated.
    AutoRestError=AutoRest resulted in an error
    SwaggerParamsMissing=No parameters in the Swagger
    SwaggerDefinitionsMissing=No definitions in the Swagger
    SwaggerPathsMissing=No paths in the Swagger
    DiscoveredFrameworks=Automatically set Frameworks to: '{0}'
    DiscoveredRuntimes=Automatically set Runtimes to: '{0}'
    CompileForFrameworkAndRuntime=Compiling for framework '{0}' and runtime '{1}'
    CompileFailed=One or more assemblies failed to compile. See preceding error messages for specific errors.
    CoreClrWrongBuildType=dotnet CLI version found in path does not support build project '{0}'. Supported project type: '{1}'
    PsSwaggerSupportedDotNetCliVersion=PSSwagger currently only supports building with dotnet CLI preview3 or earlier.
    DotNetFailedToRestorePackages=Failed to restore packages.
    DotNetFailedToBuild=Failed to build and publish.
    DotNetExeNotFound=dotnet.exe not found in Path and -AutomaticBootstrap not specified. Please download your preferred version of dotnet CLI and add dotnet.exe to your Path variable.
    DotNetExeVersion=Output of dotnet --version: {0}
    CopyDirectoryToDestination=Copying directory '{0}' to '{1}'
###PSLOC
'@