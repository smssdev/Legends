import { expect, test } from "@playwright/test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const page_url = "login.html";

test("the sign-in page has no accessibility violations", async ({ page }) => {
  await page.goto(page_url);
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  // @ts-expect-error axe is added to the page by the script tag above
  const violations = await page.evaluate(() => axe.run().then((r) => r.violations.map((v) => v.id)));
  expect(violations).toEqual([]);
});

test("the whole sign-in works with the keyboard only", async ({ page }) => {
  await page.goto(page_url);
  await page.keyboard.press("Tab");
  await page.keyboard.type("sara@example.com");
  await page.keyboard.press("Tab");
  await page.keyboard.type("bit2026code");
  await page.keyboard.press("Enter");
  await expect(page.getByRole("heading", { name: "Welcome back, Sara!" })).toBeVisible();
});
