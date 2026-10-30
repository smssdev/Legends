<script setup lang="ts">
// [X61] One empty state for every list with nothing in it: a drawn icon, a title, a line on what fills it, and the
// button that does (when there is one), instead of a grey sentence.
import Icon, { type PATHS } from '../Icon.vue'

defineProps<{ icon: keyof typeof PATHS; title: string; text?: string; cta?: { label: string; to: string } }>()
</script>

<template>
  <section class="flex animate-fade-up flex-col items-center gap-2 rounded-xl bg-surface px-4 py-8 text-center">
    <span class="grid size-14 place-items-center rounded-full bg-gold/12 text-gold"><Icon :name="icon" :size="28" /></span>
    <h2 class="font-display text-lg font-extrabold">{{ $t(title) }}</h2>
    <p v-if="text" class="max-w-sm text-sm text-text-muted">{{ $t(text) }}</p>
    <RouterLink v-if="cta" :to="cta.to" class="mt-1 flex min-h-touch items-center rounded-lg bg-gold px-5 font-bold text-on-gold transition active:scale-[0.97]">{{ $t(cta.label) }}</RouterLink>
  </section>
</template>
