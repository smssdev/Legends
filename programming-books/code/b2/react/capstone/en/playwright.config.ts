import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  webServer: { command: "node ../../../serve.mjs 4175", url: "http://localhost:4175/vendor/react.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4175/react/capstone/en/", browserName: "chromium" },
});
