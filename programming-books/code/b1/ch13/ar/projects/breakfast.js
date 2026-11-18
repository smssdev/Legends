function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function make(item, ms) {
  await wait(ms);
  return item;
}

function seconds(start) {
  const ms = Date.now() - start;
  return (Math.round(ms / 100) / 10).toFixed(1);
}

async function main() {
  let start = Date.now();
  await make("شاي", 300);
  await make("خبز محمص", 400);
  await make("بيض", 500);
  console.log("واحداً بعد الآخر:", seconds(start), "ثانية");

  start = Date.now();
  const breakfast = await Promise.all([
    make("شاي", 300),
    make("خبز محمص", 400),
    make("بيض", 500),
  ]);
  console.log("كلها معاً:", seconds(start), "ثانية");
  console.log(breakfast.join(" + "));
}

main();
