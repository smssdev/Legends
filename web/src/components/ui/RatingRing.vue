<script setup lang="ts">
// A rating in a ring that fills toward 99 [X29]: the team's strength per line, like the dials of the classic manager
// games. The colour follows the line (tokens.json), the number sits in the middle.
import { computed } from 'vue'

const props = withDefaults(defineProps<{ value: number; label: string; color?: string; size?: number }>(), { color: 'var(--color-gold)', size: 76 })
const R = 30
const C = 2 * Math.PI * R
const dash = computed(() => `${(Math.max(0, Math.min(99, props.value)) / 99) * C} ${C}`)
</script>

<template>
  <div class="flex flex-col items-center gap-1.5" role="meter" :aria-label="label" :aria-valuenow="value" aria-valuemin="0" aria-valuemax="99">
    <div class="relative grid place-items-center" :style="{ width: size + 'px', height: size + 'px' }">
      <svg :width="size" :height="size" viewBox="0 0 76 76" class="absolute inset-0 -rotate-90" aria-hidden="true">
        <circle cx="38" cy="38" :r="R" fill="none" stroke="var(--color-surface-sunk)" stroke-width="7" />
        <circle cx="38" cy="38" :r="R" fill="none" :stroke="color" stroke-width="7" stroke-linecap="round" :stroke-dasharray="dash" />
      </svg>
      <b class="relative font-numbers text-2xl">{{ value }}</b>
    </div>
    <span class="text-xs font-bold text-text-soft">{{ label }}</span>
  </div>
</template>
