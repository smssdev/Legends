// The game's words explained, from the server, for the "?" beside each term [X19]. Fetched once per visit.
import { reactive } from 'vue'
import { api } from '../api/client'

const terms = reactive<Record<string, string>>({})
let asked = false

export function useGlossary(): Record<string, string> {
  if (!asked) {
    asked = true
    api.GET('/data/glossary').then(({ data }) => Object.assign(terms, data?.terms ?? {})).catch(() => (asked = false))
  }
  return terms
}
