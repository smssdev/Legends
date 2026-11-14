// [Sprint 37 R1] The director (Sprint 35 C1): which cutaways follow a scene, as a pure function of the minute's story,
// the device's tier and the time left, so its unit test (director.test.ts, Vitest) runs it without a screen.
import { SCENE_TIME } from './timing.ts'

export type Tier = 'low' | 'mid' | 'high'
export type Cut = { name: string; data: Record<string, any>; dur: number }
export type DirectorCtx = { tier: Tier; looks?: Record<string, string> | null; seed?: number }
type Side = 'home' | 'away'
/** [Sprint 57 W3] What the director reads of a minute's story (story.ts) and of the minute itself. */
export type StoryView = { scene: string | null; side: Side; goal: boolean; data: Record<string, any> }
export type TickView = { tick: number; moods?: Record<string, string> | null }

const MOODS = ['joy', 'cheer', 'angry', 'worried', 'sad', 'surprise']

/**
 * As on a broadcast. A goal: the scorers' fans, their coach's joy, then the other coach. A red card: the players
 * squaring up, then the sent-off player's coach. A big chance missed or saved: the shooter's coach. The moods are the
 * server's (tick.moods) when it has an expressive one.
 * s: the minute's story (story.ts). total: the minute's length in seconds. sceneT: the scene's own length.
 * Returns the cutaways that fit after the scene: none on 'low', one on 'mid', up to three on 'high'.
 */
export function director(s: StoryView | null | undefined, tick: TickView, total: number, sceneT: number, ctx: DirectorCtx): Cut[] {
  if (!s?.scene || ctx.tier === 'low') return []
  const other: Side = s.side === 'home' ? 'away' : 'home',
    moods: Record<string, string> = tick.moods ?? {},
    seed = ctx.seed || 1
  const look = (side: Side) => ctx.looks?.[side] ?? (side === 'home' ? 'C1' : 'C2')
  const felt = (side: Side, fallback: string) => (MOODS.includes(moods[side]) ? moods[side] : fallback)
  const coach = (side: Side, fallback: string): Cut => ({
    name: 'coachReact',
    data: { side, look: look(side), mood: felt(side, fallback) },
    dur: SCENE_TIME.coachReact[0],
  })
  const crowdCut = (): Cut => ({
    name: 'crowd',
    data: { side: s.side, v: seed * 7 + tick.tick, count: ctx.tier === 'high' ? 110 : 60, flares: ctx.tier === 'high' },
    dur: SCENE_TIME.crowd[0],
  })
  let list: Cut[] = []
  if (s.goal) list = [crowdCut(), coach(s.side, 'joy'), coach(other, 'angry')]
  // [Sprint 35 C2] A red card: tempers flare first (both sides squaring up), then the coach.
  // [Sprint 42 B2] A red card told as a fight or a spit already has its tempers: the coach only.
  else if (s.scene === 'card' && s.data.type === 'red' && ['brawl', 'spit'].includes(s.data.drama)) list = [coach(s.side, 'angry')]
  else if (s.scene === 'card')
    list =
      s.data.type === 'red'
        ? [{ name: 'brawl', data: { side: s.side, v: seed * 13 + tick.tick }, dur: SCENE_TIME.brawl[0] }, coach(s.side, 'angry')]
        : ctx.tier === 'high'
          ? [coach(s.side, 'angry')]
          : []
  // [Sprint 42 F6] A big chance blasted over the bar: the coach loses it (pulls his hair, kicks the bench, throws his jacket).
  else if (s.scene === 'miss' && s.data.how === 'over')
    list = [{ name: 'meltdown', data: { side: s.side, v: seed * 5 + tick.tick }, dur: SCENE_TIME.meltdown[0] }]
  else if (['miss', 'save', 'penalty', 'freekick'].includes(s.scene)) list = [coach(s.side, 'worried')]
  // [Sprint 36 F5] The end of a half: at half time the players walk off to the tunnel; at full time they shake
  // hands, then the coaches in their moods (the server's: joy for the winners, sorrow for the losers).
  else if (s.scene === 'whistle' && s.data.name === 'halftime')
    list = [{ name: 'tunnel', data: { side: 'home' }, dur: SCENE_TIME.tunnel[0] }]
  else if (s.scene === 'whistle' && s.data.name === 'fulltime')
    list = [{ name: 'handshake', data: { side: 'home' }, dur: SCENE_TIME.handshake[0] }, coach('home', 'idle'), coach('away', 'idle')]
  // [Sprint 35 C3] A goal ruled out by VAR: the coach who thought his side had scored, then the relieved one.
  else if (s.scene === 'var') list = [coach(s.side, 'angry'), coach(other, 'joy')]
  list = list.slice(0, ctx.tier === 'high' ? 3 : 1)
  // What fits: a goal keeps room for its replay (4.5 s), the rest for the commentator's line (1.2 s).
  const keep = s.goal ? 4.5 : 1.2
  const fit: Cut[] = []
  let used = 0
  for (const c of list) {
    if (sceneT + used + c.dur + keep <= total) {
      fit.push(c)
      used += c.dur
    }
  }
  return fit
}
