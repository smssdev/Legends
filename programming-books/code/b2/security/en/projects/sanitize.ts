import { withLab } from "../lab";

const inputs = [
  "<b>Bold</b> <i>italic</i>",
  '<img src=x onerror="window.hacked=true">',
  '<a href="javascript:alert(1)">Free gift</a>',
  "<script>window.hacked=true</script><p>Some text</p>",
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
        // Only the allowed tags survive; scripts and event handlers are removed
        (window as unknown as { DOMPurify: { sanitize(h: string, o: object): string } }).DOMPurify.sanitize(html, {
          ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p"],
          ALLOWED_ATTR: ["href"],
        }),
      input,
    );
    console.log(`${input}\n  → ${clean}`);
  }
});
