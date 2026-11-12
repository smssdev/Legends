// The coins wallet (Sprint 34, docs/features/premium.md): the balance on the shell, and the wallet page's view.
// Reloaded after anything that spends or earns coins.
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'
import { takeBoot } from '../lib/session'

export const useWallet = defineStore('wallet', () => {
  const view = ref<components['schemas']['WalletView'] | null>(null)
  /** [Sprint 58 W7] The last load failed: the shell shows «?», not a balance of 0 it does not know. */
  const error = ref(false)

  /** userId: the account, to take the visit's start once (GET /bootstrap) instead of asking. */
  async function load(userId?: number) {
    const start = takeBoot('wallet', userId)
    if (start) return void (view.value = start as typeof view.value)
    try {
      view.value = (await api.GET('/wallet')).data!
      error.value = false
    } catch {
      // The shell keeps its last number, or shows «?» when it has none.
      error.value = true
    }
  }

  /** Coins can be spent in this league (not a fair one). */
  const open = (leagueId: number | null) => !!leagueId && !!view.value?.leagues.some((l) => l.id === leagueId && !l.fair)
  const price = (key: string) => view.value?.prices[key] ?? 0

  return { view, error, load, open, price }
})
