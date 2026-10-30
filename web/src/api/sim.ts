// Simulator API client (docs/api/openapi.yaml, docs/api/match-events.md).
import { api, asApiError, ensureCsrf } from './client'

export type Side = 'home' | 'away'

export interface Tactics {
  plan: 'counter' | 'long' | 'passing' | 'wings' | 'shots'
  tackling: number
  pressing: number
  style: number
  tempo: number
  att: 'back' | 'support' | 'only'
  mid: 'def' | 'stay' | 'push'
  def: 'stay' | 'fullbacks' | 'mid'
  trap: number
  marking: 'zone' | 'man'
}

export interface Club {
  id: number
  name: string
  code: string
  league?: string
  league_name?: string
  primary?: string
  secondary?: string
  color_primary?: string
  color_secondary?: string
  strength?: number
  strength_cp?: number
  logo?: string | null
}

export interface TeamPlayer {
  id: number
  name: string
  no: number
  pos: string
  line: string
  slot: number | null
  slot_line: string
  on: boolean
  out: '' | 'sub' | 'red' | 'injury'
  fit: number
  yc: number
  ovr: number
  rating: number
}

export interface TeamSnapshot {
  formation: string
  /** null for the other side in a live match: its tactics stay private. */
  tactics: Tactics | null
  subs_used: number
  subs_max: number
  stats: Record<string, number>
  players: TeamPlayer[]
}

export interface Frame {
  t: number
  b: [number, number, number]
  p: Record<string, [number, number]>
  h: number | null
}

export interface MatchEvent {
  type: string
  team: Side | null
  /** The server's Arabic commentary line for this event (Sprint 20 B1). */
  text?: string
  [key: string]: any
}

export interface Tick {
  /** [Sprint 26 B1] How each side's coach feels after the minute (App\Characters\Mood). */
  moods?: Record<Side, string>
  tick: number
  period: number
  minute: [number, number]
  score: Record<Side, number>
  events: MatchEvent[]
  danger: number
  /** Simulator only: the league runner does not send it. */
  rejected?: { action: any; reason: string }[]
  finished: boolean
  frames: Frame[]
  moment?: { kind: string; ms: number }
  /** [X42] Play stops after this minute: the coach's window. */
  window?: boolean
  /** Live matches: when this minute starts, on the server clock (ms). */
  at?: number
  /** League [E8.3]: the minute's start on the match's own clock (ms), and when the server made it (ms). */
  match_time?: number
  server_ts?: number
  teams?: Record<Side, TeamSnapshot>
  debug?: { initiative?: { rate: number; home_share: number } }
}

export interface LiveSync {
  started: boolean
  finished: boolean
  tick: number
  server_now: number
  next_at: number | null
  gap: boolean
  /** League (Sprint 20 W2): after a gap, the events of the minutes in between. */
  missed?: { tick: number; minute: number; events: MatchEvent[] }[]
  /** League [E8.5]: after a gap, how many minutes were missed and their goals and red cards. */
  summary?: LiveSummary | null
  /** League [E8.7]: a server under load asks the screens to poll this seldom (ms); null for their own pace. */
  poll_ms?: number | null
  ticks: Tick[]
  /** League: the assistant's notes to this coach (ENGINE 8.2). */
  readings?: Reading[]
  reactions: Reaction[]
  /** League: the side chat between the viewers [X24]. */
  chat?: ChatLine[]
  /** League [UP17]: the break under way: its end, the coaches ready, and each side's injured player waiting. */
  pause?: { until: number; ready: Side[]; window: boolean; injured: Partial<Record<Side, number>> } | null
}

export interface LiveSummary {
  from_tick: number
  to_tick: number
  minutes: number
  goals: { minute: number; team: Side; scorer: number | null }[]
  reds: { minute: number; team: Side; player: number | null }[]
}

export interface Reading { id: number; tick: number; minute: number; kind: string; text: string }

/** side: the coach's (null for a league member who watches); target and who: the league's broadcast [X24]. */
export interface Reaction { id: number; side: Side | null; key: string; at: number; target?: Side | null; who?: string }
export interface ChatLine { id: number; side: Side | null; who: string; body: string; user_id: number; at: number }

export interface MatchView {
  id: string
  seed: number
  competition: 'league' | 'cup'
  referee: number
  venue: 'home' | 'neutral'
  control: Record<Side, 'me' | 'cpu'>
  mode: 'solo' | 'live'
  /** Live matches: the side this device's seat manages, or null for a viewer. */
  you: Side | null
  seats?: Record<Side, string>
  started: boolean
  tick: number
  finished: boolean
  score: Record<Side, number>
  formations: string[]
  /** [X42] windows: the minutes a live match stops after for window_seconds, the coach's only moments to change. */
  timing: { tick_ms: number; extra_time_tick_ms: number; halftime_seconds: number; windows?: number[]; window_seconds?: number }
  clubs: Record<Side, Club>
  coaches?: Partial<Record<Side, string>>
  /** [Sprint 26] Each human coach's look on the touchline. */
  coach_looks?: Partial<Record<Side, 'C1' | 'C2' | 'C3'>>
  teams: Record<Side, TeamSnapshot>
}

export type Room = { id: string; host: { name: string; club: Club }; guest: { name: string; club: Club } | null; match_id: string | null; seat?: string }

// A live match's seat: the secret that lets this device manage its side. Kept per match in the browser.
export const seats = {
  get: (match: string) => { try { return localStorage.getItem(`legends.seat.${match}`) } catch { return null } },
  set: (match: string, seat: string) => { try { localStorage.setItem(`legends.seat.${match}`, seat) } catch {} },
}

