import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom", // a pretend browser, so components can render
    setupFiles: ["./vitest.setup.ts"],
    include: ["**/*.test.{ts,tsx}"],
  },
});
