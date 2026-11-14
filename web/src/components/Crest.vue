<template>
  <img
    v-if="logo"
    :src="logo"
    :alt="code"
    class="shrink-0 object-contain"
    :style="{ width: size + 'px', height: size * 1.12 + 'px' }"
    decoding="async"
    loading="lazy"
  />
  <span
    v-else
    class="inline-flex shrink-0 items-center justify-center border-2 font-numbers font-bold"
    :style="{
      width: size + 'px',
      height: size * 1.12 + 'px',
      borderRadius: `${size * 0.28}px ${size * 0.28}px ${size * 0.5}px ${size * 0.5}px`,
      background: primary,
      borderColor: secondary,
      color: text,
      fontSize: size * 0.34 + 'px',
    }"
    :aria-label="code"
    >{{ code }}</span
  >
</template>

<script setup lang="ts">
// The club's real logo where it has one [UP3], else a badge drawn from its colours and code.
import { computed } from 'vue'

const props = withDefaults(defineProps<{ code: string; primary: string; secondary: string; size?: number; logo?: string | null }>(), {
  size: 44,
  logo: null,
})
const light = (hex: string) => {
  const n = parseInt(hex.slice(1), 16)
  return ((n >> 16) * 299 + ((n >> 8) & 255) * 587 + (n & 255) * 114) / 1000 > 150
}
const text = computed(() => (light(props.primary) ? (light(props.secondary) ? '#0B1A2C' : props.secondary) : '#FFFFFF'))
</script>
