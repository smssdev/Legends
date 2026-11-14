// [Sprint 20 W3, W4] What each timer and each waiting item is called, and the screen it opens.
import type { Board } from '../../stores/board'

type Timer = Board['timers'][number]
type Pending = Board['pending'][number]

export const LINE_NAMES: Record<string, string> = { gk: 'الحراسة', def: 'الدفاع', mid: 'الوسط', att: 'الهجوم' }
export const SECTION_NAMES: Record<string, string> = { seats: 'التذاكر والمقاعد', pitch: 'أرضية الملعب', training: 'منشأة التدريب' }

export const TIMER: Record<Timer['kind'], { label: string; to: string; icon: string }> = {
  match: { label: 'المباراة القادمة', to: '/match', icon: 'match' },
  training: { label: 'التدريب', to: '/training', icon: 'training' },
  stadium: { label: 'الملعب', to: '/stadium', icon: 'stadium' },
  scout: { label: 'تقرير الكشاف', to: '/scout', icon: 'scout' },
  daily: { label: 'مكافأة الدخول اليومية', to: '/wallet', icon: 'quest' },
  market: { label: 'صفقات السوق التالية', to: '/market', icon: 'market' },
}

export const PENDING: Record<Pending['kind'], { label: string; to: (p: Pending, league: number | null) => string }> = {
  window: { label: 'النافذة التكتيكية مفتوحة', to: (p) => `/live/${p.match_id}` },
  lineup: { label: 'مصاب أو موقوف في تشكيلتك', to: () => '/lineup' },
  offers: { label: 'عروض واردة', to: () => '/market' },
  requests: { label: 'طلبات انضمام لدوريك', to: (_p, l) => (l ? `/leagues/${l}` : '/leagues') },
  training_empty: { label: 'خانة تدريب فارغة', to: () => '/training' },
  training_done: { label: 'تدريب انتهى', to: () => '/training' },
}

export const SEVERITY: Record<Pending['severity'], string> = {
  high: 'var(--color-live)',
  mid: 'var(--color-warning)',
  low: 'var(--color-brand-light)',
}
