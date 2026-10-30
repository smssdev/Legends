// [X61] Short confirmations from the top of the screen (under the top bar, never over the phone's bottom bar): a
// success or an error, gone after a few seconds or on a tap.
import { defineStore } from 'pinia'
import { ref } from 'vue'

export type Toast = { id: number; text: string; tone: 'success' | 'error' }

export const useToast = defineStore('toast', () => {
  const list = ref<Toast[]>([])
  let seq = 0
  function show(text: string, tone: Toast['tone'] = 'success', ms = 3200) {
    const id = ++seq
    list.value.push({ id, text, tone })
    if (list.value.length > 3) list.value.shift()
    setTimeout(() => close(id), ms)
    if (tone === 'success') navigator.vibrate?.(10)
  }
  function close(id: number) {
    list.value = list.value.filter((t) => t.id !== id)
  }
  return { list, show, close }
})
