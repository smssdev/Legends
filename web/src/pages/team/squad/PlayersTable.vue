<script setup lang="ts">
// [Sprint 48 T2] The squad as a table by line (the owner's screenshots, our own look): each line under a header in its
// colour that carries the columns' names, and each player across: his line and position, his state, age, nation,
// strength, fitness, this season's matches, goals, assists and average rating, and his value. A tap opens his card.
import LineBadge from '../../../components/ui/LineBadge.vue'
import NationChip from '../../../components/ui/NationChip.vue'
import { fitnessTone, money, type Line } from '../../../lib/format'
import type { SquadPlayer } from '../team'
import { ratingTone, LINE_HEAD, type SeasonPlayer } from './squad'

defineProps<{
  groups: { line: Line; players: SquadPlayer[] }[]
  season: Record<string, SeasonPlayer> | null
  status: (p: SquadPlayer) => { text: string; tone: string }
}>()
const emit = defineEmits<{ open: [player: SquadPlayer]; sale: [player: SquadPlayer] }>()
const COLS = ['المركز', 'الحالة', 'العمر', 'الجنسية', 'القوة', 'اللياقة', 'م', 'أهداف', 'صناعة', 'التقييم', 'القيمة'] as const
</script>

<template>
  <div class="overflow-x-auto rounded-2xl bg-surface">
    <table class="w-full min-w-[54rem] border-collapse text-sm">
      <tbody v-for="grp in groups" :key="grp.line">
        <tr class="line-head" :style="{ '--line': `var(--color-line-${grp.line})`, '--line-fg': `var(--color-line-${grp.line}-fg)` }">
          <th scope="colgroup" class="px-3 py-2 text-start font-display text-base font-extrabold">{{ $t(LINE_HEAD[grp.line]) }} <span class="font-numbers text-xs opacity-80">{{ grp.players.length }}</span></th>
          <th v-for="c in COLS" :key="c" scope="col" class="px-2 py-2 text-center text-xs font-bold">{{ $t(c) }}</th>
        </tr>
        <tr v-for="p in grp.players" :key="p.id" class="cursor-pointer border-b border-text/5 transition-colors last:border-0 hover:bg-surface-raised" :class="p.role === 'starter' ? 'starter' : ''" tabindex="0" @click="emit('open', p)" @keydown.enter="emit('open', p)">
          <td class="px-3 py-2">
            <span class="flex items-center gap-2">
              <LineBadge :line="p.line as Line" />
              <span class="truncate font-display text-base font-extrabold">{{ $nm(p.name) }}</span>
              <span v-if="p.listed" role="button" tabindex="0" class="shrink-0 rounded-pill bg-gold/20 px-2 py-0.5 text-[11px] font-bold text-gold" :aria-label="$t('معروض للبيع: اسحبه أو اتركه')"
                @click.stop="emit('sale', p)" @keydown.enter.stop.prevent="emit('sale', p)">{{ $t('معروض للبيع') }}</span>
            </span>
          </td>
          <td class="px-2 text-center text-text-soft" dir="ltr">{{ p.position }}</td>
          <td class="max-w-[8rem] truncate px-2 text-center text-xs" :class="status(p).tone">{{ $t(status(p).text) }}</td>
          <td class="px-2 text-center font-numbers text-text-soft">{{ p.age }}</td>
          <td class="px-2 text-center"><NationChip :nation="p.nation ?? null" :name="p.nationality" /></td>
          <td class="px-2 text-center"><b class="font-numbers text-lg" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</b></td>
          <td class="w-24 px-2">
            <span class="flex items-center gap-1.5">
              <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="fitnessTone(p.fitness)" :style="{ width: `${p.fitness}%` }" /></span>
              <span class="w-7 text-end font-numbers text-xs text-text-soft">{{ p.fitness }}</span>
            </span>
          </td>
          <td class="px-2 text-center font-numbers text-text-soft">{{ season?.[p.id]?.played ?? 0 }}</td>
          <td class="px-2 text-center font-numbers">{{ season?.[p.id]?.goals ?? 0 }}</td>
          <td class="px-2 text-center font-numbers">{{ season?.[p.id]?.assists ?? 0 }}</td>
          <td class="px-2 text-center">
            <span v-if="season?.[p.id]?.average" class="inline-grid h-7 min-w-10 place-items-center rounded-pill px-1.5 font-numbers text-xs font-bold" :class="ratingTone(season[p.id].average!)">{{ (season[p.id].average! / 100).toFixed(1) }}</span>
            <span v-else class="text-text-muted">—</span>
          </td>
          <td class="px-2 text-end font-numbers text-text-soft">{{ money(p.value) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
/* A line's header: its colour, the columns' names on it. */
.line-head { background: linear-gradient(90deg, color-mix(in srgb, var(--line) 82%, #000), var(--line)); color: var(--line-fg); }
:dir(rtl) .line-head { background: linear-gradient(-90deg, color-mix(in srgb, var(--line) 82%, #000), var(--line)); }
/* The eleven: a gold thread at the start of the row. */
.starter td:first-child { box-shadow: inset 3px 0 0 var(--color-gold); }
:dir(rtl) .starter td:first-child { box-shadow: inset -3px 0 0 var(--color-gold); }
</style>
