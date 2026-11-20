import { onScopeDispose, readonly, ref } from "vue";

// A composable: a function that uses the Composition API and returns reactive state
export function useStopwatch() {
  // Each call makes new refs: two components never share a stopwatch by accident
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
