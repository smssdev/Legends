// [X81] The site's measurement (the owner's request 2026-11-02): Google Analytics 4 and the Meta Pixel, both from the
// server (/health → analytics, App\Analytics\Tracking), so an id changes on the server without a deploy.
// - Google's Consent Mode v2: in Europe (EEA, the UK, Switzerland) nothing is stored until the visitor agrees in
//   Google's consent message (AdSense → Privacy & messaging, the CMP updates the consent itself); elsewhere it is on.
// - The Meta Pixel has no consent mode: it loads only where the consent message does not apply (gdprApplies false)
//   or where the visitor agreed to storage (TCF purpose 1).
// - The game is one page: each screen is its own page_view (router.afterEach), never the admin panel's, and no name,
//   username or email is ever sent: the paths carry ids only.
import type { Router } from 'vue-router'
import { api } from '../api/client'

type Config = { ga: string | null; pixel: string | null }
type Fn = (...args: unknown[]) => void
type Tcf = (cmd: string, v: number, cb: (data: { gdprApplies?: boolean; eventStatus?: string; purpose?: { consents?: Record<string, boolean> } }, ok: boolean) => void) => void
type W = Window & { dataLayer?: unknown[]; gtag?: Fn; fbq?: Fn & { queue?: unknown[]; callMethod?: Fn; loaded?: boolean; version?: string; push?: Fn }; _fbq?: unknown; __tcfapi?: Tcf }

const EUROPE = ['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
  'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'IS', 'LI', 'NO', 'GB', 'CH']

let cfg: Config | null = null
let pixelOn = false
const w = () => window as W
const skipped = (path: string) => path.startsWith('/admin')

function script(src: string) {
  if (document.querySelector(`script[src="${src}"]`)) return
  const s = document.createElement('script')
  s.async = true
  s.src = src
  document.head.appendChild(s)
}

function startGoogle(id: string) {
  const win = w()
  win.dataLayer = win.dataLayer || []
  // gtag must push the arguments object itself, as Google's own snippet does.
  win.gtag = function gtag() { win.dataLayer!.push(arguments) } as Fn
  win.gtag('consent', 'default', { ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied', analytics_storage: 'denied', region: EUROPE, wait_for_update: 500 })
  win.gtag('consent', 'default', { ad_storage: 'granted', ad_user_data: 'granted', ad_personalization: 'granted', analytics_storage: 'granted' })
  win.gtag('js', new Date())
  // The pages are sent by hand below, one per screen.
  win.gtag('config', id, { send_page_view: false })
  script(`https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(id)}`)
}

function startPixel(id: string) {
  const win = w()
  if (win.fbq) return
  // Meta's own loader, as a function: queue the calls until fbevents.js arrives.
  const fbq = function (...args: unknown[]) { fbq.callMethod ? fbq.callMethod(...args) : fbq.queue!.push(args) } as NonNullable<W['fbq']>
  fbq.push = fbq; fbq.loaded = true; fbq.version = '2.0'; fbq.queue = []
  win.fbq = fbq
  win._fbq = fbq
  script('https://connect.facebook.net/en_US/fbevents.js')
  fbq('init', id)
  pixelOn = true
  fbq('track', 'PageView')
}

/** The Pixel only with consent where Google's consent message applies (TCF purpose 1, storage on the device). */
function whenAllowed(go: () => void) {
  let done = false
  const decide = (allowed: boolean) => { if (!done) { done = true; if (allowed) go() } }
  const ask = () => w().__tcfapi?.('addEventListener', 2, (d, ok) => {
    if (!ok) return
    if (d.gdprApplies === false) return decide(true)
    if (d.eventStatus === 'tcloaded' || d.eventStatus === 'useractioncomplete') decide(!!d.purpose?.consents?.['1'])
  })
  if (w().__tcfapi) return ask()
  // No consent tool on the page after a few seconds: outside the regions it serves.
  let tries = 0
  const t = window.setInterval(() => {
    if (w().__tcfapi) { window.clearInterval(t); ask() } else if (++tries > 8) { window.clearInterval(t); decide(true) }
  }, 500)
}

function page(path: string) {
  if (!cfg || skipped(path)) return
  if (cfg.ga) w().gtag?.('event', 'page_view', { page_path: path, page_location: location.origin + path, page_title: document.title })
  if (pixelOn) w().fbq?.('track', 'PageView')
}

/** Once at the start: the server's ids, then Google and Meta, and a page for every screen after. */
export function useAnalytics(router: Router) {
  if (typeof window === 'undefined' || navigator.webdriver) return
  api.GET('/health').then(({ data }) => {
    cfg = (data?.analytics ?? null) as Config | null
    if (!cfg) return
    if (cfg.ga) startGoogle(cfg.ga)
    if (cfg.pixel) whenAllowed(() => startPixel(cfg!.pixel!))
    page(router.currentRoute.value.path)
    // The title is set by the page's own SEO on the same navigation, so it is read a moment later.
    router.afterEach((to, from) => { if (to.path !== from.path) window.setTimeout(() => page(to.path), 50) })
  }).catch(() => {})
}

/** The moments that count: a sign-up, a sign-in, a league made or joined (no name or email, only what happened). */
export function track(event: 'sign_up' | 'login' | 'create_league' | 'join_league', params: Record<string, string | number> = {}) {
  if (!cfg) return
  if (cfg.ga) w().gtag?.('event', event, { method: 'username', ...params })
  if (pixelOn) {
    const meta = { sign_up: 'CompleteRegistration', login: null, create_league: 'StartTrial', join_league: 'SubmitApplication' }[event]
    if (meta) w().fbq?.('track', meta)
  }
}
