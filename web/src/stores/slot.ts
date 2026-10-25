// The slot the coach is in [X29]: the club whose sections the menu shows. Read from the home screen's slots and the
// league remembered on this device (lib/currentLeague); outside a slot there is no menu, only the top bar.
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'

type Slot = components['schemas']['HomeScreen']['slots'][number]
type Coach = components['schemas']['HomeScreen']['coach']

export const useSlot = defineStore('slot', () => {
  const slots = ref<Slot[]>([])
  const current = ref<Slot | null>(null)
  // The coach's own tab on the shell's header (level and avatar) [X32].
  const coach = ref<Coach | null>(null)
  let loadedFor = 0

  async function load(userId: number, force = false) {
    if (!force && loadedFor === userId) return pick()
    loadedFor = userId
    try {
      const home = (await api.GET('/home')).data
      slots.value = home?.slots ?? []
      coach.value = home?.coach ?? null
    } catch {
      slots.value = []
      coach.value = null
    }
    pick()
  }

  function pick() {
    let saved = 0
    try {
      saved = Number(localStorage.getItem('legends.league')) || 0
    } catch {}
    const clubs = slots.value.filter((s) => s.state === 'club')
    current.value = clubs.find((s) => s.league?.id === saved) ?? clubs[0] ?? null
  }

  return { slots, current, coach, load, pick }
})
