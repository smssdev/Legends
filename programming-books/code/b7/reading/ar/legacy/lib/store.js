var fs = require("fs");

function load(f, cb) {
  fs.readFile(f, "utf8", function (err, txt) {
    if (err) return cb(err);
    try {
      cb(null, JSON.parse(txt));
    } catch (e) {
      cb(e);
    }
  });
}

module.exports = {load: load};
