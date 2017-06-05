module.exports.auth = function (req) {
    var authHeader = req.header('authorization');
    if (authHeader == null) {
        return false;
    }

    // Base64 encoded string of "username:passwordAlt" with "Basic" prefix
    var expectedAuthHeader = "Basic dXNlcm5hbWU6cGFzc3dvcmRBbHQ=";

    return expectedAuthHeader == authHeader;
}