import { onScopeDispose } from "vue";

// Removed when the component (or any effect scope) that called it goes away
export function useEventListener<K extends keyof WindowEventMap>(
  target: Window,
  event: K,
  handler: (e: WindowEventMap[K]) => void,
) {
  target.addEventListener(event, handler);
  onScopeDispose(() => target.removeEventListener(event, handler));
}
