import { nextTick, ref, watch } from "vue";

const count = ref(0);
// Three changes, one run of the watcher, with the first and last values
watch(count, (now, before) => console.log(`watch: ${before} → ${now}`));

count.value++;
count.value++;
count.value++;
console.log("Right after the changes:", count.value);
await nextTick();
console.log("After nextTick");
