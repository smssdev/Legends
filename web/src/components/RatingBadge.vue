<script setup lang="ts">
// [Sprint 25] A rating tier's emblem: a shield in the tier's colour, its rank's chevrons inside, and the division's
// pips under it (three for I). The legend wears a crown. Only draws what the API sends.
import { computed } from 'vue'
import { tierName, TIER_COLOR, type TierKey } from '../lib/rating'

const props = withDefaults(defineProps<{ tier: TierKey; division?: number | null; size?: number; dim?: boolean }>(), {
  division: null,
  size: 40,
  dim: false,
})
const color = computed(() => TIER_COLOR[props.tier])
const rank = computed(() => Object.keys(TIER_COLOR).indexOf(props.tier) + 1)
// Division III shows one pip, II two, I three.
const pips = computed(() => (props.division ? 4 - props.division : 0))
const label = computed(() => tierName(props.tier) + (props.division ? ' ' + ['', 'I', 'II', 'III'][props.division] : ''))
</script>

<template>
  <svg
    :width="size"
    :height="size * 1.15"
    viewBox="0 0 40 46"
    role="img"
    :aria-label="label"
    :class="{ 'opacity-35 grayscale': dim }"
    class="shrink-0"
  >
    <defs>
      <linearGradient :id="`rb-${tier}`" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" :style="{ stopColor: color, stopOpacity: 1 }" />
        <stop offset="1" :style="{ stopColor: color, stopOpacity: 0.62 }" />
      </linearGradient>
    </defs>
    <path
      d="M20 2 36 8v12c0 10-7 17-16 21C11 37 4 30 4 20V8Z"
      :fill="`url(#rb-${tier})`"
      style="stroke: var(--color-shade)"
      stroke-opacity="0.35"
      stroke-width="1.2"
    />
    <path
      d="M20 5.5 33 10.4V20c0 8.2-5.6 14-13 17.5C12.6 34 7 28.2 7 20v-9.6Z"
      fill="none"
      stroke="#fff"
      stroke-opacity="0.45"
      stroke-width="1"
    />
    <!-- The legend's crown; the others their rank in chevrons (up to three, then stars). -->
    <path v-if="tier === 'legend'" d="M11 25 9 14l6 5 5-8 5 8 6-5-2 11Z" fill="#fff" />
    <template v-else-if="rank <= 3">
      <path
        v-for="n in rank"
        :key="n"
        :d="`M12 ${13 + n * 5}l8 -4 8 4`"
        fill="none"
        stroke="#fff"
        stroke-width="2.6"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>
    <template v-else>
      <path
        v-for="n in rank - 3"
        :key="n"
        :transform="`translate(${(n - 1) * 8 - (rank - 4) * 4} 0)`"
        d="m20 13 1.8 3.7 4 .6-2.9 2.8.7 4L20 22.2l-3.6 1.9.7-4-2.9-2.8 4-.6Z"
        fill="#fff"
      />
    </template>
    <circle
      v-for="n in pips"
      :key="'p' + n"
      :cx="20 + (n - (pips + 1) / 2) * 6"
      cy="43"
      r="2.2"
      :style="{ fill: color, stroke: 'var(--color-shade)' }"
      stroke-opacity="0.3"
      stroke-width="0.6"
    />
  </svg>
</template>
