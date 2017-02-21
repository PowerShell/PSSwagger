#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Localized Utils.Resources.psd1
#
#########################################################################################

ConvertFrom-StringData @'
###PSLOC

    AlgorithmNotSupported=Hash algorithm '{0}' not supported.
    FailedToReadFile=Failed to read file to hash. File: '{0}'
    AzureRestBootstrapPrompt=PSSwagger needs to download the Microsoft.Rest.ClientRuntime.Azure NuGet package to compile the generated assembly for .NET Framework.
    AzureRestBootstrapDownload=The download of the Microsoft.Rest.ClientRuntime.Azure NuGet package will occur during a later stage of PSSwagger.
    AzureRestMissing=PSSwagger requires the Microsoft.Rest.ClientRuntime.Azure NuGet package for this stage of its operation, but the user did not give consent to download the package.
    NugetBootstrapPrompt=PSSwagger requires NuGet.exe, which will be downloaded from '{0}'
    NugetBootstrapDownload=Downloading latest NuGet.exe...
    NugetMissing=Missing NuGet.exe from local tools folder or Path environment variable. Please rerun PSSwagger and give consent to bootstrap dependencies or add NuGet.exe to your Path variable manually.
    BootstrapConfirmTitle=Missing PSSwagger dependencies
    BootstrapConfirmPrompt=Do you want PSSwagger to download the dependencies listed above if they are missing?
    BootstrapConfirmYesDescription=Gives consent to download all missing PSSwagger dependencies.
    BootstrapConfirmNoDescription=Does not give consent to download all missing PSSwagger dependencies.
    YesPrompt=&Yes
    NoPrompt=&No
    NuGetOutput=NuGet.exe output: {0}
###PSLOC
'@