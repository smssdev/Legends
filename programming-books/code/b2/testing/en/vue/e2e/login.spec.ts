import { expect, test } from "@playwright/test";

const page_url = "login.html"; // relative to baseURL in playwright.config.ts

test("a user can sign in", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("Email").fill("sara@example.com");
  await page.getByLabel("Password").fill("bit2026code");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Welcome back, Sara!" })).toBeVisible();
});

test("a wrong password keeps the user on the form", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("Email").fill("sara@example.com");
  await page.getByLabel("Password").fill("nope");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("alert")).toHaveText("Wrong email or password.");
  await expect(page.getByLabel("Email")).toHaveValue("sara@example.com");
});
