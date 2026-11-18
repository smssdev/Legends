var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/store-node.ts
import { createStore } from "zustand/vanilla";
var require_store_node = __commonJS({
  "en/store-node.ts"() {
    var store = createStore()((set) => ({
      count: 0,
      increase: () => set((s) => ({ count: s.count + 1 }))
    }));
    var stop = store.subscribe((state, previous) => {
      console.log(`count: ${previous.count} \u2192 ${state.count}`);
    });
    store.getState().increase();
    store.getState().increase();
    stop();
    store.getState().increase();
    console.log("after stop():", store.getState().count);
  }
});
export default require_store_node();
