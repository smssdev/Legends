function* range(from, to, step = 1) {
  for (let n = from; n <= to; n += step) {
    yield n; // توقف هنا وسلّم n للمستدعي
  }
}

console.log([...range(1, 10, 3)]);

// مولّد يقسم القائمة إلى صفحات
function* pages(items, size) {
  for (let i = 0; i < items.length; i += size) {
    yield items.slice(i, i + size);
  }
}

const letters = "ABCDEFG".split("");
for (const page of pages(letters, 3)) {
  console.log(page.join(" "));
}
