function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function makeTea() {
  console.log("Boiling the water…");
  await wait(300);
  console.log("Steeping the tea…");
  await wait(300);
  console.log("Done.");
  return "A cup of tea";
}

makeTea().then((result) => console.log(result));
console.log("Meanwhile, I set the table.");
