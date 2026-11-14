<script setup lang="ts">
// [Sprint 48 T2] The team at a glance, beside the squad's tables (the owner's screenshots, 2026-11-08, our own look):
// the club and its coach, the eleven's average in a big dial with the four lines on a pitch, the place, the shape and
// the squad's value, then the best, the star, the top scorer and the next opponent. Only what the API sends.
import Explain from '../../../components/ui/Explain.vue'
import { useBoard as useExplainBoard } from '../../../stores/board'
import { computed } from 'vue'
import RatingRing from '../../../components/ui/RatingRing.vue'
import { money } from '../../../lib/format'
import type { SquadPlayer, Team } from '../team'
import type { Board } from '../../../stores/board'
// [Sprint 64 W5] The league whose club the numbers explain.
const explainBoard = useExplainBoard()

const props = defineProps<{ team: Team; board: Board | null; season: { players: Record<string, { goals: number }> } | null }>()
const emit = defineEmits<{ open: [player: SquadPlayer] }>()

const starters = computed(() => props.team.players.filter((p) => p.role === 'starter'))
const average = computed(() => (starters.value.length ? Math.round(starters.value.reduce((n, p) => n + p.overall, 0) / starters.value.length) : null))
const best = computed(() => [...props.team.players].sort((a, b) => b.overall - a.overall)[0] ?? null)
const star = computed(() => [...props.team.players].sort((a, b) => b.value - a.value)[0] ?? null)
const scorer = computed(() => {
  const goals = (p: SquadPlayer) => props.season?.players[String(p.id)]?.goals ?? 0
  const top = [...props.team.players].sort((a, b) => goals(b) - goals(a))[0]
  return top && goals(top) > 0 ? { player: top, goals: goals(top) } : null
})
const formation = computed(() => props.board?.lineup.formation.replace(/^custom:.*/, '') || null)
const moraleColor = (v: number) => (v >= 75 ? 'var(--color-success)' : v < 50 ? 'var(--color-live)' : 'var(--color-gold)')
</script>

