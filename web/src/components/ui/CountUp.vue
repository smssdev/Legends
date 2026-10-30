<script setup lang="ts">
// [X61] A number that moves to its new value instead of jumping (the coins, the club's money, points): from the old
// value to the new in requestAnimationFrame with an ease-out, once per change; at once with reduced motion or on the
// first show. `format` writes it (money(), a plain count...).
import { onBeforeUnmount, ref, watch } from 'vue'

const props = withDefaults(defineProps<{ value: number; format?: (n: number) => string; ms?: number }>(), { ms: 700 })
const shown = ref(props.value)
let frame = 0
const reduced = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches

watch(() => props.value, (to, from) => {
  cancelAnimationFrame(frame)
  if (reduced() || from === undefined || to === from) {
    shown.value = to
    return
  }
  const start = performance.now()
  const step = (now: number) => {
    const k = Math.min(1, (now - start) / props.ms)
    const eased = k === 1 ? 1 : 1 - 2 ** (-10 * k)   // ease-out expo
    shown.value = Math.round(from + (to - from) * eased)
    if (k < 1) frame = requestAnimationFrame(step)
  }
  frame = requestAnimationFrame(step)
})
onBeforeUnmount(() => cancelAnimationFrame(frame))
</script>

<template>
  <span class="tabular-nums">{{ format ? format(shown) : shown }}</span>
</template>
