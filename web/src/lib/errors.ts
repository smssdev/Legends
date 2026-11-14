// [Sprint 66 W1] The errors this page meets on a player's device, sent to our own server (POST /client-errors): Vue's
// errors, the uncaught ones and the promises nobody caught. The same error goes once a minute at most, and twenty a
// visit at most, so a loop never floods the server. Nothing about the player is sent: the platform, the build's
// version, the screen's path (the server drops its ids), the message and the first lines of the trace. The privacy
// policy says so («بيانات الأعطال»).
const ONCE_PER_MS = 60_000
const MAX_PER_VISIT = 20

export type ClientError = { platform: 'web'; version: string; path: string; message: string; stack: string }

const sent = new Map<string, number>()
let count = 0

/** Whether this error may go now: not sent in the last minute, and the visit's allowance not spent. */
export function shouldSend(key: string, now: number, seen: Map<string, number> = sent): boolean {
  if (count >= MAX_PER_VISIT) return false
  const last = seen.get(key)
  if (last !== undefined && now - last < ONCE_PER_MS) return false
  seen.set(key, now)
  return true
}

/** The report for an error of any kind (an Error, a string, a rejection's reason). */
export function describe(err: unknown, path: string): ClientError {
  const e = err instanceof Error ? err : null
  const message = (e ? `${e.name}: ${e.message}` : typeof err === 'string' ? err : safeJson(err)).slice(0, 1000)
  const stack = (e?.stack ?? '').split('\n').slice(0, 8).join('\n').slice(0, 2000)
  return { platform: 'web', version: __GLM_VERSION__, path: path.split(/[?#]/)[0]!.slice(0, 500), message: message || 'Unknown error', stack }
}

function safeJson(v: unknown): string {
  try { return JSON.stringify(v) ?? String(v) } catch { return String(v) }
}

/** Sends one error (never throws, never waits: a report must not break what is left of the page). */
export function report(err: unknown, path: string = typeof location === 'undefined' ? '/' : location.pathname) {
  const body = describe(err, path)
  if (!shouldSend(`${body.message}\n${body.stack.split('\n')[1] ?? ''}`, Date.now())) return
  count++
  try {
    void fetch('/api/v1/client-errors', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
      keepalive: true,
      credentials: 'omit',   // no cookie: the report carries nobody
    }).catch(() => {})
  } catch {}
}

/** Errors that say nothing about our code: a browser extension, a cancelled request, the network gone. */
export function ignored(err: unknown): boolean {
  const text = err instanceof Error ? `${err.name} ${err.message}` : String(err)
  return /ResizeObserver loop|AbortError|NetworkError|Failed to fetch|Load failed|chrome-extension:|moz-extension:/i.test(text)
}

/** Listens for the page's errors (once, from main.ts); Vue's own errors come through `vueHandler`. */
export function watchErrors(target: Window = window) {
  target.addEventListener('error', (e) => { if (!ignored(e.error ?? e.message)) report(e.error ?? e.message) })
  target.addEventListener('unhandledrejection', (e) => { if (!ignored(e.reason)) report(e.reason) })
}

export function vueHandler(err: unknown) {
  // As without a handler: the error still shows in the console for whoever is debugging.
  console.error(err)
  if (!ignored(err)) report(err)
}

/** For the tests: the visit's allowance back to empty. */
export function resetErrors() {
  sent.clear()
  count = 0
}
