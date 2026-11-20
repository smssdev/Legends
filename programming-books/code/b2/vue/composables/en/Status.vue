<script setup lang="ts">
import { ref } from "vue";
import { useEventListener } from "./composables/useEventListener";
import { useOnline } from "./composables/useOnline";

const online = useOnline();
const width = ref(window.innerWidth);
useEventListener(window, "resize", () => (width.value = window.innerWidth));
</script>

<template>
  <p :class="online ? 'ok' : 'warn'" role="status">{{ online ? "Online" : "Offline: changes will be saved when you are back" }}</p>
  <p>Window width: {{ width }}px</p>
</template>
