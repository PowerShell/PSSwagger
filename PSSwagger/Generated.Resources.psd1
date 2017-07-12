#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################

ConvertFrom-StringData @'
###PSLOC

    CompilingBinaryComponent=Binary component '{0}' not found. Attempting to compile.
    CatalogHashNotValid=Catalog file's hash is not valid.
    HashValidationFailed=File hash validation failed.
    CompilationFailed=Failed to compile binary component '{0}'
    CSharpFilesNotFound=Could not find generated C# files in path '{0}'
    HashValidationSuccessful=Successfully validated hash of generated C# files.
    CompilationSucceeded=Successfully compiled binary component '{0}'
###PSLOC
'@