function calc(options, discount) {
  let total = 0;
  for (const item of options.l) {
    total += item.p * item.q;
  }

  if (discount && total > 20000) {
    total -= Math.floor(total * 0.1);
  }

  if (options.c === "VIP") {
    total -= 500;
  }

  return total < 0 ? 0 : total;
}

module.exports = { calc };
