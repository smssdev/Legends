<script setup lang="ts">
// A card with a title and an optional link or action on the other side (design: WebHome).
defineProps<{ title?: string }>()
</script>

<template>
  <section class="flex flex-col gap-3 rounded-xl bg-surface p-4 md:p-5">
    <header v-if="title || $slots.action" class="flex items-center justify-between gap-3">
      <h2 class="font-display text-xl font-extrabold">{{ $t(title) }}</h2>
      <slot name="action" />
    </header>
    <slot />
  </section>
</template>
