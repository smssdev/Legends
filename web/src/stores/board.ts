// [Sprint 20 W2 to W5, W7] The club board of the slot the coach is in: one request (B1) for the board, the top bar's
// money, timers and to-do list, and the missed matches' count. Fetched on entering a slot, on each move between its
// screens (at most once every 20 seconds), and every minute while the page is visible.
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'

export type Board = components['schemas']['ClubBoard']

export const useBoard = defineStore('board', () => {
  const board = ref<Board | null>(null)
  const league = ref<number | null>(null)
  let fetched = 0
  let timer: ReturnType<typeof setInterval> | undefined

  async function load(leagueId: number | null, force = false) {
    if (!leagueId) {
      board.value = null
      league.value = null
      return
    }
    if (!force && league.value === leagueId && Date.now() - fetched < 20000) return
    if (league.value !== leagueId) board.value = null
    league.value = leagueId
    fetched = Date.now()
    try {
      board.value = (await api.GET('/leagues/{league}/team/summary', { params: { path: { league: leagueId } } })).data ?? null
    } catch {
      // No club in this league (left, or not yet taken): no board.
      if (league.value === leagueId) board.value = null
    }
    timer ??= setInterval(() => document.visibilityState === 'visible' && league.value && load(league.value, true), 60000)
  }

  return { board, league, load, refresh: () => load(league.value, true) }
})
