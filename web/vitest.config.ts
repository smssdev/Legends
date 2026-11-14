// [Sprint 57 W1] Unit tests for the match's composables (src/**/*.test.ts), with fake timers and a small DOM.
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  define: { __GLM_VERSION__: JSON.stringify('web-test') },
  test: { environment: 'happy-dom', include: ['src/**/*.test.ts'] },
})
