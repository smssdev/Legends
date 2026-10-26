// The game's words explained, from the server, for the "?" beside each term [X19]. Fetched once per visit, and again in the other language [UP2].
import { reactive, watch } from 'vue'
import { api } from '../api/client'
import { locale } from './i18n'

const terms = reactive<Record<string, string>>({})
let asked = false

export function useGlossary(): Record<string, string> {
  if (!asked) {
    asked = true
    fetchTerms()
    // [UP2] Asked again in the new language when the coach switches.
    watch(locale, fetchTerms)
  }
  return terms
}
function fetchTerms() {
  api.GET('/data/glossary').then(({ data }) => Object.assign(terms, data?.terms ?? {})).catch(() => (asked = false))
}
