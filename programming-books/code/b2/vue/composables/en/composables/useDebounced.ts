import { ref, toValue, watch, type MaybeRefOrGetter, type Ref } from "vue";

// Accepts a value, a ref or a getter, so callers can pass whatever they have
export function useDebounced<T>(source: MaybeRefOrGetter<T>, ms = 300): Readonly<Ref<T>> {
  const value = ref(toValue(source)) as Ref<T>;
  watch(
    () => toValue(source),
    (now, _before, onCleanup) => {
      const id = setTimeout(() => (value.value = now), ms);
      onCleanup(() => clearTimeout(id));
    },
  );
  return value;
}
