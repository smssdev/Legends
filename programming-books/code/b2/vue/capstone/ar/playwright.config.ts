import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  webServer: { command: "node ../../../serve.mjs 4176", url: "http://localhost:4176/vendor-vue/vue.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4176/vue/capstone/ar/", browserName: "chromium" },
});
