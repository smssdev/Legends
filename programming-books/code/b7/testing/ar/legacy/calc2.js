const calc = (o, d) => {
  let t = 0;
  for (const x of o.l) {
    t += x.p * x.q;
  }
  if (d && t > 20000) {
    t = t - Math.floor(t * 0.1);
  }
  if (o.c === "VIP") {
    t = t - 500;
  }
  return t < 0 ? 0 : t;
};

module.exports = { calc };
