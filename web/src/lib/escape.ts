// [Sprint 30 Q4] Esc closes a window that is not on UiDialog (a full-screen card, a side panel): listened to while the
// component is on screen, and only when `active` says it is open.
import { onBeforeUnmount, onMounted } from 'vue'

export function useEscape(close: () => void, active: () => boolean = () => true) {
  const onKey = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && active()) close()
  }
  onMounted(() => window.addEventListener('keydown', onKey))
  onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
}
