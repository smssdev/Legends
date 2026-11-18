import { createStore } from "zustand/vanilla";

// المخزن يعمل دون React: الكود نفسه يعمل في Node
type Counter = { count: number; increase: () => void };

const store = createStore<Counter>()((set) => ({
  count: 0,
  increase: () => set((s) => ({ count: s.count + 1 })),
}));

const stop = store.subscribe((state, previous) => {
  console.log(`count: ${previous.count} → ${state.count}`);
});

store.getState().increase();
store.getState().increase();
stop();
store.getState().increase();
console.log("بعد stop():", store.getState().count);
