// [Sprint 30 Q2] One way to ask before anything that cannot be undone, instead of the browser's confirm(): any screen
// awaits `useConfirm().ask({...})` and the one window (ConfirmHost in App.vue, on ConfirmDangerDialog) answers true
// or false. With `expected`, the button wakes only once that name or number is typed.
import { defineStore } from 'pinia'
import { ref } from 'vue'

export type ConfirmAsk = { title: string; text?: string; action: string; expected?: string }

export const useConfirm = defineStore('confirm', () => {
  const current = ref<ConfirmAsk | null>(null)
  let answer: ((ok: boolean) => void) | null = null
  function ask(q: ConfirmAsk): Promise<boolean> {
    answer?.(false)
    current.value = q
    return new Promise((resolve) => { answer = resolve })
  }
  function settle(ok: boolean) {
    answer?.(ok)
    answer = null
    current.value = null
  }
  return { current, ask, settle }
})
