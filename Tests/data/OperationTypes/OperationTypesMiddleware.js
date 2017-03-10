var async = require('async')
var request = require('request')
module.exports = function (req, res, next) {
  if (req.method == 'PUT') {
    var getPath = req.protocol + '://' + req.headers['host'] + req.path
    var arr = req.path.split('/')
    // First is empty string always
    // Second is resource name
    // Third is ID
    if (arr.length >= 3) {
      var id = arr[2]
    }

    async.waterfall([
      function (callback) {
        request.get(getPath).on('response', function (response) {
          if (response.statusCode != 200) {
            // Item doesn't exist or came back as an error, so POST it instead
            req.method = 'POST'
            // URL needs to change to remove the ID
            req.url = req.url.replace(id, '')
          }
          callback(null)
        });
      },
      function (callback) {
        next()
      }], function (err, results) {
      }
    );
  } else {
    next()
  }
}