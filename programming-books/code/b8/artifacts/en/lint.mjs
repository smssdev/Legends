import {chromium} from "playwright";
import path from "node:path";

// Checks any artifact should pass before it is shared.
async function lint(file) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const requests = [];
  page.on("request", (r) => r.url().startsWith("file:") || requests.push(r.url()));
  await page.goto(`file://${path.resolve(file)}`);
  const results = {
    "has a title": (await page.title()).trim().length > 0,
    "every input has a label": await page.$$eval("input", (inputs) =>
      inputs.every((i) => i.labels.length > 0 || i.getAttribute("aria-label"))),
    "makes no network requests": requests.length === 0,
  };
  await browser.close();
  return results;
}

for (const file of ["artifacts/tip-v1.html", "artifacts/tip-v2.html"]) {
  const results = await lint(file);
  const failed = Object.entries(results).filter(([, ok]) => !ok).map(([name]) => name);
  console.log(`${file}: ${failed.length ? `FAIL (${failed.join("; ")})` : "PASS"}`);
}
