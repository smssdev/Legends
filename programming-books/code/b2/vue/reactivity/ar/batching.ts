import { nextTick, ref, watch } from "vue";

const count = ref(0);
// ثلاثة تغييرات، ومرة واحدة للمراقب، بالقيمتين الأولى والأخيرة
watch(count, (now, before) => console.log(`watch: ${before} → ${now}`));

count.value++;
count.value++;
count.value++;
console.log("بعد التغييرات مباشرة:", count.value);
await nextTick();
console.log("بعد nextTick");
