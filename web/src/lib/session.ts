// [Sprint 58 W1] The visit's start in one request (GET /bootstrap, App\Http\Controllers\Api\BootstrapController): who is
// signed in, the wallet, the coach and his slots, the unread count, and the site's settings (support links, AdSense,
// measurement). The splash screen, the route guard and the shell's stores all wait on the same request, so opening the
// site costs one call instead of five to nine (W-P06). Each store takes its part once (for the account it was made
// for); after that it reloads from its own route, as before (after spending coins, claiming a club, reading mail).
import { api } from '../api/client'
import type { paths } from '../api/schema'

export type Boot = paths['/bootstrap']['get']['responses']['200']['content']['application/json']
type Health = paths['/health']['get']['responses']['200']['content']['application/json']
/** The site's settings, as GET /health gives them. */
export type SiteConfig = Pick<Health, 'version' | 'time' | 'clock_offset' | 'broadcast' | 'support' | 'adsense' | 'analytics'>

let first: Promise<Boot> | null = null
let got: Boot | null = null
const taken = new Set<string>()

/** The visit's start (one request, shared); a failure rejects (ApiError: signed out, or the server not reached). */
export function boot(): Promise<Boot> {
  return (first ??= api.GET('/bootstrap').then(({ data }) => (got = data!)).catch((e) => { first = null; throw e }))
}

/** Asked again (after a sign-in, a sign-out, or «try again»). */
export function rebootSession() {
  first = null
  got = null
  taken.clear()
}

/** The site's settings, or null when the server was not reached. */
export const siteConfig = (): Promise<SiteConfig | null> => boot().then((b) => b.config as SiteConfig).catch(() => null)

/** A store's part of the start, once, for the account it was made for; undefined when it should ask its own route. */
export function takeBoot<K extends 'wallet' | 'home' | 'unread'>(key: K, userId: number | null | undefined): NonNullable<Boot[K]> | undefined {
  if (!got || !userId || got.user?.id !== userId || taken.has(key) || got[key] == null) return undefined
  taken.add(key)
  return got[key] as NonNullable<Boot[K]>
}
