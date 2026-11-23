// nightly job
var store = require("./lib/store");
var report = require("./lib/report");

store.load("data/orders.json", function (err, orders) {
  if (err) return console.log("ERR " + err);
  console.log(report.make(orders, true));
});
