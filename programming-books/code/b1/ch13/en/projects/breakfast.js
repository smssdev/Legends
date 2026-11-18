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
  await make("tea", 300);
  await make("toast", 400);
  await make("eggs", 500);
  console.log("One after another:", seconds(start), "seconds");

  start = Date.now();
  const breakfast = await Promise.all([
    make("tea", 300),
    make("toast", 400),
    make("eggs", 500),
  ]);
  console.log("All at once:", seconds(start), "seconds");
  console.log(breakfast.join(" + "));
}

main();
