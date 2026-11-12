// The league whose club the "الفريق" and "التشكيلة" sections show (Sprint 16): the last one opened with
// a club of mine, else the first of my leagues with one. Kept on this device only.
import { storage } from './storage'
import { api } from '../api/client'

const KEY = 'league'

export function rememberLeague(id: number) {
  try {
    storage.set(KEY, String(id))
  } catch {
    // Private mode: the first league with a club is used instead.
  }
}

export async function currentLeague(): Promise<number | null> {
  const { data } = await api.GET('/leagues')
  const mine = (data?.leagues ?? []).filter((l) => l.my_club_id)
  let saved: number | null = null
  try {
    saved = Number(storage.get(KEY)) || null
  } catch {
    saved = null
  }
  return mine.find((l) => l.id === saved)?.id ?? mine[0]?.id ?? null
}
