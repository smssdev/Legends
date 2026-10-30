<script setup lang="ts">
// [Sprint 29] A tournament's page (docs/design/legends-ui/Sprint29Drafts.html, 4): the groups' tables (those going
// through marked), the league table, or the bracket whose first ties say where their teams come from (A1 against B2)
// until the groups end; and the way to its draw, its group chat and joining it.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { paths } from '../../api/schema'
import { when } from '../../api/leagues'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import { FORMATS, STAGES, TEMPLATES } from './labels'

type Page = paths['/tournaments/{league}']['get']['responses']['200']['content']['application/json']['tournament']
type Card = { id: number; name: string; code: string; crest_url: string; coach?: string | null }
const props = defineProps<{ id: string }>()
const page = ref<Page | null>(null)
const error = ref('')
const tab = ref<'groups' | 'bracket' | 'teams'>('groups')

onMounted(async () => {
  try {
    const { data } = await api.GET('/tournaments/{league}', { params: { path: { league: Number(props.id) } } })
    page.value = data!.tournament
    if (page.value.format === 'knockout') tab.value = 'bracket'
  } catch (e) {
    error.value = asApiError(e).message
  }
})
const card = (c: unknown) => c as Card | null
const tabs = computed(() => {
  const f = page.value?.format
  const list: { key: typeof tab.value; label: string }[] = []
  if (f !== 'knockout') list.push({ key: 'groups', label: f === 'league' ? 'الترتيب' : 'المجموعات' })
  if (f !== 'league') list.push({ key: 'bracket', label: 'الأدوار الإقصائية' })
  list.push({ key: 'teams', label: 'الفرق' })
  return list
})
const tables = computed(() => (page.value?.format === 'league' ? [{ group: '', rows: page.value.table }] : page.value?.groups ?? []))
const through = computed(() => page.value?.advance_per_group ?? (page.value?.format === 'league' ? 1 : 0))
</script>

<template>
  <div class="flex flex-col gap-4 pb-8">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <template v-if="page">
      <header class="flex flex-col gap-1">
        <h1 class="font-display text-3xl font-extrabold">{{ page.name }}</h1>
        <p class="text-sm text-text-muted">{{ $t(TEMPLATES[page.template ?? 'custom'] ?? 'بطولة مخصصة') }} · {{ $t('{n} فريقاً', { n: page.team_count }) }} · {{ $t(FORMATS[page.format ?? 'groups']) }}
          · {{ $t('المنظم: {v0}', { v0: page.owner?.name ?? '' }) }}</p>
      </header>
      <nav class="grid grid-cols-3 gap-2">
        <RouterLink :to="{ name: 'tournament-draw', params: { id } }" class="flex min-h-touch items-center justify-center rounded-xl bg-gold px-2 text-center text-sm font-extrabold text-on-gold">
          {{ page.drawn_at ? $t('شاهد القرعة') : page.draw_at ? $t('القرعة {v0}', { v0: when(page.draw_at) }) : $t('القرعة') }}</RouterLink>
        <RouterLink :to="{ name: 'join', params: { code: page.code } }" class="flex min-h-touch items-center justify-center rounded-xl bg-surface px-2 text-sm font-bold">{{ $t('اطلب فريقاً') }}</RouterLink>
        <RouterLink :to="{ name: 'league-home', params: { id } }" class="flex min-h-touch items-center justify-center rounded-xl bg-surface px-2 text-sm font-bold">{{ $t('صفحة الدوري') }}</RouterLink>
      </nav>

      <div class="flex gap-2" role="tablist">
        <button v-for="x in tabs" :key="x.key" role="tab" :aria-selected="tab === x.key" class="min-h-touch rounded-full px-4 text-sm font-bold"
          :class="tab === x.key ? 'bg-brand' : 'bg-surface-sunk text-text-muted'" @click="tab = x.key">{{ $t(x.label) }}</button>
      </div>

      <section v-if="tab === 'groups'" class="grid gap-3 md:grid-cols-2">
        <p v-if="!tables.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('تظهر المجموعات بعد القرعة.') }}</p>
        <div v-for="g in tables" :key="g.group" class="rounded-2xl bg-surface p-3">
          <h2 v-if="g.group" class="mb-2 font-bold text-gold">{{ $t('المجموعة {v0}', { v0: g.group }) }}</h2>
          <table class="w-full text-sm">
            <thead class="text-xs text-text-muted"><tr><th class="text-start">{{ $t('الفريق') }}</th><th>{{ $t('لعب') }}</th><th>{{ $t('الفارق') }}</th><th>{{ $t('النقاط') }}</th></tr></thead>
            <tbody>
              <tr v-for="(r, i) in g.rows" :key="i" class="border-t border-text/5">
                <td class="py-1.5"><span class="flex items-center gap-2" :class="i < through ? 'border-s-[3px] border-brand-light ps-2' : 'ps-[11px]'">
                  <ClubCrest v-if="card(r.club)" :url="card(r.club)!.crest_url" :code="card(r.club)!.code" :size="22" /><span class="truncate">{{ $nm(card(r.club)?.name) }}</span></span></td>
                <td class="text-center font-numbers">{{ r.played }}</td>
                <td class="text-center font-numbers" dir="ltr">{{ r.goals_for - r.goals_against }}</td>
                <td class="text-center font-numbers font-bold">{{ r.points }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-else-if="tab === 'bracket'" class="flex gap-3 overflow-x-auto pb-2">
        <div v-for="s in page.bracket" :key="s.stage" class="flex min-w-[170px] flex-1 flex-col justify-around gap-2">
          <h2 class="text-center text-sm font-bold text-gold">{{ $t(STAGES[s.stage] ?? s.stage) }}</h2>
          <div v-for="tie in s.ties" :key="tie.slot" class="rounded-xl bg-surface p-2 text-sm" :class="s.stage === 'final' ? 'ring-1 ring-gold' : ''">
            <div v-for="side in (['home', 'away'] as const)" :key="side" class="flex min-h-[32px] items-center justify-between gap-2"
              :class="tie.winner_id && card(tie[side])?.id === tie.winner_id ? 'font-bold' : ''">
              <span class="flex min-w-0 items-center gap-1">
                <ClubCrest v-if="card(tie[side])" :url="card(tie[side])!.crest_url" :code="card(tie[side])!.code" :size="20" />
                <span class="truncate">{{ card(tie[side]) ? $nm(card(tie[side])!.name) : (tie[`${side}_from`] ?? '؟') }}</span></span>
              <b v-if="tie.score" class="font-numbers">{{ tie.score[side === 'home' ? 0 : 1] }}</b>
            </div>
            <span class="block text-xs text-text-muted">{{ when(tie.at) }}</span>
          </div>
        </div>
      </section>

      <section v-else class="grid grid-cols-2 gap-2 sm:grid-cols-3">
        <div v-for="c in page.teams.map(card)" :key="c!.id" class="flex min-h-touch items-center gap-2 rounded-xl bg-surface p-2 text-sm">
          <ClubCrest :url="c!.crest_url" :code="c!.code" :size="28" />
          <span class="min-w-0"><b class="block truncate">{{ $nm(c!.name) }}</b><span class="block truncate text-xs text-text-muted">{{ c!.coach ?? $t('الحاسوب') }}</span></span>
        </div>
      </section>
    </template>
  </div>
</template>
