// [Sprint 30 G8] The critical path end to end in a real browser (Chromium, a phone's width, Arabic): sign-up, a league
// and its team, the lineup, a match, its report; and an accessibility check (axe) of the main screens. It starts the
// API (SQLite, the game's data imported) and the web, or uses them when already running (`composer dev`).
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  timeout: 120_000,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: {
    baseURL: 'http://localhost:5173',
    // [Sprint 48 L1] The game is played sideways: a phone turned on its side (upright, the rotate card covers it).
    ...devices['Pixel 7 landscape'],
    locale: 'ar',
    trace: 'retain-on-failure',
    // In the cloud sessions the preinstalled browser; in CI the one `npx playwright install chromium` fetches.
    launchOptions: process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {},
  },
  webServer: [
    {
      command: 'php artisan serve --port=8000',
      cwd: '../backend',
      url: 'http://localhost:8000/api/v1/health',
      reuseExistingServer: true,
      timeout: 120_000,
    },
    { command: 'npx vite --port 5173', url: 'http://localhost:5173', reuseExistingServer: true, timeout: 120_000 },
  ],
})
