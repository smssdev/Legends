// Simulator API client (docs/api/openapi.yaml, docs/api/match-events.md).

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
  tactics: Tactics
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
  [key: string]: any
}

export interface Tick {
  tick: number
  period: number
  minute: [number, number]
  score: Record<Side, number>
  events: MatchEvent[]
  danger: number
  rejected: { action: any; reason: string }[]
  finished: boolean
  frames: Frame[]
  teams?: Record<Side, TeamSnapshot>
  debug?: { initiative?: { rate: number; home_share: number } }
}

export interface MatchView {
  id: string
  seed: number
  competition: 'league' | 'cup'
  referee: number
  venue: 'home' | 'neutral'
  control: Record<Side, 'me' | 'cpu'>
  tick: number
  finished: boolean
  score: Record<Side, number>
  formations: string[]
  timing: { tick_ms: number; extra_time_tick_ms: number; halftime_seconds: number }
  clubs: Record<Side, Club>
  teams: Record<Side, TeamSnapshot>
}

async function call<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`/api/v1/sim${path}`, {
    method,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) {
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
  order: (id: string, order: Record<string, unknown>) =>
    call<{ target_tick: number; duplicate: boolean }>('POST', `/matches/${id}/actions`, {
      ...order,
      idempotency_key: crypto.randomUUID(),
    }),
  report: (id: string, side: Side = 'home') => call<any>('GET', `/matches/${id}/report?side=${side}`),
}

export const clubColors = (c: Club) => ({
  primary: c.primary ?? c.color_primary ?? '#163360',
  secondary: c.secondary ?? c.color_secondary ?? '#F7F4EA',
})
