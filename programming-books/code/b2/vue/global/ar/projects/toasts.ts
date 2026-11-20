import { defineStore } from "pinia";
import { ref } from "vue";

type Action = { label: string; run: () => void };
type Toast = { id: number; text: string; action?: Action | undefined };

export const useToasts = defineStore("toasts", () => {
  const toasts = ref<Toast[]>([]);
  let next = 1;

  function dismiss(id: number) {
    toasts.value = toasts.value.filter((t) => t.id !== id);
  }

  function notify(text: string, action?: Action) {
    const id = next++;
    toasts.value = [...toasts.value.slice(-2), { id, text, action }];
    setTimeout(() => dismiss(id), 5000);
  }

  return { toasts, notify, dismiss };
});
