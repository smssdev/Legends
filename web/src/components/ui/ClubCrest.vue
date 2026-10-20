<script setup lang="ts">
// A club's badge: the generated SVG from the API (the same picture the app shows), its name under it if asked.
defineProps<{ url: string; code: string; name?: string; size?: number }>()
</script>

<template>
  <span class="inline-flex flex-col items-center gap-1.5">
    <img :src="url" :alt="name ?? code" :width="size ?? 48" :height="Math.round((size ?? 48) * 1.12)" loading="lazy" />
    <span v-if="name" class="max-w-24 truncate text-sm text-text-soft">{{ name }}</span>
  </span>
</template>
