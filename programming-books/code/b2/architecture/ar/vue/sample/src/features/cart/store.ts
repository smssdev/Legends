import { defineStore } from "pinia";
import { computed, ref } from "vue";

type Item = { id: number; price: number };
export const useCart = defineStore("cart", () => {
  const items = ref<Item[]>([]);
  const count = computed(() => items.value.length);
  const add = (item: Item) => items.value.push(item);
  return { items, count, add };
});
