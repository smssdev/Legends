// [Sprint 48 T2] What the squad's tabs share: the season's numbers (GET /leagues/{league}/team/season) and how they read.
import type { Line } from '../../../lib/format'

export type SeasonPlayer = { goals: number; assists: number; played: number; ratings: Record<string, number>; average: number | null }
export type SeasonTransfer = {
  id: number
  player_id: number
  name: string
  position: string
  from: string | null
  to: string | null
  price: number
  value: number
  at: string
}
export type SeasonData = { rounds: number; players: Record<string, SeasonPlayer>; transfers: SeasonTransfer[] }

/** A line's header over its rows. */
export const LINE_HEAD: Record<Line, string> = { gk: 'حراس المرمى', def: 'المدافعون', mid: 'لاعبو الوسط', att: 'المهاجمون' }

/** A match rating (hundredths) in the design's rating colours: 8 and up deep green, 7 green, 6 gold, under 6 orange. */
export const ratingTone = (r: number) =>
  r >= 800
    ? 'bg-success text-on-gold'
    : r >= 700
      ? 'bg-fitness-high text-bg-deep'
      : r >= 600
        ? 'bg-gold text-on-gold'
        : 'bg-warning text-bg-deep'
