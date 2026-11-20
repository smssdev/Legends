import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  // Start the site before the tests, and stop it after. In a Vite project: "npm run build && npm run preview".
  webServer: { command: "node ../../serve.mjs 4173", url: "http://localhost:4173/vendor/react.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4173/testing/en/", browserName: "chromium" },
});
