import { useCounter, useVisitors } from "./composables/counters";

const a = useCounter();
const b = useCounter();
a.add();
a.add();
b.add();
console.log("First call:", a.count.value, "Second call:", b.count.value);

useVisitors().arrive();
useVisitors().arrive();
console.log("Shared by every call:", useVisitors().visitors.value);
