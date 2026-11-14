<script setup lang="ts">
// [Sprint 54 W3] A screen's title: the cream turning gold with a short gold bar under it (the look that lived in
// style.css as `main h1.font-display`), an optional line under it, and the screen's actions on the other side.
defineProps<{ title: string; subtitle?: string }>()
</script>

<template>
  <header class="ui-page-title-row flex flex-wrap items-end justify-between gap-3">
    <div class="min-w-0">
      <h1 class="ui-page-title font-display text-headline">{{ $t(title) }}</h1>
      <p v-if="subtitle || $slots.subtitle" class="mt-1 text-caption text-text-muted">
        <slot name="subtitle">{{ $t(subtitle) }}</slot>
      </p>
    </div>
    <div v-if="$slots.default" class="flex shrink-0 items-center gap-2"><slot /></div>
  </header>
</template>
