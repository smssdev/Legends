import { ref } from "vue";
import { useEventListener } from "./useEventListener";

export function useOnline() {
  const online = ref(navigator.onLine);
  useEventListener(window, "online", () => (online.value = true));
  useEventListener(window, "offline", () => (online.value = false));
  return online;
}
