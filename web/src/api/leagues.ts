// Private leagues (Sprint 13): the types from docs/api/openapi.yaml, and small helpers the screens share.
import type { components } from './schema'

export type League = components['schemas']['League']
export type LeagueClub = components['schemas']['LeagueClub']
export type LeaguePlayer = components['schemas']['LeaguePlayer']
export type JoinRequest = components['schemas']['JoinRequest']

/** League rounds for N teams: home and away, and with an odd count every team rests twice [PLAN 2.4]. */
export const roundsFor = (teams: number) => (teams % 2 === 0 ? 2 * (teams - 1) : 2 * teams)
/** The first round of the last quarter, rounded up as the server does (LeagueFactory::lockFromRound). */
export const lockFromRound = (rounds: number) => rounds - Math.ceil(rounds / 4) + 1

/** A date as the design shows it, in the device's own time zone with Latin digits: «السبت 17 أكتوبر · 21:00». */
export function when(iso: string): string {
  const d = new Date(iso)
  const day = new Intl.DateTimeFormat('ar-EG-u-nu-latn', { weekday: 'long', day: 'numeric', month: 'long' }).format(d)
  const time = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' }).format(d)
  return `${day} · ${time}`
}

export const END_MODES = { renew: 'موسم جديد بنفس الدوري', end: 'ينتهي الدوري' } as const

export const STATUS = { waiting: 'لم يبدأ', running: 'جارٍ', finished: 'انتهى' } as const

/** "3 ملايين"، "1.5 مليون"، "500 ألف". */
export function budget(v: number): string {
  if (v >= 1_000_000) {
    const m = v / 1_000_000
    const n = Number.isInteger(m) ? String(m) : m.toFixed(1)
    return m >= 3 && m <= 10 && Number.isInteger(m) ? `${n} ملايين` : `${n} مليون`
  }
  return `${Math.round(v / 1000)} ألف`
}

/** A club's objectives in words (Sprint 33): the place in the league and the stage in the cup. */
const CUP_STAGES: Record<string, string> = { r16: 'دور الـ16', qf: 'ربع النهائي', sf: 'نصف النهائي', final: 'النهائي', winner: 'البطولة' }
export function leagueGoal(o: { target: number; kind: string }): string {
  if (o.kind === 'title') return 'الفوز باللقب'
  if (o.kind === 'survive') return `البقاء: المركز ${o.target} أو أفضل`
  return `المركز ${o.target} أو أفضل`
}
export const cupGoal = (stage: string) => `الوصول إلى ${CUP_STAGES[stage] ?? stage}`
export const cupStage = (stage: string | null | undefined) => (stage === 'out' ? 'خرج مبكراً' : CUP_STAGES[stage ?? ''] ?? stage ?? '')
