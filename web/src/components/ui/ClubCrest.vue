<script setup lang="ts">
// A club's badge: its crest from the API (a static file or its logo, Sprint 58), its name under it if asked; the shield of
// its code when the picture does not come (AppImage).
defineProps<{ url: string; code: string; name?: string; size?: number }>()
</script>

<template>
  <span class="inline-flex flex-col items-center gap-1.5">
    <AppImage :src="url" :alt="name ?? code" :size="size ?? 48" :crest="{ code }" />
    <span v-if="name" class="max-w-24 truncate text-sm text-text-soft">{{ name }}</span>
  </span>
</template>
