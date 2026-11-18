function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function makeTea() {
  console.log("أغلي الماء…");
  await wait(300);
  console.log("أنقع الشاي…");
  await wait(300);
  console.log("انتهيت.");
  return "كوب من الشاي";
}

makeTea().then((result) => console.log(result));
console.log("في الأثناء، أجهّز المائدة.");
