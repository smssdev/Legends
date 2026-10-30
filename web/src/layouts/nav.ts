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
  // [Sprint 20 W5] The club board: the first page of a slot, outside the portals.
  { name: 'club', path: '/club', label: 'لوحة النادي', icon: 'club', club: true },
  { name: 'team', path: '/team', label: 'الفريق', icon: 'team', club: true, group: 'team' },
  { name: 'lineup', path: '/lineup', label: 'التشكيلة', icon: 'lineup', club: true, group: 'team' },
  { name: 'tactics', path: '/tactics', label: 'التكتيك', icon: 'tactics', club: true, group: 'team' },
  { name: 'training', path: '/training', label: 'التدريب', icon: 'training', club: true, group: 'team' },
  { name: 'specialists', path: '/specialists', label: 'الجهاز الفني', icon: 'staff', club: true, group: 'team' },
  { name: 'market', path: '/market', label: 'السوق', icon: 'market', club: true, group: 'club' },
  { name: 'scout', path: '/scout', label: 'الكشاف', icon: 'scout', club: true, group: 'club' },
  { name: 'stadium', path: '/stadium', label: 'الملعب', icon: 'stadium', club: true, group: 'club' },
  { name: 'finance', path: '/finance', label: 'المالية', icon: 'finance', club: true, group: 'club' },
  // [Sprint 20 B5] The weekly quests.
  { name: 'quests', path: '/quests', label: 'المهام الأسبوعية', icon: 'quest', club: true, group: 'club' },
  { name: 'match', path: '/match', label: 'المباراة', icon: 'match', club: true, group: 'comps' },
  { name: 'league', path: '/league', label: 'الدوري والكأس', icon: 'league', club: true, group: 'comps' },
  // [Sprint 21 E4.3] The whole season's fixtures, any club's.
  { name: 'fixtures', path: '/fixtures', label: 'جدول المباريات', icon: 'match', club: true, group: 'comps' },
  { name: 'stats', path: '/stats', label: 'جدول الدوري', icon: 'league', club: true, group: 'comps' },
  // [Sprint 20 B4] The friendlies.
  { name: 'friendlies', path: '/friendlies', label: 'الوديات', icon: 'friendly', club: true, group: 'comps' },
  { name: 'newspaper', path: '/newspaper', label: 'أخبار الدوري', icon: 'news', club: true, group: 'media', inLeague: true },
  { name: 'predictions', path: '/predictions', label: 'التوقعات', icon: 'predict', club: true, group: 'media', inLeague: true },
  { name: 'inbox', path: '/inbox', label: 'الرسائل', icon: 'inbox' },
  // [Sprint 29] The chat groups and the tournaments, outside a slot as the inbox.
  { name: 'groups', path: '/groups', label: 'الجروبات', icon: 'chat' },
  { name: 'tournaments', path: '/tournaments', label: 'البطولات', icon: 'trophy' },
  { name: 'sim', path: '/sim', label: 'المحاكي', icon: 'sim', dev: true },
]

/** The four portals inside a slot [UP7]. */
export const GROUPS: { key: Group; label: string; icon: keyof typeof PATHS }[] = [
  { key: 'team', label: 'إدارة الفريق', icon: 'team' },
  { key: 'club', label: 'النادي والمالية', icon: 'finance' },
  { key: 'comps', label: 'المنافسات', icon: 'league' },
  { key: 'media', label: 'الإعلام والتفاعل', icon: 'news' },
]
