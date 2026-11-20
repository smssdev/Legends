import { ref } from "vue";

export function useCounter() {
  const count = ref(0); // Each call makes new refs: two components never share a stopwatch by accident
  return { count, add: () => count.value++ };
}

const visitors = ref(0); // Created once, outside the function: everyone who calls it shares the same value
export function useVisitors() {
  return { visitors, arrive: () => visitors.value++ };
}
