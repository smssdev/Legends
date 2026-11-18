// [Sprint 11 W3, W4] The match screen and the Unity scene (README 7.2, 7.8): what the page sends the scene, where its
// web build is, which device may run it, and the page's pitch that plays every minute on both the cartoon and Unity.
// The cartoon keeps playing under the scene (its clock, its cues, its commentary and its sound), so the page's timing
// is the cartoon's, and a scene that fails or a device that cannot keep up only uncovers it: no minute is lost.
// Unity draws only what the server sent (Bridge.cs reads the same shapes as the /scene route and the live minutes).
import type { MatchView, Side, TeamSnapshot, Tick } from '../../api/sim'
import type { Pitch } from '../useMatchPlayer'
import type { Tier } from '../perf'

/**
 * What Unity's Bridge.OnSetup reads (MatchSetup.From): the clubs, both squads, the minute's length, the seed, the coaches'
 * looks, and [Sprint 08 U4] the stadium's light, the cartoon's (Sprint 43 C7: day by the site's day look, else night).
 */
export function unitySetup(
  view: Pick<MatchView, 'clubs' | 'kits' | 'timing' | 'seed' | 'coach_looks'>,
  teams: Partial<Record<Side, TeamSnapshot>>,
  light: 'day' | 'night' = 'night',
) {
  const club = (side: Side) => {
    const c = view.clubs[side]
    return {
      id: c.id,
      name: c.name,
      code: c.code,
      primary: c.primary ?? c.color_primary ?? '#FFFFFF',
      secondary: c.secondary ?? c.color_secondary ?? '#000000',
      pattern: c.pattern ?? null,
    }
  }
  const players = (side: Side) =>
    (teams[side]?.players ?? []).map((p) => ({ id: p.id, name: p.name, no: p.no, pos: p.pos, line: p.line, starter: p.on }))
  return {
    clubs: { home: club('home'), away: club('away') },
    kits: view.kits,
    players: { home: players('home'), away: players('away') },
    tick_ms: view.timing.tick_ms,
    seed: view.seed,
    coach_looks: { home: view.coach_looks?.home ?? null, away: view.coach_looks?.away ?? null },
    light,
  }
}

/** The web build's four files under /unity/<build>/Build/ (unity/build.ps1 webgl: gzip with the decompression fallback). */
export function unityFiles(build: string, base = '/unity') {
  const dir = `${base}/${encodeURIComponent(build)}/Build/WebGL`
  return {
    loaderUrl: `${dir}.loader.js`,
    dataUrl: `${dir}.data.unityweb`,
    frameworkUrl: `${dir}.framework.js.unityweb`,
    codeUrl: `${dir}.wasm.unityweb`,
    streamingAssetsUrl: `${base}/${encodeURIComponent(build)}/StreamingAssets`,
    companyName: 'Legends',
    productName: 'Legends Match',
    productVersion: build,
  }
}

type Nav = { deviceMemory?: number; hardwareConcurrency?: number; connection?: { saveData?: boolean } }

/**
 * [W4] Whether this device should load the scene at all: WebGL 2, at least 4 GB and 4 cores when it says, and no data
 * saving (the build is about 50 MB). A no here plays the cartoon, as a failed load does.
 */
export function canRunUnity(nav: Nav, webgl2: boolean): boolean {
  if (!webgl2) return false
  if (nav.connection?.saveData) return false
  if (nav.deviceMemory !== undefined && nav.deviceMemory < 4) return false
  if (nav.hardwareConcurrency !== undefined && nav.hardwareConcurrency < 4) return false
  return true
}

/** Unity's quality level for the cartoon's tier (Bridge.OnQuality: README 7.6). */
export const unityQuality = (tier: Tier) => (tier === 'low' ? 'low' : tier === 'mid' ? 'medium' : 'high')

/**
 * A minute for Bridge.OnMinute: the tick as the server sent it, and how far into it the page already is (`into`, s),
 * so a minute that started before the scene got it (a late join, a hidden tab) is drawn from the same second.
 */
export function unityMinute(t: Tick, startAt: number | null | undefined, now: number): string {
  const into = startAt != null ? Math.max(0, (now - startAt) / 1000) : 0
  return JSON.stringify(into > 0.05 ? { ...t, into: Math.round(into * 1000) / 1000 } : t)
}

/** What UnityScene exposes: it plays and skips with the cartoon. */
export type UnityPitch = { play: (t: Tick, startAt?: number | null) => void; skip: () => void }

/** The page's pitch: every minute to the cartoon (which keeps the timing) and to the Unity scene when it is on. */
export function withUnity(feed: Pitch, unity: () => UnityPitch | null | undefined): Pitch {
  return {
    play: (t, startAt) => {
      feed.play(t, startAt)
      unity()?.play(t, startAt ?? null)
    },
    skip: () => {
      feed.skip()
      unity()?.skip()
    },
    prepare: (t) => feed.prepare(t),
    react: (side, emoji, text, who) => feed.react(side, emoji, text, who),
  }
}
