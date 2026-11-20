<script setup lang="ts">
import { onWatcherCleanup, ref, watch } from "vue";

const running = ref(false);
const seconds = ref(0);

watch(running, (on) => {
  if (!on) return;
  const id = setInterval(() => seconds.value++, 1000);
  // Runs before the next run of the watcher, and when the component is removed
  onWatcherCleanup(() => clearInterval(id));
});
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> seconds
    <button type="button" :aria-pressed="running" @click="running = !running">
      {{ running ? "Stop" : "Start" }}
    </button>
  </p>
</template>
