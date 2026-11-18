// [Sprint 09 G1] The cases of the director's golden vectors (docs/api/director-golden.json), from the cartoon's pure
// modules: every minute of the sample match with the server's story, and a story for each scene the sample lacks, at
// every tier and both lengths of a minute (the live pace and a moment's). scripts/director-golden.mjs writes them, the
// web test checks the file is still what the cartoon gives, and Unity's DirectorTests checks its port gives the same.
import { clockAt } from './clock.ts'
import type { DirectorCtx, StoryView } from './director.ts'
import { planMinute } from './plan.ts'

type Side = 'home' | 'away'
type SampleTick = {
  tick: number
  minute: [number, number]
  moods?: Record<string, string> | null
  moment?: { ms?: number } | null
  story?: { scene: string | null; side: Side; goal: boolean; data: Record<string, unknown> } | null
}
export type GoldenCase = {
  story: StoryView
  tick: { tick: number; minute: [number, number]; moods: Record<string, string> | null; ms: number }
  ctx: { tier: DirectorCtx['tier']; seed: number; looks: Record<string, string> | null; smooth: boolean }
  plan: ReturnType<typeof planMinute>
  clock: { u: number; text: string; frozen: boolean; half: string; progress: number }[]
}

const TIERS: DirectorCtx['tier'][] = ['low', 'mid', 'high']
const US = [0, 0.04, 0.1, 0.3, 0.5, 0.7, 0.9, 1]

/** The scenes a sample match may not have, each as the server tells it (MomentStory), so every branch is pinned. */
const MADE: { scene: string; goal?: boolean; data?: Record<string, unknown> }[] = [
  { scene: 'goal', goal: true },
  { scene: 'penalty', goal: true },
  { scene: 'penalty' },
  { scene: 'freekick', goal: true },
  { scene: 'freekick' },
  { scene: 'save' },
  { scene: 'miss', data: { how: 'wide' } },
  { scene: 'miss', data: { how: 'over' } },
  { scene: 'blocked' },
  { scene: 'card', data: { type: 'yellow' } },
  { scene: 'card', data: { type: 'red' } },
  { scene: 'card', data: { type: 'red', drama: 'brawl' } },
  { scene: 'card', data: { type: 'red', drama: 'spit' } },
  { scene: 'foul' },
  { scene: 'offside' },
  { scene: 'corner' },
  { scene: 'injury' },
  { scene: 'sub' },
  { scene: 'coach' },
  { scene: 'whistle', data: { name: 'halftime' } },
  { scene: 'whistle', data: { name: 'fulltime' } },
  { scene: 'whistle', data: { name: 'kickoff' } },
  { scene: 'var' },
  { scene: 'clearance' },
  { scene: 'trap' },
  { scene: 'rant' },
  { scene: 'slip' },
  { scene: 'board' },
]

function one(story: StoryView, tick: GoldenCase['tick'], ctx: GoldenCase['ctx']): GoldenCase {
  const plan = planMinute(story, { tick: tick.tick, moods: tick.moods, moment: { ms: tick.ms } }, ctx)
  const timing = story.scene ? { total: plan.total, sceneT: plan.sceneT, cutT: plan.cutT, scene: true } : null
  const clock = US.map((u) => ({ u, ...clockAt(tick.minute, tick.tick, u, timing) }))
  return { story, tick, ctx, plan, clock }
}

export function cases(sample: { match: { seed: number }; ticks: SampleTick[] }): GoldenCase[] {
  const seed = sample.match.seed
  const out: GoldenCase[] = []
  // every minute of the sample, at every tier (and the smooth mode, which drops the replay)
  for (const t of sample.ticks) {
    const s = t.story
    const story: StoryView = s
      ? { scene: s.scene, side: s.side, goal: !!s.goal, data: { ...s.data } }
      : { scene: null, side: 'home', goal: false, data: {} }
    const tick = { tick: t.tick, minute: t.minute, moods: t.moods ?? null, ms: t.moment?.ms ?? 3000 }
    for (const tier of TIERS) out.push(one(story, tick, { tier, seed, looks: { home: 'C3', away: 'C1' }, smooth: false }))
    if (story.goal) out.push(one(story, tick, { tier: 'high', seed, looks: null, smooth: true }))
  }
  // every scene, for either side, at the live pace and as a long moment, with moods and without
  MADE.forEach((m, i) => {
    for (const side of ['home', 'away'] as Side[])
      for (const ms of [3300, 9000, 20000])
        for (const tier of TIERS) {
          const story: StoryView = { scene: m.scene, side, goal: !!m.goal, data: { ...(m.data ?? {}) } }
          const moods = i % 2 ? { home: 'joy', away: 'sad' } : { home: 'idle', away: 'worried' }
          const tick = { tick: 10 + i, minute: [30 + i, 0] as [number, number], moods, ms }
          out.push(one(story, tick, { tier, seed, looks: i % 3 ? null : { home: 'C2' }, smooth: false }))
        }
  })
  return out
}
