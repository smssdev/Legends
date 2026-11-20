// vue/composables/ar/composables/counters.ts
import { ref } from "vue";
function useCounter() {
  const count = ref(0);
  return { count, add: () => count.value++ };
}
var visitors = ref(0);
function useVisitors() {
  return { visitors, arrive: () => visitors.value++ };
}

// vue/composables/ar/state.ts
var a = useCounter();
var b = useCounter();
a.add();
a.add();
b.add();
console.log("\u0627\u0644\u0627\u0633\u062A\u062F\u0639\u0627\u0621 \u0627\u0644\u0623\u0648\u0644:", a.count.value, "\u0627\u0644\u0627\u0633\u062A\u062F\u0639\u0627\u0621 \u0627\u0644\u062B\u0627\u0646\u064A:", b.count.value);
useVisitors().arrive();
useVisitors().arrive();
console.log("\u0645\u0634\u062A\u0631\u0643 \u0628\u064A\u0646 \u0643\u0644 \u0627\u0644\u0627\u0633\u062A\u062F\u0639\u0627\u0621\u0627\u062A:", useVisitors().visitors.value);
