<script setup lang="ts">
// [Sprint 20 W7, B3] The matches the coach missed since his last visit, in one window: the score, the goals, the man
// of the match, the coins, and what changed in his squad; «شاهد الإعادة» and «التقرير» (each marks it seen), the
// next one, or «تخطَّ الكل». Once skipped, a match does not come back. [Sprint 24 W1] «الملخص السريع» first: the
// match's big moments fast, then the numbers (MatchRecap), and it counts as seen.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api/client'
import type { components } from '../../api/schema'
import { useBoard } from '../../stores/board'
import MatchRecap from './MatchRecap.vue'

const props = defineProps<{ leagueId: number }>()
const router = useRouter()
const board = useBoard()
const matches = ref<components['schemas']['MissedMatch'][]>([])
const at = ref(0)
const m = computed(() => matches.value[at.value] ?? null)
const path = { params: { path: { league: props.leagueId } } }

onMounted(async () => {
  matches.value = (await api.GET('/leagues/{league}/team/missed', path)).data?.matches ?? []
})
async function skipAll() {
  const ids = matches.value.map((x) => x.match_id)
  matches.value = []
  await api.POST('/leagues/{league}/team/missed/seen', { ...path, body: { match_ids: ids } })
  board.refresh()
}
function open(to: string) {
  matches.value = []
  board.refresh()
  router.push(to)
}
// The recap open for this match; closing it moves to the next missed match.
const recap = ref<number | null>(null)
function recapClosed() {
  recap.value = null
  matches.value.splice(at.value, 1)
  if (at.value >= matches.value.length) at.value = Math.max(0, matches.value.length - 1)
  if (!matches.value.length) board.refresh()
}
const RESULT = { 1: ['فوز', 'bg-success/20 text-success'], 0: ['تعادل', 'bg-surface-raised text-text'], [-1]: ['خسارة', 'bg-live/20 text-danger'] } as const
</script>

<template>
  <MatchRecap v-if="recap" :match-id="recap" @close="recapClosed" />
  <div v-else-if="m" class="fixed inset-0 z-50 grid place-items-center bg-bg-deep/80 p-4" role="dialog" aria-modal="true" :aria-label="$t('فاتتك مباراة')">
    <div class="flex w-full max-w-md flex-col gap-4 rounded-2xl border border-gold/40 bg-surface p-5 shadow-2xl">
      <div class="flex items-center text-xs text-text-muted">
        <span class="flex-1">{{ $t(m.competition === 'league' ? 'فاتتك مباراة · الجولة {v0}' : 'فاتتك مباراة · الكأس', { v0: m.round }) }}</span>
        <span v-if="matches.length > 1" class="font-numbers" dir="ltr">{{ at + 1 }} / {{ matches.length }}</span>
      </div>
      <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 text-center">
        <span class="flex min-w-0 flex-col items-center gap-1"><img :src="m.home.crest_url" alt="" class="size-12" /><b class="max-w-full truncate text-sm">{{ $nm(m.home.name) }}</b></span>
        <span class="flex flex-col items-center gap-1">
          <b class="font-numbers text-5xl leading-none" dir="ltr">{{ m.home_goals }} - {{ m.away_goals }}</b>
          <span class="rounded-pill px-2 py-0.5 text-xs font-bold" :class="RESULT[m.result as 1 | 0 | -1][1]">{{ $t(RESULT[m.result as 1 | 0 | -1][0]) }}{{ m.result === 1 && m.venue === 'away' ? ' ' + $t('خارج أرضك') : '' }}</span>
        </span>
        <span class="flex min-w-0 flex-col items-center gap-1"><img :src="m.away.crest_url" alt="" class="size-12" /><b class="max-w-full truncate text-sm">{{ $nm(m.away.name) }}</b></span>
      </div>
      <ul v-if="m.goals.length" class="flex flex-wrap justify-center gap-x-3 gap-y-1 text-sm">
        <li v-for="(g, i) in m.goals" :key="i" :class="(g.side === 'home') === (m.venue === 'home') ? 'text-text' : 'text-text-muted'"><span class="font-numbers text-text-muted" dir="ltr">{{ g.minute }}'</span> <bdi>{{ $nm(g.scorer ?? '') }}</bdi></li>
      </ul>
      <div class="flex flex-wrap items-center gap-2 rounded-lg bg-surface-sunk p-3 text-sm">
        <span v-if="m.man_of_the_match" class="min-w-0 flex-1">{{ $t('رجل المباراة') }}: <b><bdi>{{ $nm(m.man_of_the_match.name ?? '') }}</bdi></b> <span class="font-numbers text-gold">{{ (m.man_of_the_match.rating / 100).toFixed(1) }}</span></span>
        <span v-if="m.coins" class="rounded-pill bg-gold px-2 font-numbers text-xs font-bold text-on-gold" dir="ltr">+{{ m.coins }}</span>
        <span v-for="(c, i) in m.changes" :key="i" class="rounded-pill px-2 text-xs" :class="c.kind === 'injury' ? 'bg-live/20 text-danger' : 'bg-warning/20 text-warning'"><bdi>{{ $nm(c.player ?? '') }}</bdi> {{ $t(c.kind === 'injury' ? 'مصاب' : 'مطرود') }}</span>
      </div>
      <button type="button" class="h-touch rounded-lg bg-gold font-bold text-on-gold" @click="recap = m.match_id">⚡ {{ $t('الملخص السريع') }}</button>
      <div class="flex gap-2">
        <button type="button" class="h-touch flex-1 rounded-lg bg-surface-raised font-bold" @click="open(`/live/${m.match_id}`)">{{ $t('شاهد الإعادة') }}</button>
        <button type="button" class="h-touch flex-1 rounded-lg bg-surface-raised font-bold" @click="open(`/live/${m.match_id}/report`)">{{ $t('التقرير') }}</button>
      </div>
      <div class="flex gap-2">
        <button v-if="at < matches.length - 1" type="button" class="h-touch flex-1 rounded-lg text-sm font-bold text-brand-light" @click="at++">{{ $t('المباراة التالية') }}</button>
        <button type="button" class="h-touch flex-1 rounded-lg text-sm text-text-muted" @click="skipAll">{{ $t(matches.length > 1 ? 'تخطَّ الكل' : 'تخطَّ') }}</button>
      </div>
    </div>
  </div>
</template>
