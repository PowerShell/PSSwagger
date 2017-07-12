#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under the MIT license.
#
# PSSwagger Module
#
#########################################################################################

# Note: Plural to Singular mapping is case-sensitive in PluralizationService.
$script:CustomPluralToSinglularMapList = @(
    @{Databases = 'Database'}
    @{databases = 'database'}
)