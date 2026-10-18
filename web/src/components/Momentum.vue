<template>
  <svg :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="none" class="h-full w-full" role="img" :aria-label="label">
    <line :x1="0" :y1="H / 2" :x2="W" :y2="H / 2" stroke="rgba(247,244,234,0.18)" />
    <line :x1="W / 2" y1="2" :x2="W / 2" :y2="H - 2" stroke="rgba(247,244,234,0.12)" stroke-dasharray="3 4" />
    <path :d="paths.up" :fill="homeColor" fill-opacity="0.85" />
    <path :d="paths.down" fill="#F7F4EA" fill-opacity="0.75" />
  </svg>
</template>

<script setup lang="ts">
// Momentum: who threatened more, minute by minute. Time runs right to left (RTL).
import { computed } from 'vue'

const props = defineProps<{ values: number[]; homeColor: string; minutes?: number }>()
const W = 1000
const H = 90
const label = 'منحنى الزخم: أعلى الخط لصاحب الأرض، وأسفله للضيف'
const paths = computed(() => {
  const total = Math.max(props.minutes ?? 90, props.values.length)
  const x = (m: number) => (W - (m / total) * W).toFixed(1)
  let up = `M${W} ${H / 2}`
  let down = `M${W} ${H / 2}`
  // Smooth over three minutes so single events do not spike.
  props.values.forEach((_, i) => {
    const v = (props.values[i - 1] ?? 0) * 0.25 + props.values[i] * 0.5 + (props.values[i + 1] ?? 0) * 0.25
    up += ` L${x(i + 1)} ${H / 2 - Math.max(0, v) * 8}`
    down += ` L${x(i + 1)} ${H / 2 + Math.max(0, -v) * 8}`
  })
  const end = x(props.values.length)
  return { up: `${up} L${end} ${H / 2} Z`, down: `${down} L${end} ${H / 2} Z` }
})
</script>
