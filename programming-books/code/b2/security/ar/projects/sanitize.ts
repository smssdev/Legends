import { withLab } from "../lab";

const inputs = [
  "<b>عريض</b> <i>مائل</i>",
  '<img src=x onerror="window.hacked=true">',
  '<a href="javascript:alert(1)">هدية مجانية</a>',
  "<script>window.hacked=true</script><p>بعض النص</p>",
];

await withLab({}, async (page, base) => {
  await page.goto(base + "sanitize.html");
  await page.evaluate(async (src) => {
    const s = document.createElement("script");
    s.src = src;
    document.head.append(s);
    await new Promise((r) => (s.onload = r));
  }, base + "purify.js");
  for (const input of inputs) {
    const clean = await page.evaluate(
      (html) =>
        // تبقى الوسوم المسموحة فقط، وتُحذف السكربتات ومعالجات الأحداث
        (window as unknown as { DOMPurify: { sanitize(h: string, o: object): string } }).DOMPurify.sanitize(html, {
          ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p"],
          ALLOWED_ATTR: ["href"],
        }),
      input,
    );
    console.log(`${input}\n  → ${clean}`);
  }
});
