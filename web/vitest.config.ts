// [Sprint 57 W1] Unit tests for the match's composables (src/**/*.test.ts), with fake timers and a small DOM.
// [Sprint 66 T4] And the pure logic of lib/ and match/, at 80% of its lines at least (npm test fails under it): what
// draws (the canvas, the clips), plays sound or talks to a browser service (ads, analytics, the service worker) is
// checked in the browser (e2e/), not here.
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

const LOGIC = [
  'src/lib/{action,clock,currentLeague,dates,errors,format,i18n,names,bots,rating,soundLevels,statuses,storage,theme,uuid}.ts',
  'src/match/{commentary,frames,perf,viewing}.ts',
  'src/match/use{CoachOrders,IntroMatch,LiveSync,MatchAnnouncer,MatchAudio,MatchClock,MatchPlayer,MatchSocial,Replay,WakeLock}.ts',
  'src/match/feed/{director,clock,cues}.ts',
]

export default defineConfig({
  plugins: [vue()],
  define: { __GLM_VERSION__: JSON.stringify('web-test') },
  test: {
    environment: 'happy-dom',
    include: ['src/**/*.test.ts'],
    coverage: { provider: 'v8', include: LOGIC, reporter: ['text-summary', 'text'], thresholds: { lines: 80 } },
  },
})
