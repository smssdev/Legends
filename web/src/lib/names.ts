// The names switch [X40]: the leagues, clubs and players in Arabic (the default) or as the game stores them (Latin).
// The dictionary is written at build time (scripts/names.mjs) and loaded once; a name it does not have stays as it
// is. The choice is the coach's, on this device (Profile). The English commentary always says the Latin names.
// [Sprint 21 E3.2] The game in English is English throughout: its names are the Latin ones, whatever the switch.
import { storage } from './storage'
import { computed, ref } from 'vue'
import { locale } from './i18n'

export type NamesLang = 'ar' | 'en'
const KEY = 'names'
type Dict = {
  leagues: Record<string, string>
  clubs: Record<string, string>
  players: Record<string, string>
  nations?: Record<string, string>
}

function readPref(): NamesLang {
  try {
    return storage.get(KEY) === 'en' ? 'en' : 'ar'
  } catch {
    return 'ar'
  }
}

export const namesLang = ref<NamesLang>(readPref())
const dict = ref<Dict | null>(null)
let loading: Promise<void> | null = null

/** Fetch the dictionary once (the app calls it at start; the names show in Latin until it comes). */
export function loadNames(): Promise<void> {
  if (!loading) {
    loading = fetch(import.meta.env.BASE_URL + 'names/ar.json')
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        dict.value = d
      })
      .catch(() => {
        /* no dictionary: the Latin names */
      })
  }
  return loading
}

export function setNamesLang(l: NamesLang) {
  namesLang.value = l
  try {
    storage.set(KEY, l)
  } catch {
    /* private mode: this visit only */
  }
}

/** The names actually shown: Latin in the English game, else the coach's choice. */
export const shownNames = computed<NamesLang>(() => (locale.value === 'en' ? 'en' : namesLang.value))

const pick = (table: keyof Dict, s: string | null | undefined) =>
  !s || shownNames.value === 'en' ? (s ?? '') : (dict.value?.[table]?.[s] ?? s)

/** A player's name: [Sprint 30, the owner's decision 2026-11-01] English on every screen, whatever the switch. */
export const pn = (s: string | null | undefined) => s ?? ''
/** A club's name. */
export const cn = (s: string | null | undefined) => pick('clubs', s)
/** A league's name. */
export const ln = (s: string | null | undefined) => pick('leagues', s)
/** [Sprint 30 Q10] A nationality (Belgium → بلجيكا in the Arabic game). */
export const natn = (s: string | null | undefined) => pick('nations', s)
/** Any name the game shows: a club's, else a league's, else a country's (a player's stays English, as what none knows). */
export const nm = (s: string | null | undefined) =>
  !s || shownNames.value === 'en' ? (s ?? '') : (dict.value?.clubs[s] ?? dict.value?.leagues[s] ?? dict.value?.nations?.[s] ?? s)
