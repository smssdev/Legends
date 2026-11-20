import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";

export type Product = { id: number; name: string; price: number };
type Line = { product: Product; quantity: number };

// A setup store: refs are state, computed are getters, functions are actions
export const useCart = defineStore("cart", () => {
  // useLocalStorage keeps the lines in the browser and loads them on the next visit
  const lines = useLocalStorage<Record<number, Line>>("cart", {});

  const count = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity, 0));
  const total = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity * l.product.price, 0));

  function add(product: Product) {
    const line = lines.value[product.id];
    if (line) line.quantity++;
    else lines.value[product.id] = { product, quantity: 1 };
  }

  function clear() {
    lines.value = {};
  }

  return { lines, count, total, add, clear };
});
