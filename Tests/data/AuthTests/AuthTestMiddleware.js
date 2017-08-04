// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
var path = require('path');
var auth = null;
var authJsFile = '';
process.argv.forEach(function (val, index, array) {
    if (authJsFile == 'next') {
        authJsFile = val;
    } else if (val == '--auth') {
        authJsFile = 'next';
    }
});
if (authJsFile != 'next' && authJsFile != '') {
    console.log('  Loading auth file: ' + authJsFile);
    auth = require(path.join(__dirname, authJsFile));
}
module.exports = function (req, res, next) {
    if (auth == null) {
        next();
    } else {
        var isAuthorized = false;
        if (auth.auth(req)) {
            next();
        } else {
            res.set('WWW-Authenticate', 'Basic');
            res.sendStatus(401);
        }
    }
}