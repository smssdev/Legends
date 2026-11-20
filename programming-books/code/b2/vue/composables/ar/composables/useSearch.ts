import { ref, toValue, watch, type MaybeRefOrGetter } from "vue";
import { searchProducts, type Product } from "../products";

export function useSearch(query: MaybeRefOrGetter<string>) {
  const results = ref<Product[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  watch(
    () => toValue(query).trim(),
    async (q, _before, onCleanup) => {
      error.value = null;
      if (!q) {
        results.value = [];
        return;
      }
      // الاستعلام الجديد يلغي طلب القديم
      const controller = new AbortController();
      onCleanup(() => controller.abort());
      loading.value = true;
      try {
        results.value = await searchProducts(q, controller.signal);
      } catch (e) {
        if (controller.signal.aborted) return;
        error.value = (e as Error).message;
      }
      loading.value = false;
    },
    { immediate: true },
  );

  return { results, loading, error };
}
