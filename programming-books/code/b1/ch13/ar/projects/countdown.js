function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function countdown(from) {
  for (let n = from; n > 0; n--) {
    console.log(n + "…");
    await wait(200);
  }
  console.log("انطلق!");
}

countdown(3);
console.log("استعد…");
