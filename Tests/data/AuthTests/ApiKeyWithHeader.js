// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
module.exports.auth = function (req) {
    var authHeader = req.header('authorization');
    var keyHeader = req.header('x-ms-api-key');
    if (authHeader == null) {
        return false;
    }

    if (keyHeader == null) {
        return false;
    }

    // API key with "Basic" prefix
    var expectedApiKey = "abc123";
    var expectedAuthHeader = "APIKEY " + expectedApiKey;

    return expectedAuthHeader == authHeader && keyHeader == expectedApiKey;
}