async function call<T>(method: string, path: string, body?: unknown): Promise<T> {
  const match = path.match(/^\/matches\/([^/?]+)/)?.[1]
  const seat = match ? seats.get(match) : null
  // With a session cookie (a signed-in player) Sanctum checks CSRF on every write: send the token when there is one.
  const xsrf = document.cookie.split('; ').find((c) => c.startsWith('XSRF-TOKEN='))?.slice(11)
  const res = await fetch(`/api/v1/sim${path}`, {
    method,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...(seat ? { 'X-Seat': seat } : {}), ...(xsrf ? { 'X-XSRF-TOKEN': decodeURIComponent(xsrf) } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) {
    // On the free test server the disk is wiped on every restart, so an old match link can vanish.
    if (res.status === 404 && (path.startsWith('/matches/') || path.startsWith('/rooms/'))) throw new Error('هذه المباراة لم تعد موجودة: أُعيد تشغيل سيرفر التجربة فمُسحت المباريات. ابدأ مباراة جديدة من صفحة المحاكي.')
    const data = await res.json().catch(() => ({}))
    throw new Error(data.message || `خطأ ${res.status}`)
  }
  return res.json() as Promise<T>
}

export const sim = {
  leagues: () => call<{ name: string; clubs: number; top: number }[]>('GET', '/leagues'),
  clubs: (params: { q?: string; league?: string }) =>
    call<Club[]>('GET', '/clubs?' + new URLSearchParams(Object.entries(params).filter(([, v]) => v) as [string, string][])),
  squad: (id: number) => call<{ club: Club; formation: string; starters: number[]; bench: number[]; players: any[] }>('GET', `/clubs/${id}`),
  create: (body: Record<string, unknown>) => call<MatchView>('POST', '/matches', body),
  show: (id: string) => call<MatchView>('GET', `/matches/${id}`),
  ticks: (id: string, count = 1) => call<{ ticks: Tick[] }>('POST', `/matches/${id}/ticks`, { count }),
  start: (id: string) => call<LiveSync>('POST', `/matches/${id}/start`),
  live: (id: string, since: number) => call<LiveSync>('GET', `/matches/${id}/live?since=${since}`),
  order: (id: string, order: Record<string, unknown>) =>
    call<{ target_tick: number; duplicate: boolean }>('POST', `/matches/${id}/actions`, {
      ...order,
      idempotency_key: crypto.randomUUID(),
    }),
  room: (id: string) => call<Room>('GET', `/rooms/${id}`),
  openRoom: (name: string, clubId: number) => call<Room>('POST', '/rooms', { name, club_id: clubId }),
  joinRoom: (id: string, name: string, clubId: number) => call<Room>('POST', `/rooms/${id}/join`, { name, club_id: clubId }),
  react: (id: string, key: string) => call<Reaction>('POST', `/matches/${id}/reactions`, { key }),
  report: (id: string, side: Side = 'home') => call<any>('GET', `/matches/${id}/report?side=${side}`),
}

/**
 * A league match for the same viewer (Sprint 18 W1): the server keeps the clock, the screen only plays.
 * Same shapes as the simulator's live match, from /api/v1/matches (the league's members, by session).
 */
async function leagueCall<T>(path: string): Promise<T> {
  const res = await fetch(`/api/v1/matches${path}`, { headers: { Accept: 'application/json' }, credentials: 'same-origin' })
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.message || `خطأ ${res.status}`)
  }
  return res.json() as Promise<T>
}

export const leagueMatch = {
  show: async (id: string) => ({ seed: 0, referee: 1, venue: 'home', formations: [], ...(await leagueCall<Partial<MatchView>>(`/${id}`)), mode: 'live' }) as MatchView,
  live: (id: string, since: number) => leagueCall<LiveSync>(`/${id}/live?since=${since}`),
  /** The coach's order for his side (the server knows which), with the session's XSRF token. */
  order: async (id: string, order: Record<string, unknown>) => {
    await ensureCsrf()
    try {
      const { data } = await api.POST('/matches/{match}/actions', {
        params: { path: { match: Number(id) } },
        body: { ...order, idempotency_key: crypto.randomUUID() } as any,
      })
      return data!
    } catch (e) {
      throw asApiError(e)
    }
  },
  /** The broadcast [X24]: a reaction (a boo or a cheer has its target side), and a line in the side chat. */
  react: async (id: string, key: string, target?: Side) => {
    await ensureCsrf()
    try {
      const { data } = await api.POST('/matches/{match}/reactions', { params: { path: { match: Number(id) } }, body: { key: key as any, target } })
      return data as Reaction
    } catch (e) {
      throw asApiError(e)
    }
  },
  chat: async (id: string, body: string) => {
    await ensureCsrf()
    try {
      const { data } = await api.POST('/matches/{match}/chat', { params: { path: { match: Number(id) } }, body: { body } })
      return data as ChatLine
    } catch (e) {
      throw asApiError(e)
    }
  },
  /** [UP17] «أنا مستعد»: this coach is done with the break. */
  ready: async (id: string) => {
    await ensureCsrf()
    try {
      const { data } = await api.POST('/matches/{match}/ready', { params: { path: { match: Number(id) } } })
      return data!
    } catch (e) {
      throw asApiError(e)
    }
  },
  /** "Why you won or lost", for a coach of either side (Sprint 20 B2). */
  report: (id: string) => leagueCall<any>(`/${id}/report`),
  /** My live matches, for the switcher. */
  mine: async () => (await api.GET('/matches/live')).data!.matches,
}

export const clubColors = (c: Club) => ({
  primary: c.primary ?? c.color_primary ?? '#163360',
  secondary: c.secondary ?? c.color_secondary ?? '#F7F4EA',
})
