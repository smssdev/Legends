// [X57] Google AdSense on the web (the owner's request 2026-10-29: real ads that earn). Everything comes from the
// server (/health → adsense), null until the owner's account is set there (legends-set ADSENSE_CLIENT): then Google's
// script loads once (on our server it is already in the page's head, deploy/docker/router.php), the display units
// fill (AdSlot.vue), and, with rewarded on, Google's rewarded video is tried before our own ad (AdReward.vue).
import { siteConfig } from './session'

export type AdSenseConfig = { client: string; slot: string | null; rewarded: boolean; test: boolean }
type AdBreakDone = { breakStatus: string }
type Placement = Record<string, unknown>
type AdsWindow = Window & { adsbygoogle?: Placement[]; adBreak?: (o: Placement) => void; adConfig?: (o: Placement) => void }

let loading: Promise<AdSenseConfig | null> | null = null

/** The account's settings, once per visit; null when Google's ads are off (or the server is not reached). */
export function adsense(): Promise<AdSenseConfig | null> {
  return (loading ??= siteConfig().then((data) => {
    const cfg = (data?.adsense ?? null) as AdSenseConfig | null
    if (cfg) inject(cfg)
    return cfg
  }).catch(() => null))
}

function inject(cfg: AdSenseConfig) {
  const w = window as AdsWindow
  w.adsbygoogle = w.adsbygoogle || []
  // The Ad Placement API (H5 Games Ads): adBreak and adConfig both queue into adsbygoogle.
  w.adBreak = w.adConfig = (o: Placement) => { w.adsbygoogle!.push(o) }
  if (document.querySelector('script[src*="pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"]')) return
  const s = document.createElement('script')
  s.async = true
  s.crossOrigin = 'anonymous'
  s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(cfg.client)}`
  s.dataset.adFrequencyHint = '30s'
  if (cfg.test) s.dataset.adbreakTest = 'on'
  document.head.appendChild(s)
}

/** Fills one display unit (<ins class="adsbygoogle">) placed on the page. */
export function fill() {
  try {
    const w = window as AdsWindow
    ;(w.adsbygoogle = w.adsbygoogle || []).push({})
  } catch {
    // an ad blocker: the space stays empty
  }
}

/**
 * Google's rewarded video. ready() is called only when Google has a video: it gets the server's token (the watch is
 * timed there) before the video plays. Resolves 'viewed' when it was watched to its end, 'dismissed' when closed
 * early, and 'none' when Google had no video (or is blocked), so the caller falls back to our own ad.
 */
export function rewarded(ready: () => Promise<boolean>): Promise<'viewed' | 'dismissed' | 'none'> {
  const w = window as AdsWindow
  return new Promise((resolve) => {
    let shown = false
    let settled = false
    const done = (r: 'viewed' | 'dismissed' | 'none') => { if (!settled) { settled = true; resolve(r) } }
    // A blocked script never answers: our own ad after a few seconds.
    const guard = setTimeout(() => { if (!shown) done('none') }, 5000)
    if (!w.adBreak) return done('none')
    w.adBreak({
      type: 'reward',
      name: 'cut-time',
      beforeReward: async (showAdFn: () => void) => {
        shown = true
        clearTimeout(guard)
        if (await ready()) showAdFn()
        else done('none')
      },
      adViewed: () => done('viewed'),
      adDismissed: () => done('dismissed'),
      adBreakDone: (info: AdBreakDone) => { clearTimeout(guard); done(info.breakStatus === 'viewed' ? 'viewed' : shown ? 'dismissed' : 'none') },
    })
  })
}
