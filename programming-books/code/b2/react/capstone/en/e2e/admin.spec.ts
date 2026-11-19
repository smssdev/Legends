import { expect, test, type Page } from "@playwright/test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const words = { orders: "Orders", paid: "Paid", shipped: "Shipped", overview: "Overview" };

async function noViolations(page: Page) {
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  // @ts-expect-error axe is added to the page by the script tag above
  const found: string[] = await page.evaluate(() => axe.run().then((r) => r.violations.map((v) => v.id)));
  expect(found).toEqual([]);
}

test.beforeEach(async ({ page }) => {
  await page.goto("page.html");
});

test("an order can be marked as shipped", async ({ page }) => {
  await page.getByRole("link", { name: words.orders }).click();
  await page.getByRole("link", { name: words.paid, exact: true }).click();
  await page.getByRole("row").nth(1).getByRole("link").click();
  await page.getByRole("button", { name: words.shipped }).click();
  await expect(page.locator("dd .badge")).toHaveText(words.shipped);
});

test("the overview and the orders have no accessibility violations", async ({ page }) => {
  await expect(page.getByRole("heading", { name: words.overview })).toBeVisible();
  await noViolations(page);
  await page.getByRole("link", { name: words.orders }).click();
  await expect(page.getByRole("table")).toBeVisible();
  await noViolations(page);
});

test("the whole app switches to Arabic, right to left", async ({ page }) => {
  await page.getByRole("button", { name: "العربية" }).click();
  await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
  await expect(page.getByRole("heading", { name: "نظرة عامة" })).toBeVisible();
});
