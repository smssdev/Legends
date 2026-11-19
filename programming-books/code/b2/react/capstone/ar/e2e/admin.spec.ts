import { expect, test, type Page } from "@playwright/test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const words = { orders: "الطلبات", paid: "مدفوع", shipped: "مشحون", overview: "نظرة عامة" };

async function noViolations(page: Page) {
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  // @ts-expect-error axe is added to the page by the script tag above
  const found: string[] = await page.evaluate(() => axe.run().then((r) => r.violations.map((v) => v.id)));
  expect(found).toEqual([]);
}

test.beforeEach(async ({ page }) => {
  await page.goto("page.html");
});

test("يمكن تحويل طلب إلى مشحون", async ({ page }) => {
  await page.getByRole("link", { name: words.orders }).click();
  await page.getByRole("link", { name: words.paid, exact: true }).click();
  await page.getByRole("row").nth(1).getByRole("link").click();
  await page.getByRole("button", { name: words.shipped }).click();
  await expect(page.locator("dd .badge")).toHaveText(words.shipped);
});

test("النظرة العامة والطلبات بلا مخالفات إتاحة", async ({ page }) => {
  await expect(page.getByRole("heading", { name: words.overview })).toBeVisible();
  await noViolations(page);
  await page.getByRole("link", { name: words.orders }).click();
  await expect(page.getByRole("table")).toBeVisible();
  await noViolations(page);
});

test("يتحول التطبيق كله إلى الإنجليزية، من اليسار إلى اليمين", async ({ page }) => {
  await page.getByRole("button", { name: "English" }).click();
  await expect(page.locator("html")).toHaveAttribute("dir", "ltr");
  await expect(page.getByRole("heading", { name: "Overview" })).toBeVisible();
});
