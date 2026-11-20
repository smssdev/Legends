// vue/reactivity/en/batching.ts
import { nextTick, ref, watch } from "vue";
var count = ref(0);
watch(count, (now, before) => console.log(`watch: ${before} \u2192 ${now}`));
count.value++;
count.value++;
count.value++;
console.log("Right after the changes:", count.value);
await nextTick();
console.log("After nextTick");
