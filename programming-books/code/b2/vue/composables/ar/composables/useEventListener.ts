import { onScopeDispose } from "vue";

// يُزال حين يذهب المكوّن (أو أي نطاق آثار) الذي استدعاه
export function useEventListener<K extends keyof WindowEventMap>(
  target: Window,
  event: K,
  handler: (e: WindowEventMap[K]) => void,
) {
  target.addEventListener(event, handler);
  onScopeDispose(() => target.removeEventListener(event, handler));
}
