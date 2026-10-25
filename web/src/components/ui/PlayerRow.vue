<script setup lang="ts">
// One player in a list (design: MobileSquad, Main "بطاقة اللاعب"): line, name, a detail line with a bar,
// value and rating. The bar shows fitness in a match week, and room to grow (potential) before leagues have fitness.
import { computed } from 'vue'
import { LINES, money, type Line } from '../../lib/format'
import LineBadge from './LineBadge.vue'
import RatingBox from './RatingBox.vue'

const props = defineProps<{ name: string; line: Line; position: string; age: number; overall: number; potential: number; value: number; selected?: boolean }>()
const room = computed(() => props.potential - props.overall)
const fill = computed(() => Math.max(6, Math.min(100, 100 - room.value * 6)))
</script>

<template>
  <!-- [X32] The line's colour along the start edge, as the management games colour their squad rows. -->
  <div class="relative flex min-h-touch items-center gap-3 overflow-hidden rounded-xl p-3 ps-4" :class="selected ? 'bg-surface-raised ring-1 ring-gold/60' : 'bg-surface'">
    <span class="absolute inset-y-0 start-0 w-1" :style="{ background: `var(--color-line-${line})` }" aria-hidden="true" />
    <LineBadge :line="line" />
    <div class="min-w-0 flex-1">
      <div class="truncate font-display text-base font-extrabold">{{ name }}</div>
      <div class="mt-1 flex items-center gap-2 text-xs text-text-muted">
        <span>{{ LINES[line].name }} · <span dir="ltr">{{ position }}</span> · {{ age }} سنة</span>
        <span class="hidden h-1.5 w-20 overflow-hidden rounded-pill bg-surface-sunk sm:block" :title="`الإمكانية ${potential}`">
          <span class="block h-full rounded-pill" :class="room >= 6 ? 'bg-success' : room >= 2 ? 'bg-gold' : 'bg-warning'" :style="{ width: fill + '%' }" />
        </span>
        <span v-if="room > 0" class="font-numbers text-sm text-success" dir="ltr" :aria-label="`يتطور حتى ${potential}`">+{{ room }}</span>
      </div>
    </div>
    <span class="font-numbers text-lg text-text-soft" :aria-label="`القيمة ${value}`">{{ money(value) }}</span>
    <RatingBox :value="overall" />
  </div>
</template>
