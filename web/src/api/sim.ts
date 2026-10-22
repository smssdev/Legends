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
  /** Live matches: when this minute starts, on the server clock (ms). */
  at?: number
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
  ticks: Tick[]
  /** League: the assistant's notes to this coach (ENGINE 8.2). */
  readings?: Reading[]
  reactions: Reaction[]
}

export interface Reading { id: number; tick: number; minute: number; kind: string; text: string }

export interface Reaction { id: number; side: Side; key: string; at: number }

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
  timing: { tick_ms: number; extra_time_tick_ms: number; halftime_seconds: number }
  clubs: Record<Side, Club>
  coaches?: Partial<Record<Side, string>>
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
  const res = await fetch(`/api/v1/sim${path}`, {
    method,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...(seat ? { 'X-Seat': seat } : {}) },
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
  /** "Why you won or lost", for a coach of either side (Sprint 20 B2). */
  report: (id: string) => leagueCall<any>(`/${id}/report`),
  /** My live matches, for the switcher. */
  mine: async () => (await api.GET('/matches/live')).data!.matches,
}

export const clubColors = (c: Club) => ({
  primary: c.primary ?? c.color_primary ?? '#163360',
  secondary: c.secondary ?? c.color_secondary ?? '#F7F4EA',
})
