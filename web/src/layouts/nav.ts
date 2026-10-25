// The game's sections (docs/design/legends-ui: WebHome's side bar, MobileHome's bottom bar).
// A section whose sprint has not come yet shows "قريباً" with the sprint that brings it.
// [X29] The menu shows only inside a slot: the sections marked club are a club's own; the others (home, my leagues,
// the inbox, the simulator) sit outside, reached from the home screen and the top bar.
import type { PATHS } from '../components/Icon.vue'

export interface Section { name: string; path: string; label: string; icon: keyof typeof PATHS; sprint?: number; dev?: boolean; club?: boolean }

export const SECTIONS: Section[] = [
  { name: 'home', path: '/', label: 'الرئيسية', icon: 'home' },
  { name: 'leagues', path: '/leagues', label: 'دورياتي', icon: 'leagues' },
  { name: 'match', path: '/match', label: 'المباراة', icon: 'match', club: true },
  { name: 'team', path: '/team', label: 'الفريق', icon: 'team', club: true },
  { name: 'lineup', path: '/lineup', label: 'التشكيلة', icon: 'lineup', club: true },
  { name: 'tactics', path: '/tactics', label: 'التكتيك', icon: 'tactics', club: true },
  { name: 'training', path: '/training', label: 'التدريب', icon: 'training', club: true },
  { name: 'market', path: '/market', label: 'السوق', icon: 'market', club: true },
  { name: 'scout', path: '/scout', label: 'الكشاف', icon: 'scout', club: true },
  { name: 'specialists', path: '/specialists', label: 'الأخصائيون', icon: 'staff', club: true },
  { name: 'stadium', path: '/stadium', label: 'الملعب', icon: 'stadium', club: true },
  { name: 'finance', path: '/finance', label: 'المالية', icon: 'finance', club: true },
  { name: 'stats', path: '/stats', label: 'الإحصائيات', icon: 'league', club: true },
  { name: 'league', path: '/league', label: 'الدوري والكأس', icon: 'league', sprint: 15, club: true },
  { name: 'inbox', path: '/inbox', label: 'الرسائل', icon: 'inbox' },
  { name: 'sim', path: '/sim', label: 'المحاكي', icon: 'sim', dev: true },
]

/** The phone's bottom bar inside a slot: four of the club's sections and "more" for the rest. */
export const TABS = ['team', 'match', 'lineup', 'market']
