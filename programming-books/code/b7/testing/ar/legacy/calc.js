// do not touch - MK 2019
function calc(o, d) {
  var t = 0;
  for (var i = 0; i < o.l.length; i++) {
    var x = o.l[i];
    t += x.p * x.q;
  }
  if (d && t > 20000) t = t - Math.floor(t * 0.1);
  if (o.c == "VIP") t = t - 500;
  return t < 0 ? 0 : t;
}

module.exports = {calc: calc};
