import { defineConfig } from "vitest/config";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()], // compiles .vue files, as in the app
  test: {
    environment: "jsdom", // a pretend browser, so components can render
    setupFiles: ["./vitest.setup.ts"],
    include: ["**/*.test.ts"],
  },
});
