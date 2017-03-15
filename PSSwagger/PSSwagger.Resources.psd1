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
    SamePropertyName=Same property name '{0}' is defined in a definition '{1}' with AllOf inheritance.
    DataTypeNotImplemented=Please get an implementation of '{0}' for '{1}'
    AutoRestNotInPath=Unable to find AutoRest.exe in PATH environment. Ensure the PATH is updated.
    AutoRestError=AutoRest resulted in an error
    SwaggerParamsMissing=No parameters in the Swagger
    SwaggerDefinitionsMissing=No definitions in the Swagger
    SwaggerPathsMissing=No paths in the Swagger
    FoundFileWithHash=Found file '{0}' with hash '{1}'
    FoundPowerShellCoreMsi=Found MSI installation of PowerShell Core of version '{0}'
    MustSpecifyPsCorePath=No installations of PowerShell Core could be found. Please provide -PowerShellCorePath to specify the location of PowerShell Core.
    PsCorePathNotFound=Couldn't find PowerShell at path '{0}'
    ParameterSetNotAllowed=The '{0}' parameter is not allowed when '{1}' is specified.
    AssemblyCompilationResult=Result of assembly compilation: {0}
    CmdletHasAmbiguousParameterSets=The generated cmdlet '{0}' contains ambiguous parameter sets. This is due to automatic merging of two or more similar paths.
###PSLOC
'@