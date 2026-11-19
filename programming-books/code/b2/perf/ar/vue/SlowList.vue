<script setup lang="ts">
// A child component re-renders only when its props change: Vue needs no memo()
defineProps<{ items: string[] }>();

// A deliberately slow row: in a real app, a rich card with images, prices and badges
function slow(name: string) {
  const start = performance.now();
  while (performance.now() - start < 0.2) {
    // 0.2 ms of work per row
  }
  return name;
}
</script>

<template>
  <ul>
    <li v-for="name in items.slice(0, 2000)" :key="name">{{ slow(name) }}</li>
  </ul>
</template>
