<script setup lang="ts">
// [X61] One empty state for every list with nothing in it: a drawn icon, a title, a line on what fills it, and the
// button that does (when there is one), instead of a grey sentence. [Sprint 26 W3] The lion mascot (A2) waits there
// calmly, the icon on its shirt's corner.
import Icon, { type PATHS } from '../Icon.vue'
import Character from '../characters/Character.vue'

defineProps<{ icon: keyof typeof PATHS; title: string; text?: string; cta?: { label: string; to: string } }>()
</script>

<template>
  <section class="flex animate-fade-up flex-col items-center gap-2 rounded-xl bg-surface px-4 py-8 text-center">
    <span class="relative w-24">
      <Character model="A2" mood="idle" class="w-24" />
      <span class="absolute -bottom-1 end-0 grid size-9 place-items-center rounded-full bg-gold/15 text-gold ring-2 ring-surface"><Icon :name="icon" :size="18" /></span>
    </span>
    <h2 class="font-display text-lg font-extrabold">{{ $t(title) }}</h2>
    <p v-if="text" class="max-w-sm text-sm text-text-muted">{{ $t(text) }}</p>
    <RouterLink v-if="cta" :to="cta.to" class="mt-1 flex min-h-touch items-center rounded-lg bg-gold px-5 font-bold text-on-gold transition active:scale-[0.97]">{{ $t(cta.label) }}</RouterLink>
  </section>
</template>
