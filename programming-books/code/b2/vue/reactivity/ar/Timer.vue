<script setup lang="ts">
import { onWatcherCleanup, ref, watch } from "vue";

const running = ref(false);
const seconds = ref(0);

watch(running, (on) => {
  if (!on) return;
  const id = setInterval(() => seconds.value++, 1000);
  // تعمل قبل المرة التالية للمراقب، وحين يُزال المكوّن
  onWatcherCleanup(() => clearInterval(id));
});
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> ثانية
    <button type="button" :aria-pressed="running" @click="running = !running">
      {{ running ? "أوقف" : "ابدأ" }}
    </button>
  </p>
</template>
