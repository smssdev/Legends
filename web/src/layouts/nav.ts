// The game's sections (docs/design/legends-ui: WebHome's side bar, MobileHome's bottom bar).
// A section whose sprint has not come yet shows "قريباً" with the sprint that brings it.
import type { PATHS } from '../components/Icon.vue'

export interface Section { name: string; path: string; label: string; icon: keyof typeof PATHS; sprint?: number; dev?: boolean }

export const SECTIONS: Section[] = [
  { name: 'home', path: '/', label: 'الرئيسية', icon: 'home' },
  { name: 'leagues', path: '/leagues', label: 'دورياتي', icon: 'leagues' },
  { name: 'match', path: '/match', label: 'المباراة', icon: 'match' },
  { name: 'team', path: '/team', label: 'الفريق', icon: 'team' },
  { name: 'lineup', path: '/lineup', label: 'التشكيلة', icon: 'lineup' },
  { name: 'tactics', path: '/tactics', label: 'التكتيك', icon: 'tactics' },
  { name: 'training', path: '/training', label: 'التدريب', icon: 'training', sprint: 27 },
  { name: 'market', path: '/market', label: 'السوق', icon: 'market', sprint: 24 },
  { name: 'scout', path: '/scout', label: 'الكشاف', icon: 'scout', sprint: 26 },
  { name: 'stadium', path: '/stadium', label: 'الملعب', icon: 'stadium', sprint: 29 },
  { name: 'finance', path: '/finance', label: 'المالية', icon: 'finance', sprint: 23 },
  { name: 'league', path: '/league', label: 'الدوري والكأس', icon: 'league', sprint: 15 },
  { name: 'inbox', path: '/inbox', label: 'الرسائل', icon: 'inbox' },
  { name: 'sim', path: '/sim', label: 'المحاكي', icon: 'sim', dev: true },
]

/** The phone's bottom bar: four sections and "more" for the rest. */
export const TABS = ['home', 'team', 'match', 'market']
