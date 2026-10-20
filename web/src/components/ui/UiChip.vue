<script setup lang="ts">
// Small labels (design system: مباشر، 1,250 كوينز، فوز، تعادل، خسارة، الحكم).
withDefaults(defineProps<{ tone?: 'neutral' | 'live' | 'win' | 'draw' | 'loss' | 'gold' | 'warning' }>(), { tone: 'neutral' })
</script>

<template>
  <span
    class="inline-flex h-8 items-center gap-1.5 rounded-pill px-3 text-sm font-bold"
    :class="{
      neutral: 'bg-surface-raised text-text-soft',
      live: 'bg-live/15 text-[#FF8A8A]',
      win: 'bg-success/15 text-success',
      draw: 'bg-surface-raised text-text-soft',
      loss: 'bg-live/15 text-[#FF8A8A]',
      gold: 'bg-gold/15 text-gold',
      warning: 'bg-warning/15 text-warning',
    }[tone]"
  >
    <span v-if="tone === 'live'" class="size-2 rounded-full bg-live" aria-hidden="true" />
    <slot />
  </span>
</template>
