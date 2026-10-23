// The coins wallet (Sprint 34, docs/features/premium.md): the balance on the shell, and the wallet page's view.
// Reloaded after anything that spends or earns coins.
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'

export const useWallet = defineStore('wallet', () => {
  const view = ref<components['schemas']['WalletView'] | null>(null)

  async function load() {
    try {
      view.value = (await api.GET('/wallet')).data!
    } catch {
      /* the shell keeps its last number */
    }
  }

  /** Coins can be spent in this league (not a fair one). */
  const open = (leagueId: number | null) => !!leagueId && !!view.value?.leagues.some((l) => l.id === leagueId && !l.fair)
  const price = (key: string) => view.value?.prices[key] ?? 0

  return { view, load, open, price }
})
