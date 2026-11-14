<script setup lang="ts">
// A player as a card [X29], in the spirit of the football games' collectible cards but drawn for Legends: the rating
// and position large in the corner, the line's colour along the top, the name, and a fitness bar at the foot.
import { computed } from 'vue'
import { LINES, fitnessTone, money, type Line } from '../../lib/format'
import { nm } from '../../lib/names'

const props = defineProps<{
  name: string
  line: Line
  position: string
  overall: number
  value: number
  fitness?: number
  price?: number
  status?: string
  statusTone?: string
  selected?: boolean
  attributes?: Record<string, number | null>
}>()
// The card's six numbers, as on the real game cards: the outfield attributes, or the keeper's.
const LABELS: Record<string, string> = {
  pac: 'سرعة',
  sho: 'تسديد',
  pas: 'تمرير',
  dri: 'مراوغة',
  def: 'دفاع',
  phy: 'بدنية',
  diving: 'طيران',
  handling: 'إمساك',
  kicking: 'ركل',
  positioning: 'تمركز',
  reflexes: 'ردة فعل',
}
const stats = computed(
  () =>
    Object.entries(props.attributes ?? {})
      .filter(([, v]) => v != null)
      .slice(0, 6) as [string, number][],
)
const tier = computed(() => (props.overall >= 85 ? 'gold' : props.overall >= 75 ? 'silver' : 'bronze'))
const FACE = {
  gold: 'from-gold/25 via-surface-raised to-surface ring-gold/70',
  silver: 'from-silver/20 via-surface-raised to-surface ring-chrome/40',
  bronze: 'from-bronze/30 via-surface-raised to-surface ring-bronze/60',
}
// The name as the coach chose to see it [X40]; on the card its last part (the whole of a one-word name).
const shortName = computed(() => {
  const full = nm(props.name)
  const parts = full.trim().split(/\s+/)
  return parts.length > 1 ? parts.slice(1).join(' ') : full
})
</script>

<template>
  <div
    class="relative flex flex-col overflow-hidden rounded-2xl bg-gradient-to-b p-3 ring-1 transition hover:-translate-y-1 hover:shadow-xl hover:shadow-shade/40"
    :class="[FACE[tier], selected ? 'ring-2 ring-gold' : '', price === undefined ? 'aspect-[3/4]' : 'min-h-[16rem]']"
  >
    <span class="absolute inset-x-0 top-0 h-1" :style="{ background: `var(--color-line-${line})` }" aria-hidden="true" />
    <span
      class="pointer-events-none absolute -bottom-6 -end-6 size-28 rounded-full opacity-20 blur-2xl"
      :style="{ background: `var(--color-line-${line})` }"
      aria-hidden="true"
    />
    <div class="flex items-start justify-between">
      <div class="flex flex-col items-center leading-none">
        <b class="font-numbers text-4xl" :class="tier === 'gold' ? 'text-gold' : 'text-text'">{{ overall }}</b>
        <span class="mt-1 font-numbers text-sm text-text-soft" dir="ltr">{{ position }}</span>
      </div>
      <span
        class="grid size-7 place-items-center rounded-md text-xs font-extrabold"
        :style="{ background: `var(--color-line-${line})`, color: `var(--color-line-${line}-fg)` }"
        :title="LINES[line].name"
        >{{ $t(LINES[line].letter) }}</span
      >
    </div>
    <dl v-if="stats.length" class="my-2 grid grid-cols-2 gap-x-3 gap-y-0.5 text-[11px]">
      <div v-for="[k, v] in stats" :key="k" class="flex items-center justify-between gap-1">
        <dt class="truncate text-text-muted">{{ $t(LABELS[k] ?? k) }}</dt>
        <dd class="font-numbers font-bold" :class="v >= 85 ? 'text-gold' : v >= 70 ? 'text-text' : 'text-text-soft'">{{ v }}</dd>
      </div>
    </dl>
    <div class="mt-auto flex flex-col gap-1.5">
      <b class="truncate text-center font-display text-base leading-tight" :title="name"
        ><bdi>{{ shortName }}</bdi></b
      >
      <span v-if="status" class="truncate text-center text-[11px]" :class="statusTone">{{ $t(status) }}</span>
      <div
        v-if="fitness !== undefined"
        class="h-1.5 overflow-hidden rounded-pill bg-bg/60"
        :aria-label="$t('اللياقة {v0}%', { v0: fitness })"
      >
        <span class="block h-full rounded-pill" :class="fitnessTone(fitness)" :style="{ width: fitness + '%' }" />
      </div>
      <span class="text-center font-numbers text-xs text-text-muted" dir="ltr">{{ money(value) }}</span>
      <b v-if="price !== undefined" class="text-center font-numbers text-base text-gold" dir="ltr">{{ money(price) }}</b>
      <slot />
    </div>
  </div>
</template>
