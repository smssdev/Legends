<script setup lang="ts">
// [Sprint 48 T2] The squad as a table by line (the owner's screenshots, our own look): each line under a header in its
// colour that carries the columns' names, and each player across: his line and position, his state, age, nation,
// strength, fitness, this season's matches, goals, assists and average rating, and his value. A tap opens his card.
import LineBadge from '../../../components/ui/LineBadge.vue'
import NationChip from '../../../components/ui/NationChip.vue'
import { fitnessTone, money, type Line } from '../../../lib/format'
import type { SquadPlayer } from '../team'
import { ratingTone, LINE_HEAD, type SeasonPlayer } from './squad'

// [Sprint 56 W2] The columns by the tab (Squad.html): the list (position, state, age, strength, fitness, value; the nation
// from 1200px) or the season (matches, goals, assists, average rating). Rows of 44px, the line's header row stays at the
// top of the table's own scroll while its line passes.
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    groups: { line: Line; players: SquadPlayer[] }[]
    season: Record<string, SeasonPlayer> | null
    status: (p: SquadPlayer) => { text: string; tone: string }
    cols?: 'list' | 'stats'
  }>(),
  { cols: 'list' },
)
const emit = defineEmits<{ open: [player: SquadPlayer]; sale: [player: SquadPlayer] }>()
const COLS = computed(() =>
  props.cols === 'list'
    ? ['المركز', 'الحالة', 'العمر', 'الجنسية', 'القوة', 'اللياقة', 'القيمة']
    : ['المركز', 'القوة', 'م', 'أهداف', 'صناعة', 'التقييم'],
)
const wide = (c: string) => (c === 'الجنسية' ? 'max-xl:hidden' : c === 'الحالة' ? 'max-md:hidden' : '')
</script>

<template>
  <div class="squad-table relative overflow-auto overscroll-contain rounded-xl ui-card">
    <table class="w-full border-collapse text-body">
      <tbody v-for="grp in groups" :key="grp.line">
        <tr class="line-head" :style="{ '--line': `var(--color-line-${grp.line})`, '--line-fg': `var(--color-line-${grp.line}-fg)` }">
          <th scope="colgroup" class="px-3 py-2 text-start font-display text-body-lg font-extrabold">
            {{ $t(LINE_HEAD[grp.line]) }} <span class="font-numbers text-xs">{{ grp.players.length }}</span>
          </th>
          <th v-for="c in COLS" :key="c" scope="col" class="px-2 py-2 text-center text-caption font-bold" :class="wide(c)">{{ $t(c) }}</th>
        </tr>
        <tr
          v-for="p in grp.players"
          :key="p.id"
          class="h-11 cursor-pointer border-b border-text/5 transition-colors last:border-0 hover:bg-surface-raised"
          :class="p.role === 'starter' ? 'starter' : ''"
          @click="emit('open', p)"
        >
          <td class="max-w-[14rem] px-3 py-1">
            <span class="flex items-center gap-2">
              <LineBadge :line="p.line as Line" />
              <button
                type="button"
                class="name-open truncate text-start font-display text-body-lg font-extrabold focus-visible:underline"
                @click.stop="emit('open', p)"
              >
                {{ $nm(p.name) }}
              </button>
              <button
                v-if="p.listed"
                type="button"
                class="flex min-h-touch shrink-0 items-center rounded-pill bg-gold/20 px-2 text-caption font-bold text-gold max-md:hidden"
                :aria-label="$t('معروض للبيع: اسحبه أو اتركه')"
                @click.stop="emit('sale', p)"
              >
                {{ $t('معروض للبيع') }}
              </button>
            </span>
          </td>
          <td class="px-2 text-center text-text-soft" dir="ltr">{{ p.position }}</td>
          <template v-if="cols === 'list'">
            <td class="max-w-[8rem] truncate px-2 text-center text-caption max-md:hidden" :class="status(p).tone">
              {{ $t(status(p).text) }}
            </td>
            <td class="px-2 text-center font-numbers text-text-soft">{{ p.age }}</td>
            <td class="px-2 text-center max-xl:hidden"><NationChip :nation="p.nation ?? null" :name="p.nationality" /></td>
            <td class="px-2 text-center">
              <b class="font-numbers text-title" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</b>
            </td>
            <td class="w-24 px-2">
              <span class="flex items-center gap-1.5">
                <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk"
                  ><span class="block h-full rounded-full" :class="fitnessTone(p.fitness)" :style="{ width: `${p.fitness}%` }"
                /></span>
                <span class="w-7 text-end font-numbers text-caption text-text-soft">{{ p.fitness }}</span>
              </span>
            </td>
            <td class="px-2 text-end font-numbers text-text-soft">{{ money(p.value) }}</td>
          </template>
          <template v-else>
            <td class="px-2 text-center">
              <b class="font-numbers text-title" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</b>
            </td>
            <td class="px-2 text-center font-numbers text-text-soft">{{ season?.[p.id]?.played ?? 0 }}</td>
            <td class="px-2 text-center font-numbers">{{ season?.[p.id]?.goals ?? 0 }}</td>
            <td class="px-2 text-center font-numbers">{{ season?.[p.id]?.assists ?? 0 }}</td>
            <td class="px-2 text-center">
              <span
                v-if="season?.[p.id]?.average"
                class="inline-grid h-7 min-w-10 place-items-center rounded-pill px-1.5 font-numbers text-caption font-bold"
                :class="ratingTone(season[p.id].average!)"
                >{{ (season[p.id].average! / 100).toFixed(1) }}</span
              >
              <span v-else class="text-text-muted">—</span>
            </td>
          </template>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
/* [Sprint 65 W5] The name opens the card with the keys; its 44px touch spreads around it, so the row keeps its height. */
.name-open {
  position: relative;
}
.name-open::after {
  content: '';
  position: absolute;
  inset: -10px 0;
}
/* A line's header: its colour, the columns' names on it, held at the top while its line scrolls by. */
.line-head th {
  position: sticky;
  top: 0;
  z-index: 1;
  background: var(--line);
}
.line-head {
  background: linear-gradient(90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line));
  color: var(--line-fg);
}
:dir(rtl) .line-head {
  background: linear-gradient(-90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line));
}
/* The eleven: a gold thread at the start of the row. */
.starter td:first-child {
  box-shadow: inset 3px 0 0 var(--color-gold);
}
:dir(rtl) .starter td:first-child {
  box-shadow: inset -3px 0 0 var(--color-gold);
}
</style>
