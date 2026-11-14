// [Sprint 30 Q2] One way to ask before anything that cannot be undone, instead of the browser's confirm(): any screen
// awaits `useConfirm().ask({...})` and the one window (ConfirmHost in App.vue, on ConfirmDangerDialog) answers true
// or false. With `expected`, the button wakes only once that name or number is typed.
import { storage } from '../lib/storage'
import { defineStore } from 'pinia'
import { ref } from 'vue'

// [X87] tone: 'gold' for paying coins (not a danger, a spend); remember: a device key that, once «لا تسألني مرة أخرى» is
// ticked, answers yes without asking again.
export type ConfirmAsk = { title: string; text?: string; action: string; expected?: string; tone?: 'danger' | 'gold'; remember?: string }

export const useConfirm = defineStore('confirm', () => {
  const current = ref<ConfirmAsk | null>(null)
  let answer: ((ok: boolean) => void) | null = null
  function ask(q: ConfirmAsk): Promise<boolean> {
    try {
      if (q.remember && storage.get(q.remember) === '1') return Promise.resolve(true)
    } catch {}
    answer?.(false)
    current.value = q
    return new Promise((resolve) => {
      answer = resolve
    })
  }
  function settle(ok: boolean, remember = false) {
    if (ok && remember && current.value?.remember)
      try {
        storage.set(current.value.remember, '1')
      } catch {}
    answer?.(ok)
    answer = null
    current.value = null
  }
  return { current, ask, settle }
})
