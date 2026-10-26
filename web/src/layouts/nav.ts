// The game's sections (docs/design/legends-ui: WebHome's side bar, MobileHome's bottom bar).
// A section whose sprint has not come yet shows "قريباً" with the sprint that brings it.
// [X29] The menu shows only inside a slot: the sections marked club are a club's own; the others (home, my leagues,
// the inbox, the simulator) sit outside, reached from the home screen and the top bar.
// [UP7] A club's sections fall in four portals, each an icon that opens its own list; the side menu holds them all.
import type { PATHS } from '../components/Icon.vue'

export type Group = 'team' | 'club' | 'comps' | 'media'
export interface Section { name: string; path: string; label: string; icon: keyof typeof PATHS; sprint?: number; dev?: boolean; club?: boolean; group?: Group; inLeague?: boolean }

export const SECTIONS: Section[] = [
  { name: 'home', path: '/', label: 'الرئيسية', icon: 'home' },
  { name: 'leagues', path: '/leagues', label: 'دورياتي', icon: 'leagues' },
  { name: 'team', path: '/team', label: 'الفريق', icon: 'team', club: true, group: 'team' },
  { name: 'lineup', path: '/lineup', label: 'التشكيلة', icon: 'lineup', club: true, group: 'team' },
  { name: 'tactics', path: '/tactics', label: 'التكتيك', icon: 'tactics', club: true, group: 'team' },
  { name: 'training', path: '/training', label: 'التدريب', icon: 'training', club: true, group: 'team' },
  { name: 'specialists', path: '/specialists', label: 'الطاقم', icon: 'staff', club: true, group: 'team' },
  { name: 'market', path: '/market', label: 'السوق', icon: 'market', club: true, group: 'club' },
  { name: 'scout', path: '/scout', label: 'الكشاف', icon: 'scout', club: true, group: 'club' },
  { name: 'stadium', path: '/stadium', label: 'الملعب', icon: 'stadium', club: true, group: 'club' },
  { name: 'finance', path: '/finance', label: 'المالية', icon: 'finance', club: true, group: 'club' },
  { name: 'match', path: '/match', label: 'المباراة', icon: 'match', club: true, group: 'comps' },
  { name: 'league', path: '/league', label: 'الدوري والكأس', icon: 'league', sprint: 15, club: true, group: 'comps' },
  { name: 'stats', path: '/stats', label: 'الإحصائيات', icon: 'league', club: true, group: 'comps' },
  { name: 'newspaper', path: '/newspaper', label: 'الصحيفة', icon: 'news', club: true, group: 'media', inLeague: true },
  { name: 'predictions', path: '/predictions', label: 'التوقعات', icon: 'predict', club: true, group: 'media', inLeague: true },
  { name: 'inbox', path: '/inbox', label: 'الرسائل', icon: 'inbox' },
  { name: 'sim', path: '/sim', label: 'المحاكي', icon: 'sim', dev: true },
]

/** The four portals inside a slot [UP7]. */
export const GROUPS: { key: Group; label: string; icon: keyof typeof PATHS }[] = [
  { key: 'team', label: 'إدارة الفريق', icon: 'team' },
  { key: 'club', label: 'النادي والمالية', icon: 'finance' },
  { key: 'comps', label: 'المنافسات', icon: 'league' },
  { key: 'media', label: 'الإعلام والتفاعل', icon: 'news' },
]