<template>
  <aside class="team-card flex flex-col overflow-hidden rounded-2xl" :aria-label="$t('بطاقة الفريق')">
    <header class="flex items-center gap-3 px-4 pt-4">
      <AppImage :src="team.club.crest_url" :alt="team.club.name" :width="48" :height="54" class="shrink-0" crest />
      <div class="min-w-0 flex-1">
        <h2 class="truncate font-display text-xl font-extrabold">{{ $nm(team.club.name) }}</h2>
        <p v-if="board?.match?.club.coach" class="truncate text-sm text-text-soft"><bdi>{{ board.match.club.coach }}</bdi></p>
      </div>
      <!-- The eleven's average in the big dial. -->
      <div v-if="average" class="grid size-20 shrink-0 place-items-center rounded-full border-4 border-gold bg-bg-deep text-center shadow-lg" role="meter" :aria-label="$t('معدل الفريق')" :aria-valuenow="average" aria-valuemin="0" aria-valuemax="99">
        <span class="leading-none"><small class="block text-caption font-bold text-white/75">{{ $t('المعدل') }}</small><b class="font-numbers text-3xl text-gold">{{ average }}</b></span>
      </div>
    </header>

    <!-- The four lines on a slab of pitch. -->
    <div class="pitch-slab mx-4 mt-3 flex items-center justify-around rounded-xl px-1 py-3">
      <RatingRing v-for="l in (['att', 'mid', 'def', 'gk'] as const)" :key="l" :value="team.lines?.[l] ?? 0" :size="52"
        :label="{ att: 'هجوم', mid: 'وسط', def: 'دفاع', gk: 'حراسة' }[l]" :color="`var(--color-line-${l})`" />
    </div>

    <dl class="mx-4 mt-4 grid grid-cols-3 gap-2 text-center text-sm">
      <div class="rounded-lg bg-surface-sunk/70 px-2 py-2"><dt class="text-xs text-text-muted">{{ $t('المركز') }}</dt><dd class="font-numbers text-lg font-bold">{{ board?.standings.position ?? '—' }}<small v-if="board" class="text-xs text-text-muted">/{{ board.standings.teams }}</small></dd></div>
      <div class="rounded-lg bg-surface-sunk/70 px-2 py-2"><dt class="text-xs text-text-muted">{{ $t('الطريقة') }}</dt><dd class="font-numbers text-lg font-bold" dir="ltr">{{ formation ?? $t('خطتي') }}</dd></div>
      <div class="rounded-lg bg-surface-sunk/70 px-2 py-2"><dt class="text-xs text-text-muted">{{ $t('قيمة الفريق') }}</dt><dd class="font-numbers text-lg font-bold text-gold">{{ money(team.squad_value) }}</dd></div>
    </dl>

    <div v-if="team.morale" class="mx-4 mt-3 flex items-center gap-2 text-sm">
      <span class="font-bold">{{ $t('المعنويات') }}</span>
      <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk" role="meter" :aria-valuenow="team.morale.value" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('المعنويات')">
        <span class="block h-full rounded-full" :style="{ width: `${team.morale.value}%`, background: moraleColor(team.morale.value) }" />
      </span>
      <Explain what="morale" :league-id="explainBoard.league"><b class="font-numbers" :style="{ color: moraleColor(team.morale.value) }">{{ team.morale.value }}</b></Explain>
    </div>

    <ul class="m-4 flex flex-col divide-y divide-text/5 overflow-hidden rounded-xl bg-surface-sunk/70 text-sm">
      <li v-for="row in [
        { label: 'الأعلى قوة', player: best, num: best?.overall },
        { label: 'النجم', player: star, num: star ? money(star.value) : null },
        { label: 'الهداف', player: scorer?.player ?? null, num: scorer?.goals ?? null },
      ]" :key="row.label">
        <button type="button" class="flex min-h-11 w-full items-center gap-2 px-3 text-start hover:bg-surface-raised disabled:hover:bg-transparent" :disabled="!row.player" @click="row.player && emit('open', row.player)">
          <span class="w-20 shrink-0 text-text-muted">{{ $t(row.label) }}</span>
          <b class="min-w-0 flex-1 truncate"><bdi>{{ row.player ? $nm(row.player.name) : '—' }}</bdi></b>
          <span v-if="row.num !== null && row.num !== undefined" class="font-numbers font-bold text-gold">{{ row.num }}</span>
        </button>
      </li>
      <li v-if="board?.match" class="flex min-h-11 items-center gap-2 px-3">
        <span class="w-20 shrink-0 text-text-muted">{{ $t('المباراة القادمة') }}</span>
        <AppImage :src="board.match.opponent.crest_url" alt="" :width="20" :height="22" crest />
        <b class="min-w-0 flex-1 truncate">{{ $nm(board.match.opponent.name) }}</b>
        <span class="font-numbers font-bold text-gold">{{ Math.round(board.match.opponent.strength_cp / 100) }}</span>
      </li>
    </ul>
  </aside>
</template>

<style scoped>
/* The card: the night's panel with a gold light at its top, our own way of the manager games' side board. */
.team-card { background: radial-gradient(120% 60% at 50% 0%, color-mix(in srgb, var(--color-gold) 14%, transparent), transparent 70%), var(--color-surface); border: 1px solid color-mix(in srgb, var(--color-gold) 22%, transparent); }
/* A slab of pitch seen a little from above: stripes and a chalk line round it. */
.pitch-slab {
  background: repeating-linear-gradient(90deg, var(--color-pitch) 0 22px, var(--color-pitch-dark) 22px 44px);
  box-shadow: inset 0 0 0 2px color-mix(in srgb, var(--color-broadcast-white) 35%, transparent), 0 10px 0 -4px color-mix(in srgb, var(--color-pitch-dark) 70%, var(--color-shade));
  transform: perspective(500px) rotateX(14deg);
}
.pitch-slab :deep(span.text-xs) { color: var(--color-broadcast-white); text-shadow: 0 1px 2px color-mix(in srgb, var(--color-shade) 53%, transparent); }
</style>
