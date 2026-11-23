var calc = require("./calc").calc;

function make(orders, d) {
  var sum = 0;
  var lines = orders.map(function (o) {
    var t = calc(o, d);
    sum += t;
    return o.id + " " + (t / 100).toFixed(2);
  });
  return lines.join("\n") + "\nTOTAL " + (sum / 100).toFixed(2);
}

module.exports = {make: make};
