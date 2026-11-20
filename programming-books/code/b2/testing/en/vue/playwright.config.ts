import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  // Start the site before the tests, and stop it after. In a Vite project: "npm run build && npm run preview".
  webServer: { command: "node ../../../serve.mjs 4174", url: "http://localhost:4174/vendor-vue/vue.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4174/testing/en/vue/", browserName: "chromium" },
});
