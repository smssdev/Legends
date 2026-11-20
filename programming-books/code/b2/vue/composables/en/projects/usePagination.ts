import { computed, ref, toValue, type MaybeRefOrGetter } from "vue";

export function usePagination<T>(items: MaybeRefOrGetter<readonly T[]>, size = 3) {
  const page = ref(1);
  const pages = computed(() => Math.max(1, Math.ceil(toValue(items).length / size)));
  const current = computed(() => Math.min(page.value, pages.value));
  const rows = computed(() => toValue(items).slice((current.value - 1) * size, current.value * size));
  return {
    page: current,
    pages,
    rows,
    next: () => (page.value = Math.min(current.value + 1, pages.value)),
    previous: () => (page.value = Math.max(current.value - 1, 1)),
  };
}
