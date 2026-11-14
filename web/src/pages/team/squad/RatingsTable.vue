<script setup lang="ts">
// [Sprint 48 T2] Each player's rating in every league round played (the owner's screenshots, our own look), by line,
// with his average at the end. A round he did not play is an empty cell.
import { computed } from 'vue'
import type { Line } from '../../../lib/format'
import type { SquadPlayer } from '../team'
import { ratingTone, LINE_HEAD, type SeasonData } from './squad'

const props = defineProps<{ groups: { line: Line; players: SquadPlayer[] }[]; season: SeasonData }>()
const emit = defineEmits<{ open: [player: SquadPlayer] }>()
const rounds = computed(() => Array.from({ length: props.season.rounds }, (_, i) => String(i + 1)))
const r1 = (v: number) => (v / 100).toFixed(1)
</script>

<template>
  <p v-if="!season.rounds" class="rounded-2xl ui-card px-4 py-10 text-center text-text-muted">
    {{ $t('لم تُلعب جولة في الدوري بعد: التقييمات تظهر هنا بعد أول مباراة.') }}
  </p>
  <div v-else class="overflow-x-auto rounded-2xl ui-card">
    <table class="w-full border-collapse text-sm" :style="{ minWidth: `${14 + rounds.length * 3 + 4}rem` }">
      <tbody v-for="grp in groups" :key="grp.line">
        <tr class="line-head" :style="{ '--line': `var(--color-line-${grp.line})`, '--line-fg': `var(--color-line-${grp.line}-fg)` }">
          <th scope="colgroup" class="sticky start-0 z-10 bg-inherit px-3 py-2 text-start font-display text-base font-extrabold">
            {{ $t(LINE_HEAD[grp.line]) }}
          </th>
          <th v-for="r in rounds" :key="r" scope="col" class="w-12 px-1 py-2 text-center font-numbers text-xs font-bold">{{ r }}</th>
          <th scope="col" class="w-16 px-2 py-2 text-center text-xs font-bold">{{ $t('المعدل') }}</th>
        </tr>
        <tr
          v-for="p in grp.players"
          :key="p.id"
          class="cursor-pointer border-b border-text/5 last:border-0 hover:bg-surface-raised"
          @click="emit('open', p)"
        >
          <td class="sticky start-0 z-10 truncate bg-surface px-3 py-2 font-display font-extrabold">
            <button type="button" class="name-open w-full truncate text-start focus-visible:underline" @click.stop="emit('open', p)">
              {{ $nm(p.name) }}
            </button>
          </td>
          <td v-for="r in rounds" :key="r" class="px-1 text-center">
            <span
              v-if="season.players[p.id]?.ratings[r]"
              class="inline-grid size-8 place-items-center rounded-full font-numbers text-xs font-bold"
              :class="ratingTone(season.players[p.id].ratings[r])"
              >{{ r1(season.players[p.id].ratings[r]) }}</span
            >
          </td>
          <td class="px-2 text-center">
            <span
              v-if="season.players[p.id]?.average"
              class="inline-grid h-8 min-w-11 place-items-center rounded-pill px-2 font-numbers text-sm font-extrabold ring-2 ring-gold/50"
              :class="ratingTone(season.players[p.id].average!)"
              >{{ r1(season.players[p.id].average!) }}</span
            >
            <span v-else class="text-text-muted">—</span>
          </td>
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
.line-head {
  background: linear-gradient(90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line));
  color: var(--line-fg);
}
:dir(rtl) .line-head {
  background: linear-gradient(-90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line));
}
.line-head th.sticky {
  background: color-mix(in srgb, var(--line) 82%, var(--color-shade));
}
</style>
