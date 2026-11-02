// [X61] Short confirmations from the top of the screen (under the top bar, never over the phone's bottom bar): a
// success or an error, gone after a few seconds or on a tap. [X87] A success may carry one action, «تراجع» (undo), shown
// on the toast while it lasts (a little longer then).
import { defineStore } from 'pinia'
import { ref } from 'vue'

export type ToastAction = { label: string; run: () => unknown }
export type Toast = { id: number; text: string; tone: 'success' | 'error'; action?: ToastAction; group?: string }

export const useToast = defineStore('toast', () => {
  const list = ref<Toast[]>([])
  let seq = 0
  /** group: a new toast of the same group (the same player, the same slot) replaces the one before. */
  function show(text: string, tone: Toast['tone'] = 'success', ms = 3200, action?: ToastAction, group?: string) {
    const id = ++seq
    if (group) list.value = list.value.filter((t) => t.group !== group)
    list.value.push({ id, text, tone, action, group })
    if (list.value.length > 3) list.value.shift()
    setTimeout(() => close(id), action ? Math.max(ms, 6000) : ms)
    if (tone === 'success') navigator.vibrate?.(10)
    return id
  }
  function close(id: number) {
    list.value = list.value.filter((t) => t.id !== id)
  }
  return { list, show, close }
})
