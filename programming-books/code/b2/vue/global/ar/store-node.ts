import { computed, ref } from "vue";
import { createPinia, defineStore, setActivePinia } from "pinia";

// المخزن يعمل دون أي مكوّن: الكود نفسه يعمل في Node وفي الاختبارات
const useCounter = defineStore("counter", () => {
  const count = ref(0);
  const double = computed(() => count.value * 2);
  const increase = (by = 1) => (count.value += by);
  return { count, double, increase };
});

setActivePinia(createPinia());
const counter = useCounter();

counter.$onAction(({ name, args }) => console.log("فعل:", name, "بـ", args));
counter.$subscribe(() => console.log("تغيّر:", counter.count, "→ double", counter.double), { flush: "sync" });

counter.increase();
counter.increase(5);
counter.$dispose();
counter.increase();
console.log("بعد ‎$dispose:", counter.count);
