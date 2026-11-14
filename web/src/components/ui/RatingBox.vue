<script setup lang="ts">
// A rating in its box (design: 91 / 90 / 85). Gold from 88 up.
defineProps<{ value: number; size?: 'md' | 'lg' }>()
</script>

<template>
  <span
    class="inline-flex shrink-0 items-center justify-center rounded-xl bg-surface-raised font-numbers font-extrabold"
    :class="[size === 'lg' ? 'size-16 text-3xl' : 'size-12 text-2xl', value >= 88 ? 'text-gold' : 'text-text']"
    >{{ value }}</span
  >
</template>
