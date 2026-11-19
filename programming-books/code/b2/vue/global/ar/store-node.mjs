// vue/global/ar/store-node.ts
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
counter.$onAction(({ name, args }) => console.log("\u0641\u0639\u0644:", name, "\u0628\u0640", args));
counter.$subscribe(() => console.log("\u062A\u063A\u064A\u0651\u0631:", counter.count, "\u2192 double", counter.double), { flush: "sync" });
counter.increase();
counter.increase(5);
counter.$dispose();
counter.increase();
console.log("\u0628\u0639\u062F \u200E$dispose:", counter.count);
