// [Sprint 57 W1] The screen stays on while a live match plays (Screen Wake Lock); the phone takes it back when the page
// is hidden, so it is asked again on every return. allowed(): whether the match wants it now.
type Lock = { released: boolean; release: () => Promise<void> }

export function useWakeLock(allowed: () => boolean) {
  let lock: Lock | null = null

  async function keep() {
    if (!allowed() || document.visibilityState !== 'visible' || !('wakeLock' in navigator)) return
    if (lock && !lock.released) return
    try {
      lock = await (navigator as unknown as { wakeLock: { request: (t: 'screen') => Promise<Lock> } }).wakeLock.request('screen')
    } catch {
      /* refused (battery saver): the match still plays */
    }
  }

  function release() {
    lock?.release().catch(() => {})
    lock = null
  }

  return { keep, release }
}
