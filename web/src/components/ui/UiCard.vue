<script setup lang="ts">
// A card with a title and an optional link or action on the other side (design: WebHome). [Sprint 54 W2] Its look is its
// own class (.ui-card in style.css), not the rounded-xl + bg-surface pair a screen might write by hand.
defineProps<{ title?: string }>()
</script>

<template>
  <section class="ui-card flex flex-col gap-3 rounded-xl p-4 md:p-5">
    <header v-if="title || $slots.action" class="flex items-center justify-between gap-3">
      <h2 class="font-display text-title">{{ $t(title) }}</h2>
      <slot name="action" />
    </header>
    <slot />
  </section>
</template>
