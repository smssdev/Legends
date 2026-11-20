import { computed, ref } from "vue";
import { createPinia, defineStore, setActivePinia } from "pinia";

// A store works without any component: the same code runs in Node and in tests
const useCounter = defineStore("counter", () => {
  const count = ref(0);
  const double = computed(() => count.value * 2);
  const increase = (by = 1) => (count.value += by);
  return { count, double, increase };
});

setActivePinia(createPinia());
const counter = useCounter();

counter.$onAction(({ name, args }) => console.log("action:", name, "with", args));
counter.$subscribe(() => console.log("changed:", counter.count, "→ double", counter.double), { flush: "sync" });

counter.increase();
counter.increase(5);
counter.$dispose();
counter.increase();
console.log("after $dispose:", counter.count);
