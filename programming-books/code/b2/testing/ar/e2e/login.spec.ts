import { expect, test } from "@playwright/test";

const page_url = "react/login.html"; // relative to baseURL in playwright.config.ts

test("يستطيع المستخدم تسجيل الدخول", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("البريد الإلكتروني").fill("sara@example.com");
  await page.getByLabel("كلمة المرور").fill("bit2026code");
  await page.getByRole("button", { name: "سجّل الدخول" }).click();
  await expect(page.getByRole("heading", { name: "أهلاً بعودتك يا سارة!" })).toBeVisible();
});

test("كلمة المرور الخاطئة تُبقي المستخدم في النموذج", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("البريد الإلكتروني").fill("sara@example.com");
  await page.getByLabel("كلمة المرور").fill("nope");
  await page.getByRole("button", { name: "سجّل الدخول" }).click();
  await expect(page.getByRole("alert")).toHaveText("البريد أو كلمة المرور غير صحيحة.");
  await expect(page.getByLabel("البريد الإلكتروني")).toHaveValue("sara@example.com");
});
