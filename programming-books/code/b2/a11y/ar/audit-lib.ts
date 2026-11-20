import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
// Only the few Playwright functions this script uses
type Page = {
  goto(url: string): Promise<unknown>;
  addScriptTag(options: { path: string }): Promise<unknown>;
  evaluate<T>(fn: () => T | Promise<T>): Promise<T>;
};
type Browser = { newPage(): Promise<Page>; close(): Promise<void> };
const { chromium } = require("playwright") as { chromium: { launch(): Promise<Browser> } };
const axePath = require.resolve("axe-core/axe.min.js");

type Violation = { id: string; impact: string; help: string; nodes: unknown[] };

// Opens a page (a path from the current folder) in a real browser, runs axe-core, and prints what fails
export async function audit(page: string): Promise<number> {
  const browser = await chromium.launch();
  const tab = await browser.newPage();
  await tab.goto(pathToFileURL(resolve(page)).href);
  await tab.addScriptTag({ path: axePath });
  const violations = (await tab.evaluate(() =>
    // @ts-expect-error axe is added to the page by the script tag above
    axe.run({ runOnly: ["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa", "best-practice"] }).then((r) => r.violations),
  )) as Violation[];
  await browser.close();

  for (const v of violations) {
    console.log(`[${v.impact}] ${v.id}: ${v.help} (${v.nodes.length})`);
  }
  return violations.length;
}
