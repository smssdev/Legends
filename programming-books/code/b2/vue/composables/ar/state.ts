import { useCounter, useVisitors } from "./composables/counters";

const a = useCounter();
const b = useCounter();
a.add();
a.add();
b.add();
console.log("الاستدعاء الأول:", a.count.value, "الاستدعاء الثاني:", b.count.value);

useVisitors().arrive();
useVisitors().arrive();
console.log("مشترك بين كل الاستدعاءات:", useVisitors().visitors.value);
