// vue/composables/en/composables/counters.ts
import { ref } from "vue";
function useCounter() {
  const count = ref(0);
  return { count, add: () => count.value++ };
}
var visitors = ref(0);
function useVisitors() {
  return { visitors, arrive: () => visitors.value++ };
}

// vue/composables/en/state.ts
var a = useCounter();
var b = useCounter();
a.add();
a.add();
b.add();
console.log("First call:", a.count.value, "Second call:", b.count.value);
useVisitors().arrive();
useVisitors().arrive();
console.log("Shared by every call:", useVisitors().visitors.value);
