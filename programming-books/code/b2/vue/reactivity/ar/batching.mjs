// vue/reactivity/ar/batching.ts
import { nextTick, ref, watch } from "vue";
var count = ref(0);
watch(count, (now, before) => console.log(`watch: ${before} \u2192 ${now}`));
count.value++;
count.value++;
count.value++;
console.log("\u0628\u0639\u062F \u0627\u0644\u062A\u063A\u064A\u064A\u0631\u0627\u062A \u0645\u0628\u0627\u0634\u0631\u0629:", count.value);
await nextTick();
console.log("\u0628\u0639\u062F nextTick");
