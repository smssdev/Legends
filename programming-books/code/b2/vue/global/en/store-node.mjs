// vue/global/en/store-node.ts
import { computed, ref } from "vue";
import { createPinia, defineStore, setActivePinia } from "pinia";
var useCounter = defineStore("counter", () => {
  const count = ref(0);
  const double = computed(() => count.value * 2);
  const increase = (by = 1) => count.value += by;
  return { count, double, increase };
});
setActivePinia(createPinia());
var counter = useCounter();
counter.$onAction(({ name, args }) => console.log("action:", name, "with", args));
counter.$subscribe(() => console.log("changed:", counter.count, "\u2192 double", counter.double), { flush: "sync" });
counter.increase();
counter.increase(5);
counter.$dispose();
counter.increase();
console.log("after $dispose:", counter.count);
