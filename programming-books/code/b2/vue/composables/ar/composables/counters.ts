import { ref } from "vue";

export function useCounter() {
  const count = ref(0); // كل استدعاء يصنع مراجع جديدة: فلا يتشارك مكونان مؤقتاً بالصدفة أبداً
  return { count, add: () => count.value++ };
}

const visitors = ref(0); // يُنشأ مرة واحدة خارج الدالة: فكل من يستدعيها يتشارك القيمة نفسها
export function useVisitors() {
  return { visitors, arrive: () => visitors.value++ };
}
