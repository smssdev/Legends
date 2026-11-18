// ar/audit-lib.ts
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
var require2 = createRequire(import.meta.url);
var { chromium } = require2("playwright");
var axePath = require2.resolve("axe-core/axe.min.js");
async function audit(page) {
  const browser = await chromium.launch();
  const tab = await browser.newPage();
  await tab.goto(pathToFileURL(resolve(page)).href);
  await tab.addScriptTag({ path: axePath });
  const violations = await tab.evaluate(
    () => (
      // @ts-expect-error axe is added to the page by the script tag above
      axe.run({ runOnly: ["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa", "best-practice"] }).then((r) => r.violations)
    )
  );
  await browser.close();
  for (const v of violations) {
    console.log(`[${v.impact}] ${v.id}: ${v.help} (${v.nodes.length})`);
  }
  return violations.length;
}

// ar/audit-before.ts
var count = await audit("./before.html");
console.log(`\u0642\u0628\u0644: ${count} \u0645\u0634\u0643\u0644\u0627\u062A`);
