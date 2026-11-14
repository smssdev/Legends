// [Sprint 57 B2] The minute's story as the server tells it (tick.story, App\Simulator\MomentStory), written out for this
// screen: its words in the game's language, the names with the coach's names switch, and the scene's timing. Nothing is
// decided here: which scene, who is in it, the cards and the commentator's lines are all the server's.
import VOICE_LINES from '../../../../backend/resources/commentary/voice.json'
import { locale, t } from '../../lib/i18n'
import { cn } from '../../lib/names'
import { scoreText } from '../../lib/format'
import { SCENE_TIME } from './timing'

type Side = 'home' | 'away'
type Id = number | string | null | undefined
type SayVars = { p?: Id; q?: Id; A?: Side; n?: Txt }
/** A text from the server: a key to translate, a name, or parts (see MomentStory). */
/** A line of voice.json: its key, its slot, the language (a slot of lines) and the variant. */
type Ref = { m: string; s: string; lang?: 'en' | 'ar'; i: number }
export type Txt =
  string | { p: Id } | { c: Side } | { r: string } | { t: string; v: Txt[] } | { j: Txt[]; by: Txt } | { say: Ref; vars: SayVars }

// The commentator's variants by their place in voice.json (no m: the kick-off line).
export type ServerLine = {
  at: number
  en: number | null
  ar: number | null
  x: boolean
  vars: SayVars
  m?: string
  s?: 'pre' | 'key' | 'post'
}
export type ServerItem = { side: Side; icon: string; name: Txt; label: Txt; minute: string; goal?: boolean; center?: boolean }
export type ServerStory = {
  scene: string | null
  side: Side
  data: Record<string, any>
  head: Txt
  who: Txt
  sub: Txt
  pre: { head: Txt; who: Txt; sub: Txt } | null
  items: ServerItem[]
  lines: ServerLine[]
  bubble: Txt
  bubble_en: Txt
  goal: boolean
  minute: string
}

export type Line = {
  at: number
  en: string | null
  ar: string | null
  x: boolean
  vars: { p: Id; q: Id; A: Side; n: string }
  m?: string
  s?: string
}
export type Item = { side: Side; icon: string; name: string; label: string; minute: string; goal?: boolean; center?: boolean }
export type Story = {
  scene: string | null
  side: Side
  data: Record<string, any>
  head: string
  who: string
  sub: string
  pre: { head: string; who: string; sub: string } | null
  items: Item[]
  lines: Line[]
  bubble: string
  keyAt: number
  goal: boolean
  minute: string
}
export type StoryCtx = { players: Record<string, { name: string; no?: number | string }>; clubs: { home: string; away: string } }

const other = (s: Side): Side => (s === 'home' ? 'away' : 'home')
const LINES = VOICE_LINES as Record<string, Record<string, any>>
/** The words of a line in the table. */
const said = (r: Ref): string => {
  const slot = LINES[r.m]?.[r.s]
  return (r.lang ? slot?.[r.lang]?.[r.i] : slot?.[r.i]) ?? ''
}

/** One text from the server, written for this screen. */
export function txt(x: Txt | null | undefined, ctx: StoryCtx): string {
  if (x == null) return ''
  if (typeof x === 'string') return x ? t(x) : ''
  const name = (id: Id) => (id == null ? '' : (ctx.players[String(id)]?.name ?? ''))
  const club = (s: Side | undefined) => cn(ctx.clubs[s ?? 'home'])
  if ('p' in x) return name(x.p)
  if ('c' in x) return club(x.c)
  if ('r' in x) return x.r
  if ('t' in x) return t(x.t, Object.fromEntries(x.v.map((v, i) => [`v${i}`, txt(v, ctx)])))
  if ('j' in x) return x.j.map((v) => txt(v, ctx)).join(txt(x.by, ctx))
  const v = x.vars,
    A = v.A ?? 'home'
  return said(x.say)
    .replace(/\{p\}/g, name(v.p))
    .replace(/\{q\}/g, name(v.q))
    .replace(/\{A\}/g, club(A))
    .replace(/\{B\}/g, club(other(A)))
    .replace(/\{n\}/g, txt(v.n ?? '', ctx))
}

/** A minute with nothing to tell (one sent without its story). */
export const untold = (): Story => ({
  scene: null,
  side: 'home',
  data: {},
  head: '',
  who: '',
  sub: '',
  pre: null,
  items: [],
  lines: [],
  bubble: '',
  keyAt: 0,
  goal: false,
  minute: '',
})

/** The minute's story for this screen (null: an old minute without one, nothing to play). */
export function told(s: ServerStory | null | undefined, ctx: StoryCtx): Story | null {
  if (!s) return null
  const w = (x: Txt) => txt(x, ctx)
  const time = s.scene ? SCENE_TIME[s.scene] : null
  const k = time ? time[1] / time[0] : 0
  // The commentator's key line is said the instant the scene reaches its key moment, the reaction after it.
  const lines: Line[] = s.lines.map((l) => ({
    ...l,
    en: l.en == null ? null : said({ m: l.m ?? 'kickoff', s: l.s ?? 'key', lang: 'en', i: l.en }) || null,
    ar: l.ar == null ? null : said({ m: l.m ?? 'kickoff', s: l.s ?? 'key', lang: 'ar', i: l.ar }) || null,
    at: time && l.s === 'key' ? k : time && l.s === 'post' ? Math.min(0.92, k + 0.16) : l.at,
    vars: { p: l.vars.p ?? null, q: l.vars.q ?? null, A: l.vars.A ?? 'home', n: w(l.vars.n ?? '') },
  }))
  // [UP2] In English the bubble says the commentator's English line (the server's choice too).
  const bubble = w(locale.value === 'en' ? s.bubble_en : s.bubble)
  const data = { ...s.data }
  if (data.tactic != null) data.tactic = w(data.tactic)
  if (data.big != null) data.big = w(data.big)
  if (Array.isArray(data.stats)) data.stats = data.stats.map(([l, h, a]: [Txt, number, number]) => [w(l), h, a])
  if (Array.isArray(data.score)) data.score = scoreText(data.score[0], data.score[1])
  return {
    scene: s.scene,
    side: s.side,
    data,
    head: w(s.head),
    who: w(s.who),
    sub: w(s.sub),
    pre: s.pre ? { head: w(s.pre.head), who: w(s.pre.who), sub: w(s.pre.sub) } : null,
    items: s.items.map((i) => ({ ...i, name: w(i.name), label: w(i.label) })),
    lines,
    bubble,
    keyAt: k,
    goal: s.goal,
    minute: s.minute,
  }
}
