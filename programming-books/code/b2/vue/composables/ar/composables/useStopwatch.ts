import { onScopeDispose, readonly, ref } from "vue";

// composable: دالة تستخدم واجهة التركيب وتُرجع حالة تفاعلية
export function useStopwatch() {
  // كل استدعاء يصنع مراجع جديدة: فلا يتشارك مكونان مؤقتاً بالصدفة أبداً
  const seconds = ref(0);
  const running = ref(false);
  let timer: ReturnType<typeof setInterval> | undefined;

  function start() {
    if (running.value) return;
    running.value = true;
    timer = setInterval(() => seconds.value++, 1000);
  }
  function stop() {
    clearInterval(timer);
    running.value = false;
  }
  function reset() {
    stop();
    seconds.value = 0;
  }

  onScopeDispose(stop);
  return { seconds: readonly(seconds), running: readonly(running), start, stop, reset };
}
