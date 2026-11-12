// [Sprint 58 T1] The moments that count (lib/analytics.ts track), with the measurement's code loaded only when it is
// first needed: it is not part of the first paint. Until its settings come from the server it does nothing, as before.
import type { track as Track } from './analytics'

export function track(...args: Parameters<typeof Track>) {
  void import('./analytics').then((m) => m.track(...args)).catch(() => {})
}
