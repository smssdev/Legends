<template>
  <span
    class="inline-flex shrink-0 items-center justify-center border-2 font-numbers font-bold"
    :style="{ width: size + 'px', height: size * 1.12 + 'px', borderRadius: `${size * 0.28}px ${size * 0.28}px ${size * 0.5}px ${size * 0.5}px`, background: primary, borderColor: secondary, color: text, fontSize: size * 0.34 + 'px' }"
    :aria-label="code"
  >{{ code }}</span>
</template>

<script setup lang="ts">
// Generated club badge from colors and code (no real logos, docs/PLAN.md 2.6).
import { computed } from 'vue'

const props = withDefaults(defineProps<{ code: string; primary: string; secondary: string; size?: number }>(), { size: 44 })
const light = (hex: string) => {
  const n = parseInt(hex.slice(1), 16)
  return ((n >> 16) * 299 + ((n >> 8) & 255) * 587 + (n & 255) * 114) / 1000 > 150
}
const text = computed(() => (light(props.primary) ? (light(props.secondary) ? '#0A1F42' : props.secondary) : '#FFFFFF'))
</script>
