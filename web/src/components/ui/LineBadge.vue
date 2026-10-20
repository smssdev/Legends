<script setup lang="ts">
// A player's line: one letter on the line's colour (حارس، دفاع، وسط، هجوم). Colour tells the line apart, nothing else.
import { LINES, type Line } from '../../lib/format'
withDefaults(defineProps<{ line: Line; full?: boolean }>(), { full: false })
</script>

<template>
  <span
    class="inline-flex h-8 shrink-0 items-center justify-center rounded-md px-2 text-sm font-extrabold"
    :class="full ? 'min-w-16' : 'w-10'"
    :style="{ background: `var(--color-line-${line})`, color: `var(--color-line-${line}-fg)` }"
    :aria-label="LINES[line].name"
  >{{ full ? LINES[line].name : LINES[line].letter }}</span>
</template>
