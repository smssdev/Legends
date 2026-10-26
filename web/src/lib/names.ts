// The names switch [X40]: the leagues, clubs and players in Arabic (the default) or as the game stores them (Latin).
// The dictionary is written at build time (scripts/names.mjs) and loaded once; a name it does not have stays as it
// is. The choice is the coach's, on this device (Profile). The English commentary always says the Latin names.
import { ref } from 'vue'

export type NamesLang = 'ar' | 'en'
const KEY = 'legends.names'
type Dict = { leagues: Record<string, string>; clubs: Record<string, string>; players: Record<string, string> }

function readPref(): NamesLang {
  try { return localStorage.getItem(KEY) === 'en' ? 'en' : 'ar' } catch { return 'ar' }
}

export const namesLang = ref<NamesLang>(readPref())
const dict = ref<Dict | null>(null)
let loading: Promise<void> | null = null

/** Fetch the dictionary once (the app calls it at start; the names show in Latin until it comes). */
export function loadNames(): Promise<void> {
  if (!loading) {
    loading = fetch(import.meta.env.BASE_URL + 'names/ar.json')
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => { dict.value = d })
      .catch(() => { /* no dictionary: the Latin names */ })
  }
  return loading
}

export function setNamesLang(l: NamesLang) {
  namesLang.value = l
  try { localStorage.setItem(KEY, l) } catch { /* private mode: this visit only */ }
}

const pick = (table: keyof Dict, s: string | null | undefined) =>
  !s || namesLang.value === 'en' ? (s ?? '') : (dict.value?.[table][s] ?? s)

/** A player's name as the coach chose to see it. */
export const pn = (s: string | null | undefined) => pick('players', s)
/** A club's name. */
export const cn = (s: string | null | undefined) => pick('clubs', s)
/** A league's name. */
export const ln = (s: string | null | undefined) => pick('leagues', s)
/** Any name the game shows: a player's, else a club's, else a league's (what none knows stays as it is). */
export const nm = (s: string | null | undefined) =>
  !s || namesLang.value === 'en' ? (s ?? '') : (dict.value?.players[s] ?? dict.value?.clubs[s] ?? dict.value?.leagues[s] ?? s)
