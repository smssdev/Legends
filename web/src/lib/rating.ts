// [Sprint 25] The coach rating's tiers on screen: their names and colours (from the design tokens). The points and
// the tiers themselves come from the API (App\Season\CoachRating).
import type { components } from '../api/schema'
import { t } from './i18n'

export type TierKey = components['schemas']['RatingTierKey']

const NAMES: Record<TierKey, string> = {
  prospect: 'الواعد',
  tactician: 'التكتيكي',
  professional: 'المحترف',
  elite: 'النخبة',
  mastermind: 'العقل المدبر',
  icon: 'الأيقونة',
  legend: 'الأسطورة',
}

/** In the tiers' order. */
export const TIER_COLOR: Record<TierKey, string> = {
  prospect: 'var(--color-text-muted)',
  tactician: 'var(--color-bronze)',
  professional: 'var(--color-silver)',
  elite: 'var(--color-gold)',
  mastermind: 'var(--color-brand)',
  icon: 'var(--color-live)',
  legend: 'var(--color-gold-light)',
}

export const tierName = (key: TierKey) => t(NAMES[key])
export const divisionName = (division: number | null | undefined) => (division ? ['', 'I', 'II', 'III'][division] : '')
export const signed = (n: number) => (n > 0 ? '+' + n : String(n))
